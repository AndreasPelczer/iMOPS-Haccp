//
//  TimestampService.swift
//  iMOPS-Haccp
//
//  eIDAS-konformer Zeitstempeldienst.
//  Phase 2: Lokaler Fallback mit SHA-256.
//  Wenn ein TSA konfiguriert ist, wird an den Vertrauensdienst weitergeleitet.
//
//  Empfohlene Anbieter:
//  - D-Trust (Bundesdruckerei) ~0,10 EUR/Stempel
//  - SwissSign ~0,08 EUR/Stempel
//  - GlobalSign ~0,05 EUR/Stempel
//

import Foundation
import CryptoKit

/// Represents a qualified timestamp from an eIDAS trust service.
struct QualifiedTimestamp: Codable {
    let timestamp: Date
    let hash: String
    let signature: String
    let tsaName: String           // Trust Service Authority name
    let certificate: String?

    var isValid: Bool {
        !signature.isEmpty && !hash.isEmpty
    }

    /// Whether this is a locally generated (non-qualified) timestamp
    var isLocal: Bool {
        tsaName == "iMOPS-LOCAL"
    }
}

/// Configuration for a qualified timestamp authority (TSA)
struct TimestampServiceConfig {
    let baseURL: URL
    let apiKey: String
    let tsaName: String

    /// D-Trust (Bundesdruckerei) – recommended for German HACCP
    static let dTrust = TimestampServiceConfig(
        baseURL: URL(string: "https://tsa.d-trust.net/api/v1")!,
        apiKey: "",
        tsaName: "D-Trust TSA"
    )

    /// SwissSign – EU alternative
    static let swissSign = TimestampServiceConfig(
        baseURL: URL(string: "https://tsa.swisssign.net/api/v1")!,
        apiKey: "",
        tsaName: "SwissSign TSA"
    )

    /// GlobalSign – cost-effective option
    static let globalSign = TimestampServiceConfig(
        baseURL: URL(string: "https://timestamp.globalsign.com/api/v1")!,
        apiKey: "",
        tsaName: "GlobalSign TSA"
    )
}

/// Service for requesting eIDAS-compliant qualified timestamps.
/// Currently provides local timestamps with SHA-256 hashing.
/// When a TSA is configured, requests are forwarded to the trust service.
@available(iOS 17.0, *)
struct TimestampService {

    private static var config: TimestampServiceConfig?

    /// Configure the trust service connection.
    static func configure(with config: TimestampServiceConfig) {
        Self.config = config
    }

    /// Request a timestamp for the given data.
    /// Falls back to local timestamping if no TSA is configured (Offline-First).
    static func requestTimestamp(for data: Data) async throws -> QualifiedTimestamp {
        let hash = SHA256.hash(data: data)
        let hashString = hash.map { String(format: "%02x", $0) }.joined()

        if let config = Self.config, !config.apiKey.isEmpty {
            return try await requestQualifiedTimestamp(hash: hashString, config: config)
        }

        // Local fallback (not eIDAS-qualified, but functional for offline-first)
        return QualifiedTimestamp(
            timestamp: Date(),
            hash: hashString,
            signature: "LOCAL-\(hashString.prefix(16))",
            tsaName: "iMOPS-LOCAL",
            certificate: nil
        )
    }

    /// Verify a timestamp against the original data.
    static func verify(timestamp: QualifiedTimestamp, data: Data) -> Bool {
        let hash = SHA256.hash(data: data)
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        return hashString == timestamp.hash
    }

    // MARK: - TSA Integration (Phase 2)

    private static func requestQualifiedTimestamp(hash: String, config: TimestampServiceConfig) async throws -> QualifiedTimestamp {
        var request = URLRequest(url: config.baseURL.appendingPathComponent("timestamp"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "hash": hash,
            "hashAlgorithm": "SHA-256",
            "certReq": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TimestampError.tsaRequestFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tsaResponse = try decoder.decode(TSAResponse.self, from: data)

        return QualifiedTimestamp(
            timestamp: tsaResponse.genTime,
            hash: hash,
            signature: tsaResponse.signature,
            tsaName: config.tsaName,
            certificate: tsaResponse.certificate
        )
    }
}

// MARK: - Supporting Types

enum TimestampError: Error, LocalizedError {
    case tsaRequestFailed
    case invalidResponse
    case hashMismatch

    var errorDescription: String? {
        switch self {
        case .tsaRequestFailed: return "TSA-Anfrage fehlgeschlagen"
        case .invalidResponse: return "Ungültige TSA-Antwort"
        case .hashMismatch: return "Hash-Verifikation fehlgeschlagen"
        }
    }
}

private struct TSAResponse: Codable {
    let genTime: Date
    let signature: String
    let certificate: String?
}
