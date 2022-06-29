import CryptoKit
import CryptoSwift
import Flow
import Foundation

struct ECDSA_P256_Signer: FlowSigner {
    var address: Flow.Address
    var keyIndex: Int
    var hashAlgo: Flow.HashAlgorithm = .SHA3_256
    var signatureAlgo: Flow.SignatureAlgorithm = .ECDSA_P256
    var privateKey: P256.Signing.PrivateKey

    init(address: Flow.Address, keyIndex: Int, privateKey: P256.Signing.PrivateKey) {
        self.address = address
        self.keyIndex = keyIndex
        self.privateKey = privateKey
    }

    func sign(signableData: Data) throws -> Data {
        do {
            let sha3 = CryptoSwift.SHA3(variant: SHA3.Variant.sha256)
            let hashData = Data(sha3.calculate(for: signableData.bytes))
            return try sign_P256(hashData)
        } catch {
            throw error
        }
    }

    func sign_P256(_ hash: Data) throws -> Data {
        var fakeDigest = SHA256.hash(data: Data("42".bytes))
        withUnsafeMutableBytes(of: &fakeDigest) { pointerBuffer in
            for i in 0 ..< pointerBuffer.count {
                pointerBuffer[i] = hash.bytes[i]
            }
        }
        let signature = try privateKey.signature(for: fakeDigest)
        return signature.rawRepresentation
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

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }

    func hexString(prefixed isPrefixed: Bool = false) -> String {
        return self.bytes.reduce(isPrefixed ? "0x" : "") { $0 + String(format: "%02X", $1).lowercased() }
    }

    public mutating func padLeftZero(_ count: Int) -> Data {
        while self.count<count {
            self.insert(0, at: 0)
        }
        return self
    }

    public mutating func padRightZero(_ count: Int) -> Data {
        while self.count<count {
            self.append(0)
        }
        return self
    }
}
