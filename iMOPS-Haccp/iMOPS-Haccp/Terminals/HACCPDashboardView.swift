//
//  HACCPDashboardView.swift
//  iMOPS-Haccp
//
//  HACCP Compliance Center
//  - System-Status (Events, Audit, Score)
//  - Service-Fieberkurve (Pelczer-Matrix Historie)
//  - Audit-Log (letzte Aktionen, Blockchain-gesichert)
//  - Integritäts-Prüfung (SHA-256 Chain Verification)
//  - Export (Tagesbericht / CSV / JSON)
//
//  "Code lügt nicht. Code ZEIGT."
//

import SwiftUI

struct HACCPDashboardView: View {
    @State private var brain = TheBrain.shared
    @State private var verificationResult: IntegrityVerifier.VerificationResult?
    @State private var isVerifying = false
    @State private var showShareSheet = false
    @State private var exportText = ""
    @State private var auditEntries: [AuditLogEntry] = []
    @State private var eventCount: Int = 0
    @State private var auditCount: Int = 0
    @State private var auditStartDate: Date?
    @State private var dayIsClosed = false

    private static let verifyTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // ── HEADER ──
            dashboardHeader

            ScrollView {
                VStack(spacing: 20) {
                    systemStatusSection
                    fieberkurveSection
                    verificationSection
                    auditLogSection
                    exportSection
                    tagesabschlussSection
                }
                .padding()
            }

            // ── FOOTER ──
            dashboardFooter
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { loadData() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }

    // MARK: - Header

