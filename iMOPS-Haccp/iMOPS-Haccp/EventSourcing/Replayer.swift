//
//  Replayer.swift
//  iMOPS-Haccp
//
//  Replays iMOPS events into a RAMState snapshot.
//  Supports full replay, time-bounded replay, and count-bounded replay.
//
//  "Konserviere Arbeit als Zustandsänderungen."
//  – Thermodynamik-Prinzip
//

import Foundation

/// Controls how far events are replayed
enum ReplayMode {
    case full                      // All events
    case untilDate(Date)           // Events up to a specific point in time
    case untilEventCount(Int)      // First N events only
}

/// Replays iMOPS events into a RAMState for time-travel and recovery.
final class Replayer {

    /// Replay events according to the given mode, producing a state snapshot.
    func replay(events: [iMOPSEvent], mode: ReplayMode) -> RAMState {
        let state = RAMState()

        let filtered: [iMOPSEvent] = {
            switch mode {
            case .full:
                return events
            case .untilDate(let date):
                return events.filter { $0.ts <= date }
            case .untilEventCount(let n):
                return Array(events.prefix(max(0, n)))
            }
        }()

        for ev in filtered {
            apply(ev, to: state)
        }

        return state
    }

    // MARK: - Private

    private func apply(_ ev: iMOPSEvent, to state: RAMState) {
        switch ev.eventType {
        case .set:
            guard let v = ev.value else { return }
            state.set(path: ev.path, value: v)

        case .kill:
            state.kill(path: ev.path)

        case .killTree:
            state.killTree(prefix: ev.path)

        case .navGoto:
            guard let v = ev.value else { return }
            state.set(path: "^NAV.LOCATION", value: v)
        }
    }
}
