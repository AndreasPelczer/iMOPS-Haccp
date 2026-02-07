//
//  ProductionTaskView.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


//
//  ProductionTaskView.swift
//  iMOPS_OS_CORE
//
//  KERN-LOGIK: Produktions-Terminal (Refined Edition)
//  - Zeigt Aufgaben direkt aus dem iMOPS-Kernel
//  - Spiegelt ChefIQ-Wissen (Nährwerte/Allergene)
//  - Integriert Thermodynamik-Leitsätze als System-Anker
//  - NEU: Reaktive Belastungs-Visualisierung (Mensch-Meier-Schutz)
//

import SwiftUI

struct ProductionTaskView: View {
    let userID: String
    @State private var brain = TheBrain.shared

    var body: some View {
        VStack(spacing: 20) {

            // --- HEADER: STATUS & IDENTITÄT ---
            // Im Header-HStack der ProductionTaskView
            HStack {
                Text("POSTEN: \(userID)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                // Die Live-Anzeige der Pelczer-Matrix
                // Bezug: "Die Suppe lügt nicht" - Das System atmet mit.
                let score = brain.meierScore
                Text("MEIER-SCORE: \(score)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(score > 70 ? .red : (score > 40 ? .orange : .green))
            
            }
            .padding()
            .background(Color.white.opacity(0.05))

            Text("OFFENE AUFGABEN")
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // --- TASK-LISTE: DER PULS DER KÜCHE ---
            ScrollView {
                VStack(spacing: 16) {
                    // Wir suchen nach Task 001 (unserer Matjes-Demo) im Kernel
                    if let taskTitle: String = iMOPS.GET(.task("001", "TITLE")) {
                        TaskRow(id: "001", title: taskTitle)
                    } else {
                        // Wenn der Kernel leer ist, wartet das System passiv
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.green)
                            Text("WARTEN AUF INJEKTION...")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                    }
                }
                .padding()
            }

            Spacer()

            // --- EXIT: LOGOUT ---
            Button("LOG OUT") {
                iMOPS.GOTO("HOME") // Setzt ^NAV.LOCATION auf HOME
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.red)
            .padding()
        }
        .background(
            ZStack {
                Color.black.ignoresSafeArea()
                // Mensch-Meier-Visier: Hintergrund glüht bei Stress
                if brain.meierScore > 70 {
                    Color.red.opacity(0.05).ignoresSafeArea()
                }
            }
        )
    }
}

// MARK: - TASK ROW (DER INTERAKTIVE BON)
struct TaskRow: View {
    let id: String
    let title: String
    @State private var brain = TheBrain.shared

    var body: some View {
        Button(action: {
            // Auslösen der HACCP-Kausalkette im TaskRepository
            TaskRepository.completeTask(id: id)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("ID: #\(id)")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    Spacer()
                    
                    // Quittierungs-Button (Reaktionsebene)
                    Text("FERTIG")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }

                // --- HACCP-REFERENZ (Claim B) ---
                if let haccpRef: String = iMOPS.GET(.task(id, "HACCP_REF")) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                        Text(haccpRef)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }

                // --- INJEKTION: ChefIQ WISSENWARE ---
                // Hier ziehen wir die klinischen Daten, falls sie im Kernel liegen
                if let medical: String = iMOPS.GET(.task(id, "PINS.MEDICAL")) {
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 12))
                        Text(medical)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                }

                // --- INJEKTION: THERMODYNAMIK-LEITSATZ ---
                // Roman-Anker: Je nach Score ändert sich die Botschaft (Living Documentation)
                Divider().background(Color.white.opacity(0.1))
                
                let quote: String = {
                    if brain.meierScore > 70 {
                        return "„Wenn der Koch müde ist, wird das Messer schwer.“"
                    } else if brain.meierScore > 40 {
                        return "„Ein Zettel weiß nicht, dass jemand seit zehn Stunden steht.“"
                    } else {
                        return "„Stabilität entsteht durch Klarheit.“"
                    }
                }()
                
                Text(quote)
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(brain.meierScore > 70 ? .red.opacity(0.8) : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(brain.meierScore > 70 ? Color.red.opacity(0.5) : Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
