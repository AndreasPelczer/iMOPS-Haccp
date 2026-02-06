//
//  CommanderView.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


//
//  CommanderView.swift
//  iMOPS_OS_CORE
//
//  HACCP-TRESOR (Dispatcher Edition)
//  - Liest versiegelte Daten aus dem ^ARCHIVE Namespace
//  - Bietet Export-Funktion für die Revisionssicherheit
//  - NEU: Killswitch-Option & Stabilitäts-Monitoring (TDDA-Prinzip)
//

import SwiftUI

struct CommanderView: View {
    // Wir binden das Brain ein
    @State private var brain = TheBrain.shared
    @State private var showShareSheet = false
    @State private var exportText = ""
    
    // Killswitch-Sicherung (Roman-Anker: Joshua)
    @State private var killswitchEngaged = false

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER: THERMODYNAMISCHES DASHBOARD ---
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMMANDER: HACCP-TRESOR")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                    Text("IMMUTABLE RECORDS // KERNEL_26")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.blue)
                }
                Spacer()
                
                // Status-Indikator basierend auf der Pelczer-Matrix
                let isCritical = brain.meierScore > 80
                Circle()
                    .fill(isCritical ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                Text(isCritical ? "CRITICAL" : "SECURE")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(isCritical ? .red : .green)
            }
            .padding()
            .background(Color.blue.opacity(0.15))

            // --- TRESOR-LISTE: DIE UNBESTECHLICHE WAHRHEIT ---
            ScrollView {
                VStack(spacing: 2) {
                    // Wir erzwingen hier die Beobachtung des meierScore als "Taktgeber"
                    let _ = brain.meierScore
                    let ids = brain.getArchiveIDs()
                    
                    if ids.isEmpty {
                        VStack(spacing: 10) {
                            Text("TRESOR LEER")
                                .font(.system(size: 12, design: .monospaced))
                            Text("„Noch lügt die Suppe nicht.“")
                                .font(.system(size: 10, design: .serif)).italic()
                        }
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                    }
                    
                    ForEach(ids, id: \.self) { id in
                        ArchiveRow(id: id)
                    }
                }
            }

            // --- COMMANDS: DER „HANDTUCH“-EXPORT ---
            VStack(spacing: 0) {
                if !killswitchEngaged {
                    Button(action: {
                        // Roman-Bezug: "Code lügt nicht. Code ZEIGT."
                        exportText = brain.exportLog()
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("BERICHT EXPORTIEREN")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                    }
                }
                
                HStack(spacing: 0) {
                    // ZURÜCK BUTTON
                    Button("ZURÜCK") { iMOPS.GOTO("HOME") }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.05))
                    
                    // KILLSWITCH (Optionaler System-Schutz)
                    Button(killswitchEngaged ? "LOCKED" : "KILLSWITCH") {
                        withAnimation { killswitchEngaged.toggle() }
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(killswitchEngaged ? Color.red : Color.red.opacity(0.1))
                    .foregroundColor(.white)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }
}

struct ArchiveRow: View {
    let id: String
    @State private var brain = TheBrain.shared // Der Aufpasser

    var body: some View {
        // Wir holen die Daten hart aus dem Speicher, keine Kompromisse
        let archiveTitle = iMOPS.GET(.archive(id, "TITLE")) as String? ?? "DATA_LOCK_ERROR"
        let archiveTime   = iMOPS.GET(.archive(id, "TIME")) as String? ?? "--:--"
        let medical       = iMOPS.GET(.archive(id, "MEDICAL_SNAPSHOT")) as String?
        let user          = iMOPS.GET(.archive(id, "USER")) as String? ?? "SYSTEM"

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(id)")
                    .foregroundColor(.green)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                
                Text(archiveTitle) // Hier gibt es kein Entkommen mehr
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(archiveTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                // Wer hat es quittiert? (Bezug: "Verantwortung ohne Nachweis")
                Label(user, systemImage: "checkmark.seal.fill")
                
                if let medicalData = medical {
                    Label(medicalData, systemImage: "pills.fill")
                        .foregroundColor(.orange.opacity(0.7))
                }
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        // Dieser ID-Anker erzwingt, dass die UI stirbt und neu geboren wird,
        // wenn der Kernel-Score sich ändert. Absolute Synchronisation.
        .id("row-\(id)-\(brain.meierScore)")
    }
}

// --- HELPER: SHARE SHEET (Brücke zu UIKit) ---
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
