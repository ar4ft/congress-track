import Foundation
import CryptoKit

// Derive the public key from the current Sparkle private seed without logging either key.
let environment = ProcessInfo.processInfo.environment
guard let keyFile = environment["CONGRESSTRACK_SPARKLE_KEY_FILE"],
      let encoded = try? String(contentsOfFile: keyFile).trimmingCharacters(in: .whitespacesAndNewlines),
      let seed = Data(base64Encoded: encoded), seed.count == 32,
      let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed),
      let expected = environment["SPARKLE_PUBLIC_KEY"],
      key.publicKey.rawRepresentation.base64EncodedString() == expected.trimmingCharacters(in: .whitespacesAndNewlines) else {
    fputs("Sparkle public/private keys do not match. Export the keypair with Sparkle's generate_keys tool.\n", stderr)
    exit(1)
}
print("Sparkle public/private keypair verified.")