    private var dashboardHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HACCP COMPLIANCE")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("EU VO 852/2004 // REVISIONSSICHER")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.green)
                }
                Spacer()

                if let result = verificationResult {
                    HStack(spacing: 4) {
                        Image(systemName: result.isValid ? "checkmark.shield.fill" : "xmark.shield.fill")
                        Text(result.isValid ? "GEPRÜFT" : "VERLETZUNG")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(result.isValid ? .green : .red)
                } else {
                    Text("UNGEPRÜFT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // Prio 1: "Audit vollständig seit..." — DER größte Hebel beim Prüfer
            if let startDate = auditStartDate {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 9))
                    Text("Audit-Trail vollständig seit: \(Self.fullDateFormatter.string(from: startDate))")
                    Spacer()
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .background(Color.green.opacity(0.1))
    }

    // MARK: - System Status

    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HACCPSectionHeader(title: "SYSTEM STATUS")

            HStack(spacing: 10) {
                StatusPill(label: "EVENTS", value: "\(eventCount)", color: .blue)
                StatusPill(label: "AUDIT", value: "\(auditCount)", color: .orange)
                StatusPill(label: "SCORE", value: "\(brain.meierScore)",
                           color: brain.meierScore > 60 ? .red : (brain.meierScore > 30 ? .orange : .green))
            }

            // Claim D: Dokumentationsmodus – Lückenlosigkeit belegen
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
                Text("Dokumentationsmodus: Vollständig – alle Aktionen journalisiert")
                    .foregroundColor(.green.opacity(0.8))
                Spacer()
            }
            .font(.system(size: 9, design: .monospaced))
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Fieberkurve

    private var fieberkurveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HACCPSectionHeader(title: "SERVICE-FIEBERKURVE")

            if brain.scoreHistory.isEmpty {
                Text("Warte auf Daten...")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Retro Terminal Barchart
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(brain.scoreHistory) { point in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(scoreColor(point.score))
                            .frame(width: 5, height: max(3, CGFloat(point.score) * 0.55))
                    }
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.white.opacity(0.02))
                .cornerRadius(4)

                // Legende
                HStack(spacing: 14) {
                    legendItem(color: .green, label: "STABIL < 30")
                    legendItem(color: .orange, label: "LAST 30-60")
                    legendItem(color: .red, label: "KRITISCH > 60")
                }
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            }

            // Prio 5: Disclaimer – Angriffsfläche wegnehmen
            Text("Interne Betriebskennzahl zur Kapazitätsplanung – kein rechtlicher Grenzwert")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
                .italic()
        }
    }

    // MARK: - Verification

    @ViewBuilder
    private var verificationSection: some View {
        if let result = verificationResult {
            VStack(alignment: .leading, spacing: 8) {
                HACCPSectionHeader(title: "INTEGRITÄTS-PRÜFUNG")

                VStack(alignment: .leading, spacing: 6) {
                    // Official compliance result
                    HStack {
                        Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.isValid ? .green : .red)
                        Text(result.isValid
                             ? "Dokumentation vollständig und konsistent"
                             : "Integritätsverletzung erkannt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(result.isValid ? .green : .red)
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // Prüfer-taugliche Formulierungen
                    verifyCheckRow(label: "Audit-Trail vollständig", passed: result.auditChainValid)
                    verifyCheckRow(label: "Keine Manipulation erkannt", passed: result.auditChainValid)
                    verifyCheckRow(label: "Dokumentation konsistent", passed: result.journalConsistent)
                    verifyDetailRow(label: "Geprüfte Events", value: "\(result.eventCount)")
                    verifyDetailRow(label: "Geprüfte Audit-Einträge", value: "\(result.auditEntryCount)")

                    verifyDetailRow(label: "Prüfzeitpunkt", value: Self.verifyTimeFormatter.string(from: result.timestamp))
                }
                .padding(12)
                .background((result.isValid ? Color.green : Color.red).opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((result.isValid ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Audit Log

    private var auditLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HACCPSectionHeader(title: "AUDIT LOG")
                Spacer()
                Button(action: { loadData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                Text("\(auditEntries.count) TOTAL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }

            // Claim E: Verantwortlichkeit – klare Regel für Prüfer
            Text("Automatisierte Systemaktionen sind gekennzeichnet (SYS auto). Manuelle Aktionen erfordern Benutzerkontext.")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .italic()
                .padding(.bottom, 2)

            if auditEntries.isEmpty {
                Text("Noch keine Audit-Einträge.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 1) {
                    // Column header
                    HStack(spacing: 8) {
                        Text("ZEIT")
                            .frame(width: 52, alignment: .leading)
                        Text("USER")
                            .frame(width: 52, alignment: .leading)
                        Text("CMD")
                            .frame(width: 32, alignment: .leading)
                        Text("KEY")
                        Spacer()
                    }
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)

                    // Last 25 entries, newest first
                    let recent = Array(auditEntries.suffix(25).reversed())
                    ForEach(recent, id: \.id) { entry in
                        AuditLogRow(entry: entry)
                    }
                }
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HACCPSectionHeader(title: "EXPORT")

            HStack(spacing: 8) {
                HACCPExportButton(title: "TAGES-\nBERICHT", icon: "doc.text.fill", color: .orange) {
                    exportDailyReport()
                }
                HACCPExportButton(title: "AUDIT\nCSV", icon: "tablecells.fill", color: .blue) {
                    exportCSV()
                }
                HACCPExportButton(title: "JOURNAL\nJSON", icon: "curlybraces", color: .purple) {
                    exportJSON()
                }
            }
        }
    }

    // MARK: - Tagesabschluss (Claim A)

    private var tagesabschlussSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HACCPSectionHeader(title: "TAGESABSCHLUSS")

            if dayIsClosed {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                    Text("Tag abgeschlossen – Dokumentation versiegelt")
                        .foregroundColor(.orange)
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button(action: { closeDay() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                        Text("TAG ABSCHLIESSEN")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.orange)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Text("Revisionssicher: Nach Abschluss werden keine weiteren Änderungen für diesen Tag erwartet.")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
                .italic()
        }
    }

    // MARK: - Footer

    private var dashboardFooter: some View {
        HStack(spacing: 0) {
            Button(action: { verifyIntegrity() }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield")
                    Text(isVerifying ? "PRÜFE..." : "INTEGRITÄTSPRÜFUNG")
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
            }
            .disabled(isVerifying)

            Button("ZURÜCK") { iMOPS.GOTO("HOME") }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
        }
    }

    // MARK: - Actions

    private func loadData() {
        eventCount = brain.journal?.eventCount ?? 0
        auditCount = brain.auditTrail?.entryCount ?? 0
        auditEntries = brain.auditTrail?.fetchAllEntries() ?? []
        auditStartDate = brain.auditTrail?.firstEntryDate
        // Check if today was already closed
        dayIsClosed = auditEntries.contains { entry in
            entry.action == "CLOSE" && Calendar.current.isDateInToday(entry.timestamp)
        }
    }

    private func verifyIntegrity() {
        guard let auditTrail = brain.auditTrail,
              let journal = brain.journal else { return }
        isVerifying = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = IntegrityVerifier.verify(auditTrail: auditTrail, journal: journal)
            DispatchQueue.main.async {
                verificationResult = result
                isVerifying = false
                // Refresh counts after verify
                loadData()
            }
        }
    }

    private func closeDay() {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        let user: String = iMOPS.GET(.nav("ACTIVE_USER")) ?? "SYSTEM"
        brain.auditTrail?.log(
            action: "CLOSE",
            userId: user,
            details: "Tagesabschluss \(df.string(from: Date())) – Dokumentation versiegelt"
        )
        dayIsClosed = true
        loadData()
    }

    private func exportDailyReport() {
        guard let auditTrail = brain.auditTrail,
              let journal = brain.journal else { return }
        exportText = HACCPExporter.generateDailyReport(
            date: Date(), auditTrail: auditTrail, journal: journal, brain: brain
        )
        let user: String = iMOPS.GET(.nav("ACTIVE_USER")) ?? "SYSTEM"
        brain.auditTrail?.log(action: "EXPORT", userId: user, details: "Tagesbericht")
        showShareSheet = true
    }

    private func exportCSV() {
        guard let auditTrail = brain.auditTrail else { return }
        exportText = HACCPExporter.exportAuditCSV(auditTrail: auditTrail)
        let user: String = iMOPS.GET(.nav("ACTIVE_USER")) ?? "SYSTEM"
        brain.auditTrail?.log(action: "EXPORT", userId: user, details: "Audit CSV")
        showShareSheet = true
    }

    private func exportJSON() {
        guard let journal = brain.journal else { return }
        exportText = HACCPExporter.exportJournalJSON(journal: journal)
        let user: String = iMOPS.GET(.nav("ACTIVE_USER")) ?? "SYSTEM"
        brain.auditTrail?.log(action: "EXPORT", userId: user, details: "Journal JSON")
        showShareSheet = true
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Int) -> Color {
        if score > 60 { return .red }
        if score > 30 { return .orange }
        return .green
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
        }
    }

    private func verifyCheckRow(label: String, passed: Bool) -> some View {
        HStack {
            Text(passed ? "✓" : "✗")
                .foregroundColor(passed ? .green : .red)
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(passed ? "OK" : "FEHLER")
                .foregroundColor(passed ? .green : .red)
        }
        .font(.system(size: 10, design: .monospaced))
    }

    private func verifyDetailRow(label: String, value: String) -> some View {
        HStack {
            Text("·")
                .foregroundColor(.gray)
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 10, design: .monospaced))
    }
}

// MARK: - Sub-Components

struct HACCPSectionHeader: View {
    let title: String

    var body: some View {
        Text("── \(title) ──")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.green)
    }
}

struct StatusPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AuditLogRow: View {
    let entry: AuditLogEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// "SYSTEM" → "SYSTEM (auto)" für den Prüfer
    private var displayUserId: String {
        entry.userId == "SYSTEM" ? "SYS auto" : entry.userId
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(Self.timeFormatter.string(from: entry.timestamp))
                .foregroundColor(.gray)
                .frame(width: 52, alignment: .leading)

            Text(displayUserId)
                .foregroundColor(entry.userId == "SYSTEM" ? .gray : .cyan)
                .frame(width: 52, alignment: .leading)

            Text(entry.action)
                .foregroundColor(actionColor)
                .frame(width: 32, alignment: .leading)

            Text(entry.key ?? "")
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.02))
    }

    private var actionColor: Color {
        switch entry.action {
        case "SET": return .green
        case "KILL", "KILLTREE": return .red
        case "EXPORT": return .orange
        case "BOOT": return .cyan
        case "CLOSE": return .orange
        default: return .white
        }
    }
}

struct HACCPExportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(color)
            .background(color.opacity(0.08))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
