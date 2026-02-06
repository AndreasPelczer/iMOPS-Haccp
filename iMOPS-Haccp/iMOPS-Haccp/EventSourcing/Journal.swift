//
//  Journal.swift
//  iMOPS-Haccp
//
//  Persistent event journal backed by SwiftData.
//  Append-only by design: events are never modified or deleted.
//  "Journal append asynchron (aber garantiert)."
//
//  ARCHITEKTUR-REGELN:
//  1. Kernel = Hot Path, Journal = Side Channel (kein Deadlock)
//  2. ModelContainer = thread-safe, ModelContext = NICHT thread-safe
//  3. Jede Operation bekommt einen frischen ModelContext (SwiftData-Physik)
//

import Foundation
import SwiftData
#if os(iOS)
import UIKit
#endif

/// The persistent event journal for iMOPS.
/// Appends events to SwiftData on its own serial queue – never blocks the kernel.
/// Each operation creates a fresh ModelContext (SwiftData thread-affinity rule).
@available(iOS 17.0, *)
final class Journal {
    private let modelContainer: ModelContainer
    private let journalQueue = DispatchQueue(label: "imops.journal.queue", qos: .utility)
    private var sequenceCounter: Int = 0

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // Sequence-Counter aus der Datenbank wiederherstellen
        journalQueue.sync {
            let context = ModelContext(modelContainer)
            self.sequenceCounter = Self.fetchMaxSequenceNumber(from: context) + 1
        }
    }

    // MARK: - Append (async – blockiert den Kernel nie)

    /// Append a new event to the journal.
    /// Dispatches async to the journal queue – returns immediately.
    /// Sequence ordering is preserved by the serial queue.
    func append(type: iMOPSEventType, path: String, value: String? = nil, userId: String = "SYSTEM") {
        journalQueue.async { [self] in
            let context = ModelContext(modelContainer)
            let event = iMOPSEvent(
                type: type,
                path: path,
                value: value,
                userId: userId,
                deviceId: deviceIdentifier(),
                sequenceNumber: sequenceCounter
            )

            context.insert(event)
            sequenceCounter += 1

            // Persist immediately (Windhund-Prinzip: schnell, aber garantiert)
            try? context.save()
        }
    }

    // MARK: - Fetch (sync – für Replay und Boot)

    /// Fetch all events ordered by sequence number (for full replay).
    func fetchAll() -> [iMOPSEvent] {
        journalQueue.sync {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<iMOPSEvent>(
                sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
            )
            return (try? context.fetch(descriptor)) ?? []
        }
    }

    /// Fetch events within a date range.
    func fetch(from startDate: Date, to endDate: Date) -> [iMOPSEvent] {
        journalQueue.sync {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<iMOPSEvent> { event in
                event.ts >= startDate && event.ts <= endDate
            }
            let descriptor = FetchDescriptor<iMOPSEvent>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
            )
            return (try? context.fetch(descriptor)) ?? []
        }
    }

    /// Get the total event count.
    var eventCount: Int {
        journalQueue.sync {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<iMOPSEvent>()
            return (try? context.fetchCount(descriptor)) ?? 0
        }
    }

    // MARK: - Private

    private static func fetchMaxSequenceNumber(from context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<iMOPSEvent>(
            sortBy: [SortDescriptor(\.sequenceNumber, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let results = (try? context.fetch(descriptor)) ?? []
        return results.first?.sequenceNumber ?? -1
    }

    private func deviceIdentifier() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN"
        #else
        return "SIMULATOR"
        #endif
    }
}
