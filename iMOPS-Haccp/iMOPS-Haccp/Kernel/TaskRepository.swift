//
//  TaskRepository.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


//
//  TaskRepository.swift
//  iMOPS_OS_CORE (Labor-Version)
//

import Foundation

struct TaskRepository {

    /// Erzeugt einen neuen Arbeits-Bon mit ChefIQ-Vorbereitung
    /// haccpRef: Optionale HACCP-Referenz (z.B. "CCP-1: Kerntemperatur >= 72°C")
    static func createProductionTask(id: String, title: String, weight: Int = 10, haccpRef: String? = nil) {
        let timestamp = Date().timeIntervalSince1970

        // 1. Zuerst die Metadaten (Gewicht ist wichtig für die Matrix!)
        iMOPS.SET(.task(id, "TITLE"), title)
        iMOPS.SET(.task(id, "CREATED"), timestamp)
        iMOPS.SET(.task(id, "WEIGHT"), weight) // <--- Muss vor dem Status kommen!

        // Claim B: HACCP-Referenz (CCP/SOP/Grenzwert)
        if let ref = haccpRef {
            iMOPS.SET(.task(id, "HACCP_REF"), ref)
        }

        // 2. Jetzt erst den Status setzen - das triggert die Matrix-Berechnung im Kernel
        iMOPS.SET(.task(id, "STATUS"), "OPEN")

        print("iMOPS-GRID: Neuer Task injiziert: \(title) (Weight: \(weight))")

    }
    // Im TaskRepository.swift
    private var lastLocation: String = ""

    mutating func updateLocation(_ newLocation: String) {
        // Nur schreiben, wenn sich der Ort wirklich geändert hat
        guard newLocation != lastLocation else { return }
        
        let startTime = DispatchTime.now()
        
        // Der tatsächliche iMOPS-Schreibbefehl
        // RICHTIG (nutzt deine Syntax.swift Logik):
        iMOPS.SET(.nav("LOCATION"), newLocation)
        
        lastLocation = newLocation
        
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        print("iMOPS-CORE-SPEED: ^NAV.LOCATION gesetzt in \(nanoTime) ns (Optimiert)")
    }
    /// Task quittieren = HACCP Tresor / Revisionssicheres Archiv
    /// Hier ziehen wir die ChefIQ-Werte mit in die Ewigkeit.
    static func completeTask(id: String) {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: now)

        // 1) Daten-Snapshot aus dem Kernel ziehen
        let title: String = iMOPS.GET(.task(id, "TITLE")) ?? "UNBEKANNT"
        let user: String = iMOPS.GET(.nav("ACTIVE_USER")) ?? "SYSTEM"
        
        // NEU: Wir retten die ChefIQ-Pins vor dem Löschen ins Archiv
        let medical: String = iMOPS.GET(.task(id, "PINS.MEDICAL")) ?? "N/A"
        let sop: String = iMOPS.GET(.task(id, "PINS.SOP")) ?? "N/A"
        let haccpRef: String = iMOPS.GET(.task(id, "HACCP_REF")) ?? ""

        // 2) HACCP Tresor versiegeln (^ARCHIVE)
        // Diese Daten sind ab jetzt unantastbar für den operativen Betrieb.
        iMOPS.SET(.archive(id, "TITLE"), title)
        iMOPS.SET(.archive(id, "TIME"), timeString)
        iMOPS.SET(.archive(id, "USER"), user)
        iMOPS.SET(.archive(id, "MEDICAL_SNAPSHOT"), medical)
        iMOPS.SET(.archive(id, "SOP_REFERENCE"), sop)
        if !haccpRef.isEmpty {
            iMOPS.SET(.archive(id, "HACCP_REF"), haccpRef)
        }

        // 3) Den aktiven Arbeitsplatz (Subtree) löschen
        // iMOPS-Prinzip: Sauberer Tisch in Nanosekunden.
        iMOPS.KILLTREE(.task(id, ""))

        print("iMOPS-HACCP: Task \(id) inklusive ChefIQ-Daten versiegelt um \(timeString). ;=)")

        // 4) Automatische Rückkehr zum Auswahl-Bildschirm (Navigations-Logik)
        iMOPS.GOTO("BRIGADE_SELECT")
        DispatchQueue.main.async {
                TheBrain.shared.archiveUpdateTrigger += 1
            }
    }
}
