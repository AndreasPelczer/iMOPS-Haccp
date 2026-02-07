//
//  HACCPRecord.swift
//  iMOPS-Haccp
//
//  Revisionssichere HACCP-Dokumentation (EU VO 852/2004).
//  Immutable once created – supports the requirement for
//  "nachträglich nicht veränderbar" records.
//

import Foundation
import SwiftData

/// A persistent HACCP-compliant record.
/// Represents a single key-value entry with full provenance.
@available(iOS 17.0, *)
@Model
class HACCPRecord {
    var id: UUID
    var key: String               // e.g. "^TASK.001.TITLE"
    var value: String             // The stored value
    var createdAt: Date
    var createdBy: String         // Mitarbeiter-ID
    var signature: String?        // Qualifizierter Zeitstempel (Phase 2)
    var isArchived: String        // "true"/"false" – Bool vermieden (CoreData NSNumber-Konflikt)

    // Für Audit-Trail / Rückverfolgbarkeit
    var previousValue: String?
    var changeReason: String?

    init(id: UUID = UUID(),
         key: String,
         value: String,
         createdBy: String,
         signature: String? = nil,
         isArchived: String = "false",
         previousValue: String? = nil,
         changeReason: String? = nil) {
        self.id = id
        self.key = key
        self.value = value
        self.createdAt = Date()
        self.createdBy = createdBy
        self.signature = signature
        self.isArchived = isArchived
        self.previousValue = previousValue
        self.changeReason = changeReason
    }
}
