//
//  AuditTrail.swift
//  iMOPS-Haccp
//
//  HACCP-konformer Audit-Trail mit Blockchain-Prinzip.
//  Jede Aktion wird unveränderlich protokolliert.
//  Manipulation ist über Hash-Verifikation erkennbar.
//
//  "Code lügt nicht. Code ZEIGT."
//
//  ARCHITEKTUR-REGELN:
//  1. Kernel = Hot Path, Audit = Side Channel (kein Deadlock)
//  2. ModelContainer = thread-safe, ModelContext = NICHT thread-safe
//  3. Jede Operation bekommt einen frischen ModelContext (SwiftData-Physik)
//

import Foundation
import SwiftData
import CryptoKit
#if os(iOS)
import UIKit
#endif

/// HACCP-compliant audit trail with blockchain-style hash chaining.
/// Runs on its own serial queue – never blocks the kernel.
/// Each operation creates a fresh ModelContext (SwiftData thread-affinity rule).
@available(iOS 17.0, *)
final class AuditTrail {
    private let modelContainer: ModelContainer
    private let auditQueue = DispatchQueue(label: "imops.audit.queue", qos: .utility)
    private var lastHash: String = "GENESIS"

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // Letzten Hash aus der Datenbank laden
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            self.lastHash = Self.fetchLastHash(from: context)
        }
    }

    // MARK: - Log (async – blockiert den Kernel nie)

    /// Log an action to the audit trail.
    /// Dispatches async to the audit queue – returns immediately.
    /// Hash chain ordering is preserved by the serial queue.
    func log(action: String, key: String? = nil, userId: String, details: String? = nil) {
        auditQueue.async { [self] in
            let context = ModelContext(modelContainer)
            let now = Date()
            let newHash = computeHash(
                previousHash: lastHash,
                action: action,
                key: key,
                userId: userId,
                timestamp: now
            )

            let entry = AuditLogEntry(
                timestamp: now,
                action: action,
                key: key,
                userId: userId,
                deviceId: deviceIdentifier(),
                details: details,
                chainHash: newHash
            )

            context.insert(entry)
            lastHash = entry.chainHash

            try? context.save()
        }
    }

    // MARK: - Verify

    /// Verify the integrity of the entire audit chain.
    /// Returns true if no tampering is detected.
    func verifyIntegrity() -> Bool {
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            let entries = fetchAllEntriesInternal(context: context)
            var expectedHash = "GENESIS"

            for entry in entries {
                let computed = computeHash(
                    previousHash: expectedHash,
                    action: entry.action,
                    key: entry.key,
                    userId: entry.userId,
                    timestamp: entry.timestamp
                )
                if computed != entry.chainHash {
                    print("iMOPS-AUDIT: INTEGRITY VIOLATION at entry \(entry.id)")
                    return false
                }
                expectedHash = entry.chainHash
            }
            return true
        }
    }

    // MARK: - Fetch

    /// Fetch all audit log entries ordered by timestamp.
    func fetchAllEntries() -> [AuditLogEntry] {
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            return fetchAllEntriesInternal(context: context)
        }
    }

    /// Fetch entries for a specific calendar day.
    func fetchEntries(for date: Date) -> [AuditLogEntry] {
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = #Predicate<AuditLogEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            }
            let descriptor = FetchDescriptor<AuditLogEntry>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            return (try? context.fetch(descriptor)) ?? []
        }
    }

    /// Total number of audit entries.
    var entryCount: Int {
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<AuditLogEntry>()
            return (try? context.fetchCount(descriptor)) ?? 0
        }
    }

    /// Timestamp of the very first audit entry (= "Audit vollständig seit").
    var firstEntryDate: Date? {
        auditQueue.sync {
            let context = ModelContext(modelContainer)
            var descriptor = FetchDescriptor<AuditLogEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            descriptor.fetchLimit = 1
            let results = (try? context.fetch(descriptor)) ?? []
            return results.first?.timestamp
        }
    }

    // MARK: - Private

    /// Internal fetch – must be called ON auditQueue.
    private func fetchAllEntriesInternal(context: ModelContext) -> [AuditLogEntry] {
        let descriptor = FetchDescriptor<AuditLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func computeHash(previousHash: String, action: String, key: String?, userId: String, timestamp: Date) -> String {
        let payload = "\(previousHash)|\(action)|\(key ?? "")|\(userId)|\(timestamp.timeIntervalSince1970)"
        let data = Data(payload.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func deviceIdentifier() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN"
        #else
        return "SIMULATOR"
        #endif
    }

    private static func fetchLastHash(from context: ModelContext) -> String {
        var descriptor = FetchDescriptor<AuditLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let results = (try? context.fetch(descriptor)) ?? []
        return results.first?.chainHash ?? "GENESIS"
    }
}
