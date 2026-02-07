//
//  HomeMenuView.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


import SwiftUI

struct HomeMenuView: View {
    // Wir beobachten den Kernel direkt
    @State private var brain = TheBrain.shared
    
    // Animation-State für den Stress-Modus
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: 50) {
            
            // --- DER BRANDING-KNOTEN ---
            VStack(spacing: 10) {
                Text("iMOPS OS")
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .tracking(8)
                    // Farbe schlägt bei Stress auf Rot um
                    .foregroundColor(brain.meierScore > 60 ? .red : .white)
                    // Pulsieren nur bei kritischem Score
                    .opacity(brain.meierScore > 60 ? pulseOpacity : 1.0)
                
                Text(brain.meierScore > 60 ? "!! CRITICAL LOAD !!" : "KERNEL_26 // OMNI_GRID")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(brain.meierScore > 60 ? .red : .orange)
            }
            .padding(.top, 60)
            .onAppear {
                // Dauer-Animation im Hintergrund, wirkt sich nur bei Stress aus
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.3
                }
            }
            
            // --- DAS REBELLEN-COCKPIT ---
            VStack(spacing: 25) {
                
                // BRIGADE-ZUGANG
                Button(action: {
                    iMOPS.GOTO("BRIGADE_SELECT")
                }) {
                    RebelButton(title: "BRIGADE", icon: "person.2.fill", color: .orange)
                }
                
                // COMMANDER-ZENTRALE
                Button(action: {
                    iMOPS.GOTO("COMMANDER")
                }) {
                    RebelButton(title: "COMMANDER", icon: "terminal.fill", color: .blue)
                }

                // HACCP COMPLIANCE CENTER
                Button(action: {
                    iMOPS.GOTO("HACCP")
                }) {
                    RebelButton(title: "HACCP", icon: "checkmark.shield.fill", color: .green)
                }

                // STRESS-SIMULATOR (Versteckter Knopf für den Commander)
                Button(action: {
                    brain.simulateRushHour()
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("SIMULATE RUSH HOUR")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.top, 5)

                // OMNI-GRID STATUS
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .symbolEffect(.variableColor.iterative, isActive: true)
                    
                    // Live-Anzeige der Matrix
                    Text("MATRIX-SCORE: \(brain.meierScore)")
                        .fontWeight(.bold)
                    
                    Text("//")
                    
                    Text("GRID: \(iMOPS.GET(.sys("STATUS")) as String? ?? "OFFLINE")")
                }
                .font(.system(size: 12, design: .monospaced))
                // Ampel-Logik für den Footer-Status
                .foregroundColor(brain.meierScore > 60 ? .red : (brain.meierScore > 30 ? .orange : .green))
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // --- FUSSZEILE ---
            Text("NO SQL // NO LATENCY // NO POWER FOR NOBODY")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Hintergrund färbt sich bei extremem Stress leicht rötlich ein
        .background(
            ZStack {
                Color.black
                if brain.meierScore > 60 {
                    Color.red.opacity(0.1).ignoresSafeArea()
                }
            }
        )
    }
}

// RebelButton bleibt im Stil erhalten
struct RebelButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
            Spacer()
            Image(systemName: "chevron.right.square")
        }
        .padding(25)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 2)
                .background(color.opacity(0.1))
        )
    }
}
