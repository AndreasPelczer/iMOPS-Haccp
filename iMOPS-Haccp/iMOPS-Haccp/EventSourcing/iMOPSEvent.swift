//
//  iMOPSEvent.swift
//  iMOPS-Haccp
//
//  Immutable event model for the iMOPS event journal.
//  Every state mutation in TheBrain is captured as an event.
//  Enables: Replay, Time-Travel, Audit, Crash-Recovery.
//

import Foundation
import SwiftData

/// The types of state-changing operations in iMOPS
enum iMOPSEventType: String, Codable {
    case set
    case kill
    case killTree
    case navGoto
}

/// A single immutable event in the iMOPS event journal.
/// Persisted via SwiftData for crash-recovery and audit compliance.
@available(iOS 17.0, *)
@Model
class iMOPSEvent {
    var id: UUID
    var ts: Date
    var eventTypeRaw: String      // iMOPSEventType raw value (SwiftData needs primitive)
                                  // "type" ist reserviert (CoreData KVC) → eventTypeRaw
    var path: String
    var value: String?            // ValueCoder-encoded typed value
    var userId: String
    var deviceId: String
    var sequenceNumber: Int       // Monotonic counter for strict ordering

    init(id: UUID = UUID(),
         ts: Date = Date(),
         type: iMOPSEventType,
         path: String,
         value: String? = nil,
         userId: String = "SYSTEM",
         deviceId: String = "",
         sequenceNumber: Int = 0) {
        self.id = id
        self.ts = ts
        self.eventTypeRaw = type.rawValue
        self.path = path
        self.value = value
        self.userId = userId
        self.deviceId = deviceId
        self.sequenceNumber = sequenceNumber
    }

    /// Typed accessor for event type
    var eventType: iMOPSEventType {
        iMOPSEventType(rawValue: eventTypeRaw) ?? .set
    }
}
