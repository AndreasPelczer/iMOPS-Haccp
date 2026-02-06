//
//  MatrixPoint.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


//
//  TheBrain.swift
//  iMOPS_OS_CORE
//
//  Kernel 1.1 (Matrix Edition)
//  - Thread-safe Storage & Matrix Calculation
//  - Reaktive Meier-Score Überwachung
//  - Service-Fieberkurve (Score-Historie)
//  - TDDA-Update: Mensch-Meier-Formel & Fatigue-Vektor integriert
//

import Foundation
import Observation

/// Ein präziser Datenpunkt für die Service-Fieberkurve
/// Damit dein Bruder (der Ingenieur) die Last-Verteilung grafisch versteht.
struct MatrixPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let score: Int
}

/// ^iMOPS GLOBAL - Die unbestechliche Wahrheit (Kernel)
/// Hinweis für die Brigade:
/// - Wir bleiben beim "MUMPS-Global"-Mapping: [String: Any]
/// - Wir schützen den Zugriff via Serial Queue (Thread-Safety).
/// - NEU: Die Pelczer-Matrix berechnet die Belastung live und schreibt die Historie.
@available(iOS 17.0, *)
@Observable
final class TheBrain {
    static let shared = TheBrain()

    /// Der "Global Store" (MUMPS Global)
    /// Hier liegen alle Realitäts-Daten der Brigade.
    private var storage: [String: Any] = [:]
    
    /// Der "Wachrüttler" für die UI-Synchronisation
    var archiveUpdateTrigger: Int = 0

    /// DIE PELCZER-MATRIX (Meier-Score)
    /// Diese Property ist reaktiv. SwiftUI wird rot, wenn Harry brennt.
    private(set) var meierScore: Int = 0
    
    /// DAS SERVICE-GEDÄCHTNIS
    /// Speichert die letzten 50 Belastungsänderungen für die Fieberkurve.
    var scoreHistory: [MatrixPoint] = []

    /// Kernel-Lock:
    /// Schützt den Store vor Race-Conditions, wenn am Pass das Chaos ausbricht.
    private let kernelQueue = DispatchQueue(label: "imops.kernel.queue", qos: .userInitiated)

    // MARK: - Matrix Engine (Internal)

    /// Berechnet die aktuelle kognitive Last.
    /// Läuft innerhalb der kernelQueue, damit nichts korrumpiert.
    private func refreshMeierScore() {
        let allKeys = storage.keys
        
        // Wir suchen alle offenen Tasks (TDDA: Offene Entropie-Quellen)
        let activeTasks = allKeys.filter {
            $0.hasPrefix("^TASK.") &&
            $0.hasSuffix(".STATUS") &&
            (storage[$0] as? String == "OPEN")
        }
        
        var totalLoad = 0
        var oldestTimestamp: Double = Date().timeIntervalSince1970
        
        for key in activeTasks {
            let components = key.components(separatedBy: ".")
            if components.count >= 2 {
                let taskID = components[1]
                
                // Gewichtung: Standard 10, es sei denn, wir haben spezifisches Gewicht gesetzt
                let weight = storage["^TASK.\(taskID).WEIGHT"] as? Int ?? 10
                totalLoad += weight
                
                // Zeit-Erfassung für den Ermüdungsfaktor ("Die Suppe lügt nicht")
                let created = storage["^TASK.\(taskID).CREATED"] as? Double ?? Date().timeIntervalSince1970
                if created < oldestTimestamp { oldestTimestamp = created }
            }
        }
        
        // --- INJEKTION: MENSCH-MEIER-FORMEL ---
        
        // 1. Ermüdungs-Vektor: Wie lange druckt die älteste Aufgabe?
        let hoursOnClock = (Date().timeIntervalSince1970 - oldestTimestamp) / 3600
        let fatigueFactor = 1.0 + (hoursOnClock / 10.0) // 10% Last-Zuwachs pro Stunde Standzeit
        
        // 2. Kapazitäts-Check: Wer ist in der Brigade?
        let staffCount = allKeys.filter { $0.hasPrefix("^BRIGADE.") && $0.hasSuffix(".NAME") }.count
        let systemCapacity = Double(max(staffCount, 1) * 20) // Jeder Kopf trägt ca. 20 Units stabil
        
        // 3. Berechnung der Pelczer-Matrix (MMZ)
        var finalLoad = (Double(totalLoad) / systemCapacity) * fatigueFactor * 100
        
        // 4. JITTER-LOGIK: Schutz des Individuums ("Joshua-Modus")
        // Wenn der Stress kritisch wird, fügen wir Rauschen hinzu, um Tracking zu verhindern.
        if finalLoad > 80 {
            finalLoad += Double.random(in: -2...5)
        }
        
        let scoreResult = Int(min(max(finalLoad, 0), 100))
        
        // Zurück auf den Main-Thread für das UI-Feuerwerk und die Historie
        DispatchQueue.main.async {
            self.meierScore = scoreResult
            
            // Punkt in die Fieberkurve injizieren
            let newPoint = MatrixPoint(timestamp: Date(), score: scoreResult)
            self.scoreHistory.append(newPoint)
            
            // Wir begrenzen das Gedächtnis auf 50 Punkte (Performance-Schutz)
            if self.scoreHistory.count > 50 {
                self.scoreHistory.removeFirst()
            }
        }
    }

