//
//  iMOPS.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


import SwiftUI
import SwiftData

@main
struct iMOPS_OS_COREApp: App {
    // Kernel Bootloader
    let brain = TheBrain.shared
    let modelContainer: ModelContainer

    init() {
        // 1) SwiftData Schema aufsetzen (Persistence Layer)
        let schema = Schema([
            iMOPSEvent.self,
            HACCPRecord.self,
            AuditLogEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Schema-Versionierung: Bei Inkompatibilität Store VORHER löschen.
        // NSExceptions (ObjC) können von Swift try/catch NICHT gefangen werden,
        // deshalb dürfen wir einen inkompatiblen Store nie öffnen.
        // Version 2: hash→chainHash, type→eventTypeRaw, isArchived Bool→String, HACCP_REF
        let currentSchemaVersion = 2
        let storedVersion = UserDefaults.standard.integer(forKey: "imops.schema.version")

        if storedVersion != currentSchemaVersion {
            print("iMOPS-KERNEL: Schema-Update \(storedVersion) → \(currentSchemaVersion). Lösche alten Store...")
            Self.deleteStoreFiles()
            UserDefaults.standard.set(currentSchemaVersion, forKey: "imops.schema.version")
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Letzter Fallback: Store nochmal löschen und neu versuchen
            Self.deleteStoreFiles()
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("iMOPS-KERNEL: SwiftData Initialisierung fehlgeschlagen: \(error)")
            }
        }

        // 2) TheBrain mit Persistence konfigurieren
        // Journal + AuditTrail bekommen eigene Queues + ModelContexts (kein Deadlock)
        brain.configure(modelContainer: modelContainer)

        // 3) Boot-Strategie: Journal vorhanden → Rebuild, sonst → Seed
        //    Claim C: Jeder Systemstart wird im Audit-Trail dokumentiert (Reset-Transparenz)
        if let journal = brain.journal, journal.eventCount > 0 {
            // Crash-Recovery: RAM aus Journal rekonstruieren
            let events = journal.fetchAll()
            brain.rebuildFromJournal(events)
            brain.auditTrail?.log(action: "BOOT", userId: "SYSTEM", details: "REBUILD aus \(events.count) Journal-Events")
            print("iMOPS-KERNEL: State rebuilt from \(events.count) events.")
        } else {
            // Erststart: Demo-Daten laden
            brain.seed()
            brain.auditTrail?.log(action: "BOOT", userId: "SYSTEM", details: "INIT – Erststart mit Seed-Daten")
        }
    }

    /// Löscht den alten SwiftData-Store bei Schema-Inkompatibilität.
    /// Sicher: Nur die eigenen DB-Dateien, kein UserDefaults/Keychain.
    private static func deleteStoreFiles() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let fm = FileManager.default
        let extensions = ["store", "store-shm", "store-wal"]
        if let files = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
            for file in files {
                if extensions.contains(where: { file.lastPathComponent.hasSuffix($0) }) {
                    try? fm.removeItem(at: file)
                    print("iMOPS-KERNEL: Gelöscht: \(file.lastPathComponent)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTerminalView()
        }
        .modelContainer(modelContainer)
    }
}
