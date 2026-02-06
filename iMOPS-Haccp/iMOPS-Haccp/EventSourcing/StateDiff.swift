//
//  StateDiff.swift
//  iMOPS-Haccp
//
//  Computes the difference between two RAMState snapshots.
//  Used for time-travel debugging, audit comparison, and support forensics.
//
//  "Zeig mir den Zustand vor der Beschwerde."
//

import Foundation

/// Represents the difference between two RAMState snapshots.
struct StateDiff {
    let added: [String: String]
    let removed: [String: String]
    let changed: [String: (from: String, to: String)]

    var isEmpty: Bool {
        added.isEmpty && removed.isEmpty && changed.isEmpty
    }

    /// Human-readable summary of the diff
    var summary: String {
        var lines: [String] = []

        if !added.isEmpty {
            lines.append("ADDED (\(added.count)):")
            for (k, v) in added.sorted(by: { $0.key < $1.key }) {
                lines.append("  + \(k) = \(v)")
            }
        }

        if !removed.isEmpty {
            lines.append("REMOVED (\(removed.count)):")
            for (k, v) in removed.sorted(by: { $0.key < $1.key }) {
                lines.append("  - \(k) = \(v)")
            }
        }

        if !changed.isEmpty {
            lines.append("CHANGED (\(changed.count)):")
            for (k, v) in changed.sorted(by: { $0.key < $1.key }) {
                lines.append("  ~ \(k): \(v.from) -> \(v.to)")
            }
        }

        if lines.isEmpty {
            return "NO CHANGES"
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Factory

    /// Compute the diff between two RAMState snapshots.
    static func between(old: RAMState, new: RAMState) -> StateDiff {
        let oldS = old.storage
        let newS = new.storage

        var added: [String: String] = [:]
        var removed: [String: String] = [:]
        var changed: [String: (from: String, to: String)] = [:]

        for (k, v) in newS {
            if let ov = oldS[k] {
                if ov != v { changed[k] = (ov, v) }
            } else {
                added[k] = v
            }
        }

        for (k, v) in oldS where newS[k] == nil {
            removed[k] = v
        }

        return StateDiff(added: added, removed: removed, changed: changed)
    }
}
