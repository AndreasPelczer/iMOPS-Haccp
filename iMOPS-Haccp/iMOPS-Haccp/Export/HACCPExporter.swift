//
//  HACCPExporter.swift
//  iMOPS-Haccp
//
//  HACCP-konforme Berichtsgenerierung und Export.
//  Unterstützt: Text, CSV, JSON für Compliance-Dokumentation.
//
//  Berichtstypen:
//  - Tagesbericht: Alle Aktionen eines Tages
//  - Audit-Export: Für externe Prüfer (TÜV, DEKRA)
//  - Journal-Export: Vollständige Event-Historie
//

import Foundation
import SwiftData

/// HACCP-compliant report generator and exporter.
@available(iOS 17.0, *)
struct HACCPExporter {

    // MARK: - Tagesbericht (Daily Report)

    /// Generate a daily HACCP report in text format.
    static func generateDailyReport(
        date: Date,
        auditTrail: AuditTrail,
        journal: Journal,
        brain: TheBrain
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let dateString = formatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        var report = """
        ══════════════════════════════════════════════════════════
                     iMOPS HACCP TAGESBERICHT
                     Datum: \(dateString)
        ══════════════════════════════════════════════════════════

        """

        // Section 1: Audit entries for the day
        let auditEntries = auditTrail.fetchEntries(for: date)
        report += "── AKTIONEN (\(auditEntries.count)) ──────────────────────────\n\n"

        for entry in auditEntries {
            let time = timeFormatter.string(from: entry.timestamp)
            report += "[\(time)] \(entry.action)"
            if let key = entry.key { report += " \(key)" }
            report += " (User: \(entry.userId))"
            if let details = entry.details { report += " – \(details)" }
            report += "\n"
        }

        // Section 2: Archive records
        report += "\n── VERSIEGELTE RECORDS ──────────────────────────\n\n"
        report += brain.exportLog()

        // Section 3: Integrity status
        let integrity = IntegrityVerifier.verify(auditTrail: auditTrail, journal: journal)
        report += "\n\n── INTEGRITÄTS-PRÜFUNG ────────────────────────\n\n"
        report += "Status: \(integrity.isValid ? "GÜLTIG" : "VERLETZUNG ERKANNT")\n"
        report += "Audit-Chain: \(integrity.auditChainValid ? "OK" : "FEHLER")\n"
        report += "Journal: \(integrity.journalConsistent ? "OK" : "FEHLER")\n"
        report += "Events gesamt: \(integrity.eventCount)\n"
        report += "Audit-Einträge gesamt: \(integrity.auditEntryCount)\n"

        report += "\n── ENDE DES BERICHTS ──────────────────────────\n"
        report += "Generiert: \(Date().description)\n"
        report += "System: iMOPS 2.0 HACCP\n"

        return report
    }

    // MARK: - CSV Export

    /// Export audit trail as CSV (semicolon-separated for German locale).
    static func exportAuditCSV(auditTrail: AuditTrail, from startDate: Date? = nil, to endDate: Date? = nil) -> String {
        let entries: [AuditLogEntry]
        if let start = startDate, let end = endDate {
            entries = auditTrail.fetchAllEntries().filter { entry in
                entry.timestamp >= start && entry.timestamp <= end
            }
        } else {
            entries = auditTrail.fetchAllEntries()
        }

        let isoFormatter = ISO8601DateFormatter()

        var csv = "ID;Timestamp;Action;Key;UserID;DeviceID;Details;Hash\n"

        for entry in entries {
            let fields = [
                entry.id.uuidString,
                isoFormatter.string(from: entry.timestamp),
                entry.action,
                entry.key ?? "",
                entry.userId,
                entry.deviceId,
                entry.details ?? "",
                entry.chainHash
            ]
            csv += fields.joined(separator: ";") + "\n"
        }

        return csv
    }

    // MARK: - JSON Export

    /// Export journal events as JSON for API integration.
    static func exportJournalJSON(journal: Journal) -> String {
        let events = journal.fetchAll()
        let isoFormatter = ISO8601DateFormatter()

        var jsonEvents: [[String: Any]] = []
        for event in events {
            var dict: [String: Any] = [
                "id": event.id.uuidString,
                "timestamp": isoFormatter.string(from: event.ts),
                "type": event.type,
                "path": event.path,
                "userId": event.userId,
                "deviceId": event.deviceId,
                "sequenceNumber": event.sequenceNumber
            ]
            if let value = event.value {
                dict["value"] = value
            }
            jsonEvents.append(dict)
        }

        let wrapper: [String: Any] = [
            "export": "iMOPS-Journal",
            "version": "2.0",
            "exportDate": isoFormatter.string(from: Date()),
            "eventCount": events.count,
            "events": jsonEvents
        ]

        if let data = try? JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }

        return "{\"error\": \"Export failed\"}"
    }
}
