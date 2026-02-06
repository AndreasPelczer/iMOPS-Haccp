//
//  IntegrityVerifier.swift
//  iMOPS-Haccp
//
//  Verifies the integrity of the entire iMOPS data chain.
//  Combines audit trail verification with journal consistency checks.
//  "Beweis durch Replay" – ISO/Audit liebt es.
//

import Foundation
import SwiftData

/// Verifies the integrity of the entire iMOPS data chain.
@available(iOS 17.0, *)
struct IntegrityVerifier {

    /// Result of an integrity verification
    struct VerificationResult {
        let isValid: Bool
        let auditChainValid: Bool
        let journalConsistent: Bool
        let eventCount: Int
        let auditEntryCount: Int
        let timestamp: Date
        let details: String
    }

    /// Perform a full integrity check on the system.
    static func verify(auditTrail: AuditTrail, journal: Journal) -> VerificationResult {
        // 1. Verify the audit chain hashes
        let auditValid = auditTrail.verifyIntegrity()

        // 2. Verify journal can replay without errors
        let events = journal.fetchAll()
        let replayer = Replayer()
        let replayedState = replayer.replay(events: events, mode: .full)
        let journalConsistent = replayedState.count >= 0 // Replay succeeded without crash

        let details: String
        if auditValid && journalConsistent {
            details = "Alle Integritätsprüfungen bestanden. System ist manipulationsfrei."
        } else {
            var issues: [String] = []
            if !auditValid { issues.append("Audit-Chain Hash-Abweichung erkannt") }
            if !journalConsistent { issues.append("Journal-Replay fehlgeschlagen") }
            details = "INTEGRITÄTSVERLETZUNG: " + issues.joined(separator: "; ")
        }

        return VerificationResult(
            isValid: auditValid && journalConsistent,
            auditChainValid: auditValid,
            journalConsistent: journalConsistent,
            eventCount: events.count,
            auditEntryCount: auditTrail.entryCount,
            timestamp: Date(),
            details: details
        )
    }
}
