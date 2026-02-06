//
//  AuditLogEntry.swift
//  iMOPS-Haccp
//
//  Unveränderlicher Audit-Log-Eintrag mit Blockchain-Prinzip.
//  Jeder Eintrag enthält den SHA-256 Hash des vorherigen Eintrags.
//  Manipulation → Hash-Kette bricht → sofort erkennbar.
//

import Foundation
import SwiftData

/// An immutable audit log entry with blockchain-style hash chaining.
@available(iOS 17.0, *)
@Model
class AuditLogEntry {
    var id: UUID
    var timestamp: Date
    var action: String            // SET, KILL, KILLTREE, LOGIN, EXPORT
    var key: String?
    var userId: String
    var deviceId: String
    var ipAddress: String?
    var details: String?
    var chainHash: String         // SHA-256 chain: H(previous_hash + current_data)
                                  // "hash" ist reserviert (Hashable-Protokoll) → chainHash

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         action: String,
         key: String? = nil,
         userId: String,
         deviceId: String,
         ipAddress: String? = nil,
         details: String? = nil,
         chainHash: String) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.key = key
        self.userId = userId
        self.deviceId = deviceId
        self.ipAddress = ipAddress
        self.details = details
        self.chainHash = chainHash
    }
}