    // MARK: - Kernel Safety

    /// Minimaler Pfad-Validator:
    /// Ein Global muss mit ^ starten und darf kein "Bullshit-Rauschen" (Leerzeichen) enthalten.
    private func validate(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        guard path.hasPrefix("^") else { return false }
        guard !path.contains(" ") else { return false }
        return true
    }

    // MARK: - Core Commands (SET / GET / KILL)

    /// Der S-Befehl (Set)
    /// Schreibt Daten und triggert sofort die Matrix-Berechnung.
    func set(_ path: String, _ value: Any) {
        guard validate(path) else {
            print("iMOPS-KERNEL-ERROR: Ungültiger Pfad (SET): \(path)")
            return
        }

        let start = DispatchTime.now()

        kernelQueue.sync {
            storage[path] = value
            // Zündung der Matrix-Engine bei jeder Änderung
            refreshMeierScore()
        }

        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds

        // Performance-Log: Für das Gefühl von unendlicher Power
        print("iMOPS-CORE-SPEED: \(path) gesetzt in \(nanoTime) ns")
    }

    /// Der G-Befehl (Get) - Typsicherer Zugriff auf die Wahrheit.
    func get<T>(_ path: String) -> T? {
        guard validate(path) else {
            print("iMOPS-KERNEL-ERROR: Ungültiger Pfad (GET): \(path)")
            return nil
        }

        return kernelQueue.sync {
            storage[path] as? T
        }
    }

    /// Der KILL-Befehl (Einzel-Key löschen)
    func kill(_ path: String) {
        guard validate(path) else {
            print("iMOPS-KERNEL-ERROR: Ungültiger Pfad (KILL): \(path)")
            return
        }

        kernelQueue.sync {
            storage.removeValue(forKey: path)
            refreshMeierScore()
        }
    }

    /// KILL-TREE
    /// Löscht ganze Baumstrukturen (z.B. wenn ein Task komplett erledigt ist).
    func killTree(prefix: String) {
        guard validate(prefix) else {
            print("iMOPS-KERNEL-ERROR: Ungültiger Prefix (KILLTREE): \(prefix)")
            return
        }

        kernelQueue.sync {
            let keysToRemove = storage.keys.filter { $0.hasPrefix(prefix) }
            for k in keysToRemove {
                storage.removeValue(forKey: k)
            }
            refreshMeierScore()
        }
    }

