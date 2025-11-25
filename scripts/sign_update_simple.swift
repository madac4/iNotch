#!/usr/bin/env swift

// Simple sign_update tool using CryptoKit (macOS 10.15+)
// This doesn't require Xcode, only Swift compiler

import Foundation
import Security
import CryptoKit

@available(macOS 10.15, *)
func getKeysFromKeychain(account: String = "ed25519") throws -> (privateKey: Curve25519.Signing.PrivateKey, publicKey: Curve25519.Signing.PublicKey) {
    var item: CFTypeRef?
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "https://sparkle-project.org",
        kSecAttrAccount as String: account,
        kSecAttrProtocol as String: kSecAttrProtocolSSH,
        kSecReturnData as String: kCFBooleanTrue!
    ]
    
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    guard status == errSecSuccess else {
        if status == errSecItemNotFound {
            throw NSError(domain: "SignUpdate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Signing key not found for account '\(account)'. Please run generate_keys tool first or provide key with --ed-key-file"])
        } else if status == errSecAuthFailed {
            throw NSError(domain: "SignUpdate", code: 2, userInfo: [NSLocalizedDescriptionKey: "Access denied. Can't get keys from the keychain. Go to Keychain Access.app, lock the login keychain, then unlock it again."])
        } else {
            throw NSError(domain: "SignUpdate", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to access required key in the Keychain: \(status)"])
        }
    }
    
    guard let encoded = item as? Data,
          let secret = Data(base64Encoded: encoded) else {
        throw NSError(domain: "SignUpdate", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to decode key from Keychain"])
    }
    
    // Sparkle stores keys in different formats:
    // - 32 bytes: Just the seed (newest format)
    // - 64 bytes: 32 byte seed + 32 byte public key (new format)
    // - 96 bytes: Old format
    let seed: Data
    if secret.count == 32 {
        // Just the seed
        seed = secret
    } else if secret.count == 64 {
        // Seed + public key (extract first 32 bytes)
        seed = secret.prefix(32)
    } else if secret.count == 96 {
        // Old format (extract first 32 bytes)
        seed = secret.prefix(32)
    } else {
        throw NSError(domain: "SignUpdate", code: 5, userInfo: [NSLocalizedDescriptionKey: "Key data has invalid length: \(secret.count) bytes (expected 32, 64, or 96)"])
    }
    
    // Create private key from seed
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
    let publicKey = privateKey.publicKey
    
    return (privateKey, publicKey)
}

@available(macOS 10.15, *)
func signFile(filePath: String, printOnly: Bool = false) throws {
    let (privateKey, _) = try getKeysFromKeychain()
    
    // Read file data
    let fileURL = URL(fileURLWithPath: filePath)
    let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
    
    // Sign the data
    let signature = try privateKey.signature(for: fileData)
    let signatureBase64 = signature.base64EncodedString()
    
    if printOnly {
        print(signatureBase64)
    } else {
        print("sparkle:edSignature=\"\(signatureBase64)\" length=\"\(fileData.count)\"")
    }
}

// Main
if #available(macOS 10.15, *) {
    let args = CommandLine.arguments
    
    if args.count < 2 {
        print("Usage: \(args[0]) <dmg_path> [-p]")
        print("  -p: Print only the signature")
        exit(1)
    }
    
    let filePath = args[1]
    let printOnly = args.contains("-p") || args.contains("--print-only")
    
    do {
        try signFile(filePath: filePath, printOnly: printOnly)
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
} else {
    print("Error: Requires macOS 10.15 or later")
    exit(1)
}

