//
//  BrainNamespace.swift
//  iMOPS-Haccp
//
//  Created by Andreas Pelczer on 06.02.26.
//


//
//  Syntax.swift
//  iMOPS_OS_CORE
//
//  Kernel-Syntax 1.0 (Safety Edition)
//  - Typed Paths (weniger Vertipper)
//  - iMOPS DSL bleibt: SET/GET/GOTO
//

import Foundation

// MARK: - Typed Paths (BrainPath)

/// Namespaces: das sind deine "Global Root Nodes"
/// Wir halten das bewusst simpel und erweiterbar.
enum BrainNamespace: String {
    case nav = "^NAV"
    case sys = "^SYS"
    case task = "^TASK"
    case archive = "^ARCHIVE"
    case brigade = "^BRIGADE"
}

/// BrainPath kapselt einen Global-Key.
/// Vorteil: du baust Keys kontrolliert zusammen, statt überall Strings zu tippen.
struct BrainPath: Hashable, CustomStringConvertible {
    let raw: String
    var description: String { raw }

    private init(_ raw: String) { self.raw = raw }

    // MARK: - Standard Factory Methods

    static func nav(_ key: String) -> BrainPath {
        BrainPath("\(BrainNamespace.nav.rawValue).\(key)")
    }

    static func sys(_ key: String) -> BrainPath {
        BrainPath("\(BrainNamespace.sys.rawValue).\(key)")
    }

    static func task(_ id: String, _ field: String) -> BrainPath {
        BrainPath("\(BrainNamespace.task.rawValue).\(id).\(field)")
    }

    static func archive(_ id: String, _ field: String) -> BrainPath {
        BrainPath("\(BrainNamespace.archive.rawValue).\(id).\(field)")
    }

    static func brigade(_ id: String, _ field: String) -> BrainPath {
        BrainPath("\(BrainNamespace.brigade.rawValue).\(id).\(field)")
    }
}

// MARK: - iMOPS DSL

/// iMOPS-Kurzbefehle (Terminal-Syntax)
/// Wir bieten beides:
/// - SET/GET mit BrainPath (empfohlen)
/// - SET/GET mit String (Legacy, falls du noch schnell testen willst)
struct iMOPS {

    // MARK: Typed (empfohlen)

    static func SET(_ path: BrainPath, _ value: Any) {
        TheBrain.shared.set(path.raw, value)
    }

    static func GET<T>(_ path: BrainPath) -> T? {
        TheBrain.shared.get(path.raw)
    }

    static func KILL(_ path: BrainPath) {
        TheBrain.shared.kill(path.raw)
    }

    static func KILLTREE(_ prefix: BrainPath) {
        TheBrain.shared.killTree(prefix: prefix.raw)
    }

    /// Standortwechsel (Router im Kernel)
    static func GOTO(_ location: String) {
        SET(.nav("LOCATION"), location)
    }

    // MARK: Legacy (optional)

    static func SET(_ path: String, _ value: Any) {
        TheBrain.shared.set(path, value)
    }

    static func GET<T>(_ path: String) -> T? {
        TheBrain.shared.get(path)
    }
}
