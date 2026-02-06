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

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("iMOPS-KERNEL: SwiftData Initialisierung fehlgeschlagen: \(error)")
        }

        // 2) TheBrain mit Persistence konfigurieren
        // Journal + AuditTrail bekommen eigene Queues + ModelContexts (kein Deadlock)
        brain.configure(modelContainer: modelContainer)

        // 3) Boot-Strategie: Journal vorhanden → Rebuild, sonst → Seed
        if let journal = brain.journal, journal.eventCount > 0 {
            // Crash-Recovery: RAM aus Journal rekonstruieren
            let events = journal.fetchAll()
            brain.rebuildFromJournal(events)
            print("iMOPS-KERNEL: State rebuilt from \(events.count) events.")
        } else {
            // Erststart: Demo-Daten laden
            brain.seed()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTerminalView()
        }
        .modelContainer(modelContainer)
    }
}
