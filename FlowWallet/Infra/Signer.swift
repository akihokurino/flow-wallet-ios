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
    func toBytes() -> [UInt8]? {
        let length = count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length / 2)
        var index = startIndex
        for _ in 0..<length / 2 {
            let nextIndex = self.index(index, offsetBy: 2)
            if let b = UInt8(self[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
}

extension Data {
    func toHexString() -> String {
        var hexString = ""
        for index in 0..<count {
            hexString += String(format: "%02X", self[index])
        }
        return hexString
    }
}
