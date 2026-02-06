//
//  ValueCoder.swift
//  iMOPS-Haccp
//
//  Type-safe serialization for the iMOPS event journal.
//  Encodes Any values to String with type prefix, decodes back.
//  Format: "S:string" | "I:42" | "D:3.14" | "B:true"
//

import Foundation

enum ValueCoder {

    // MARK: - Encode

    /// Encode a typed value to a prefixed string for journal storage.
    /// Returns nil for unsupported types.
    static func encode(_ value: Any) -> String? {
        switch value {
        case let s as String:
            return "S:\(s)"
        case let i as Int:
            return "I:\(i)"
        case let d as Double:
            return "D:\(d)"
        case let b as Bool:
            return "B:\(b)"
        default:
            // Fallback: use String(describing:) but mark as unknown
            return "S:\(String(describing: value))"
        }
    }

    // MARK: - Decode

    /// Decode a prefixed string back to its original typed value.
    static func decode(_ encoded: String) -> Any? {
        guard encoded.count >= 2,
              let colon = encoded.firstIndex(of: ":"),
              colon == encoded.index(encoded.startIndex, offsetBy: 1) else {
            // No valid prefix → treat as raw string
            return encoded
        }

        let prefix = encoded[encoded.startIndex]
        let payload = String(encoded[encoded.index(after: colon)...])

        switch prefix {
        case "S": return payload
        case "I": return Int(payload)
        case "D": return Double(payload)
        case "B": return payload == "true"
        default:  return payload
        }
    }
}
