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
//  - FIX: Dynamische Task-Auflistung statt Hardcoding auf Task 001
//

import SwiftUI

struct ProductionTaskView: View {
    let userID: String
    @State private var brain = TheBrain.shared
    @State private var showNewTask = false
    @State private var newTaskTitle = ""

    var body: some View {
        VStack(spacing: 20) {

            // --- HEADER: STATUS & IDENTITÄT ---
            HStack {
                Text("POSTEN: \(userID)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .accessibilityLabel("Aktiver Posten: \(userID)")

                Spacer()

                let score = brain.meierScore
                Text("MEIER-SCORE: \(score)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(score > 70 ? .red : (score > 40 ? .orange : .green))
                    .accessibilityLabel("Belastungs-Score: \(score) von 100")
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
                    // Dynamisch alle offenen Tasks aus dem Kernel laden
                    let _ = brain.meierScore // Observation-Trigger
                    let openIDs = brain.getOpenTaskIDs()

                    if openIDs.isEmpty {
                        // Leerer Zustand: Klare Botschaft statt Endlos-Spinner
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.green.opacity(0.5))
                            Text("KEINE OFFENEN AUFGABEN")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("Alle Bons abgearbeitet.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.top, 50)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Keine offenen Aufgaben. Alle Bons abgearbeitet.")
                    } else {
                        ForEach(openIDs, id: \.self) { taskID in
                            let title: String = iMOPS.GET(.task(taskID, "TITLE")) ?? "AUFGABE \(taskID)"
                            TaskRow(id: taskID, title: title)
                        }
                    }
                }
                .padding()
            }

            // --- NEUER TASK ERSTELLEN ---
            if showNewTask {
                HStack(spacing: 8) {
                    TextField("Aufgabe eingeben...", text: $newTaskTitle)
                        .font(.system(size: 14, design: .monospaced))
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                        .accessibilityLabel("Neue Aufgabe eingeben")

                    Button("OK") {
                        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let id = String(format: "%03d", Int.random(in: 100...999))
                        TaskRepository.createProductionTask(id: id, title: newTaskTitle.uppercased())
                        newTaskTitle = ""
                        showNewTask = false
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(10)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(6)
                    .accessibilityLabel("Aufgabe erstellen")
                    .accessibilityHint("Erstellt eine neue Aufgabe mit dem eingegebenen Titel")
                }
                .padding(.horizontal)
            }

            Spacer()

            // --- FOOTER: ACTIONS ---
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation { showNewTask.toggle() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showNewTask ? "xmark" : "plus")
                        Text(showNewTask ? "ABBRECHEN" : "NEUER BON")
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                }
                .accessibilityLabel(showNewTask ? "Neue Aufgabe abbrechen" : "Neue Aufgabe erstellen")

                Button("LOG OUT") {
                    iMOPS.GOTO("HOME")
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .accessibilityLabel("Abmelden und zum Hauptmenü zurückkehren")
            }
        }
        .background(
            ZStack {
                Color.black.ignoresSafeArea()
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
                Divider().background(Color.white.opacity(0.1))

                let quote: String = {
                    if brain.meierScore > 70 {
                        return "„Wenn der Koch müde ist, wird das Messer schwer.""
                    } else if brain.meierScore > 40 {
                        return "„Ein Zettel weiß nicht, dass jemand seit zehn Stunden steht.""
                    } else {
                        return "„Stabilität entsteht durch Klarheit.""
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Aufgabe \(title), ID \(id)")
        .accessibilityHint("Doppeltippen zum Abschließen")
    }
}
