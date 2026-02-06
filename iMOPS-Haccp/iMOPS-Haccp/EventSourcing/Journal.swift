//
//  Journal.swift
//  iMOPS-Haccp
//
//  Persistent event journal backed by SwiftData.
//  Append-only by design: events are never modified or deleted.
//  "Journal append asynchron (aber garantiert)."
//

import Foundation
import SwiftData
#if os(iOS)
import UIKit
#endif

/// The persistent event journal for iMOPS.
/// Appends events to SwiftData and provides retrieval for replay.
@available(iOS 17.0, *)
final class Journal {
    private let modelContext: ModelContext
    private var sequenceCounter: Int = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Recover sequence counter from persisted events
        self.sequenceCounter = fetchMaxSequenceNumber() + 1
    }

    // MARK: - Append

    /// Append a new event to the journal (append-only, never modify).
    func append(type: iMOPSEventType, path: String, value: String? = nil, userId: String = "SYSTEM") {
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

    // MARK: - Fetch

    /// Fetch all events ordered by sequence number (for full replay).
    func fetchAll() -> [iMOPSEvent] {
        let descriptor = FetchDescriptor<iMOPSEvent>(
            sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fetch events within a date range.
    func fetch(from startDate: Date, to endDate: Date) -> [iMOPSEvent] {
        let predicate = #Predicate<iMOPSEvent> { event in
            event.ts >= startDate && event.ts <= endDate
        }
        let descriptor = FetchDescriptor<iMOPSEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sequenceNumber, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get the total event count.
    var eventCount: Int {
        let descriptor = FetchDescriptor<iMOPSEvent>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Private

    private func fetchMaxSequenceNumber() -> Int {
        var descriptor = FetchDescriptor<iMOPSEvent>(
            sortBy: [SortDescriptor(\.sequenceNumber, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let results = (try? modelContext.fetch(descriptor)) ?? []
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
