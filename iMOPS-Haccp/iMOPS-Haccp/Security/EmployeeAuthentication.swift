//
//  EmployeeAuthentication.swift
//  iMOPS-Haccp
//
//  Mitarbeiter-Authentifizierung für HACCP-Aktionen.
//  Touch ID / Face ID als fortgeschrittene elektronische Signatur (FES).
//  Fallback: 4-stellige PIN.
//

import Foundation
import LocalAuthentication
import CryptoKit

/// Result of an employee authentication attempt.
struct AuthResult {
    let employeeId: String
    let method: AuthMethod
    let timestamp: Date
    let deviceId: String

    enum AuthMethod: String {
        case biometric = "BIOMETRIC"
        case pin = "PIN"
        case combined = "BIOMETRIC+PIN"
    }
}

/// Authentication errors.
enum AuthError: Error, LocalizedError {
    case biometricNotAvailable
    case authenticationFailed
    case cancelled
    case pinMismatch

    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable: return "Biometrische Authentifizierung nicht verfügbar"
        case .authenticationFailed: return "Authentifizierung fehlgeschlagen"
        case .cancelled: return "Authentifizierung abgebrochen"
        case .pinMismatch: return "PIN stimmt nicht überein"
        }
    }
}

/// Employee authentication service for HACCP-compliant action verification.
@available(iOS 17.0, *)
struct EmployeeAuthentication {

    /// Authenticate the current employee using biometrics (Touch ID / Face ID).
    static func authenticate(employeeId: String) async throws -> AuthResult {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Aktion bestätigen für HACCP-Dokumentation"
        )

        if success {
            return AuthResult(
                employeeId: employeeId,
                method: .biometric,
                timestamp: Date(),
                deviceId: deviceIdentifier()
            )
        }

        throw AuthError.authenticationFailed
    }

    /// Authenticate with a 4-digit PIN (fallback for devices without biometrics).
    static func authenticateWithPIN(employeeId: String, pin: String, storedHash: String) throws -> AuthResult {
        let pinHash = hashPIN(pin)

        guard pinHash == storedHash else {
            throw AuthError.pinMismatch
        }

        return AuthResult(
            employeeId: employeeId,
            method: .pin,
            timestamp: Date(),
            deviceId: deviceIdentifier()
        )
    }

    /// Hash a PIN for storage. Never store PINs in plaintext.
    static func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Check if biometric authentication is available on this device.
    static var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Private

    private static func deviceIdentifier() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN"
        #else
        return "SIMULATOR"
        #endif
    }
}