    // MARK: - Inventory / Export

    /// Inventur: alle Keys (Snapshot für Debugging)
    func allKeys() -> [String] {
        kernelQueue.sync {
            Array(storage.keys)
        }
    }

    /// Exportiert den gesamten Archiv-Bereich als Text.
    /// Revisionssicherer Snapshot für den Commander.
    func exportLog() -> String {
        let snapshot: [String: Any] = kernelQueue.sync { storage }

        var log = "--- iMOPS HACCP EXPORT ---\n"
        log += "Timestamp: \(Date().description)\n"
        log += "--------------------------\n\n"

        let archiveKeys = snapshot.keys
            .filter { $0.hasPrefix("^ARCHIVE") }
            .sorted()

        for key in archiveKeys {
            log += "\(key): \(snapshot[key] ?? "")\n"
        }

        log += "\n--- ENDE DER ÜBERTRAGUNG ---"
        return log
    }

    /// Holt alle versiegelten IDs aus dem Tresor (^ARCHIVE)
    func getArchiveIDs() -> [String] {
        let snapshot = kernelQueue.sync { storage }
        let archiveKeys = snapshot.keys.filter { $0.hasPrefix("^ARCHIVE") && $0.hasSuffix(".TITLE") }
        
        return archiveKeys.compactMap { key in
            key.components(separatedBy: ".").dropFirst().first
        }.sorted(by: >)
    }
    
    func simulateRushHour() {
        print("iMOPS-MATRIX: Starte Belastungssimulation...")
        
        // Wir ballern 10 kritische Bons in den Kernel
        for i in 1...10 {
            let id = "STRESS_\(i)"
            set("^TASK.\(id).TITLE", "EXTREM-BON #\(i)")
            set("^TASK.\(id).CREATED", Date().timeIntervalSince1970)
            set("^TASK.\(id).WEIGHT", 15) // Jeder Bon wiegt 15 Punkte
            set("^TASK.\(id).STATUS", "OPEN")
        }
        
        print("iMOPS-MATRIX: Simulation abgeschlossen. Aktueller Score: \(meierScore)")
    }

    // MARK: - Seed / Boot

    /// Boot-Sequenz: Minimal-Daten + ChefIQ Injektion
    func seed() {
        // 1) Brigade laden (Stamm-Mannschaft)
        set("^BRIGADE.HARRY.NAME", "Harry Meier")
        set("^BRIGADE.HARRY.ROLE", "Gardemanger")
        set("^BRIGADE.LUKAS.NAME", "Lukas")
        set("^BRIGADE.LUKAS.ROLE", "Runner")

        // 2) Den "Smart-Task" 001 vorbereiten
        set("^TASK.001.TITLE", "MATJES WÄSSERN")
        set("^TASK.001.CREATED", Date().timeIntervalSince1970)
        
        // Zuerst das Gewicht (Kognitive Last) setzen...
        set("^TASK.001.WEIGHT", 5)
        
        // ...und DANN den Status. Erst jetzt findet die Matrix-Engine
        // den Task UND sein Gewicht gleichzeitig im Speicher.
        set("^TASK.001.STATUS", "OPEN")

        // 3) ChefIQ Zusatz-Infos (HACCP / Medizinische Pins)
        set("^TASK.001.PINS.MEDICAL", "BE: 0.1 | kcal: 145 | ALLERGEN: D")
        set("^TASK.001.PINS.SOP", "Wässerung: 12h bei < 4°C. Wasser 2x wechseln.")
        
        // 4) System-Status Zündung
        set("^SYS.STATUS", "KERNEL ONLINE")
        
        // --- DER TRICK FÜR DEN LOG ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("iMOPS-KERNEL: Labor-Seed abgeschlossen. Matrix-Score: \(self.meierScore)")
            print("iMOPS-MATRIX: Harrys Belastung erkannt. System bereit für Service-Druck.")
        }
    }
}
