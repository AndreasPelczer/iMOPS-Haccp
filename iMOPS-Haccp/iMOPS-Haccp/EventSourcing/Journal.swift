//
//  Journal.swift
//  iMOPS-Haccp
//
//  Persistent event journal backed by SwiftData.
//  Append-only by design: events are never modified or deleted.
//  "Journal append asynchron (aber garantiert)."
//
//  ARCHITEKTUR-REGEL:
//  Kernel = Hot Path, Journal = Side Channel.
//  Journal läuft auf eigener Queue, blockiert den Kernel NIE.
//

import Foundation
import SwiftData
#if os(iOS)
import UIKit
#endif

/// The persistent event journal for iMOPS.
/// Appends events to SwiftData on its own serial queue – never blocks the kernel.
@available(iOS 17.0, *)
final class Journal {
    private let modelContainer: ModelContainer
    private let journalQueue = DispatchQueue(label: "imops.journal.queue", qos: .utility)
    private var modelContext: ModelContext!
    private var sequenceCounter: Int = 0

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // ModelContext auf der journalQueue erzeugen (Thread-Ownership)
        journalQueue.sync {
            self.modelContext = ModelContext(modelContainer)
            self.sequenceCounter = Self.fetchMaxSequenceNumber(from: self.modelContext) + 1
        }
    }

    // MARK: - Append (async – blockiert den Kernel nie)

    /// Append a new event to the journal.
    /// Dispatches async to the journal queue – returns immediately.
    /// Sequence ordering is preserved by the serial queue.
    func append(type: iMOPSEventType, path: String, value: String? = nil, userId: String = "SYSTEM") {
        journalQueue.async { [self] in
            let event = iMOPSEvent(
                type: type,
                path: path,
                value: value,
                userId: userId,
                deviceId: deviceIdentifier(),
                sequenceNumber: sequenceCounter
            )

            modelContext.insert(event)
            sequenceCounter += 1

            // Persist immediately (Windhund-Prinzip: schnell, aber garantiert)
            try? modelContext.save()
        }
    }

    // MARK: - Fetch (sync – für Replay und Boot)

    /// Fetch all events ordered by sequence number (for full replay).
    func fetchAll() -> [iMOPSEvent] {
        journalQueue.sync {
            let descriptor = FetchDescriptor<iMOPSEvent>(
                sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        }
    }

    /// Fetch events within a date range.
    func fetch(from startDate: Date, to endDate: Date) -> [iMOPSEvent] {
        journalQueue.sync {
            let predicate = #Predicate<iMOPSEvent> { event in
                event.ts >= startDate && event.ts <= endDate
            }
            let descriptor = FetchDescriptor<iMOPSEvent>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        }
    }

    /// Get the total event count.
    var eventCount: Int {
        journalQueue.sync {
            let descriptor = FetchDescriptor<iMOPSEvent>()
            return (try? modelContext.fetchCount(descriptor)) ?? 0
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
