import Foundation
import CryptoKit

// Ephemeral test key: never used for production or added to an artifact.
let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let key = Curve25519.Signing.PrivateKey()
let privateFile = folder.appendingPathComponent("private-key")
try key.rawRepresentation.base64EncodedString().write(to: privateFile, atomically: true, encoding: .utf8)
try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privateFile.path)
try key.publicKey.rawRepresentation.base64EncodedString().write(to: folder.appendingPathComponent("public-key"), atomically: true, encoding: .utf8)
