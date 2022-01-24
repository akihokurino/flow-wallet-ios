import CryptoKit
import Flow
import Foundation

struct ECDSA_P256_Signer: FlowSigner {
    var address: Flow.Address
    var keyIndex: Int
    var hash: Flow.HashAlgorithm = .SHA3_256
    var signature: Flow.SignatureAlgorithm = .ECDSA_P256

    var privateKey: P256.Signing.PrivateKey

    init(address: Flow.Address, keyIndex: Int, privateKey: P256.Signing.PrivateKey) {
        self.address = address
        self.keyIndex = keyIndex
        self.privateKey = privateKey
    }

    func sign(signableData: Data) throws -> Data {
        do {
            return try privateKey.signature(for: signableData).rawRepresentation
        } catch {
            throw error
        }
    }
}

extension String {
    var hexValue: [UInt8] {
        var startIndex = self.startIndex
        return (0 ..< count / 2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            return UInt8(self[startIndex ... endIndex], radix: 16)
        }
    }
}
