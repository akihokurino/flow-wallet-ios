//
//  CadenceTypeTest
//
//  Copyright 2022 Outblock Pty Ltd
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@testable import BigInt
import CryptoKit
@testable import Flow
import XCTest

final class CodableTests: XCTestCase {
    var flowAPI: FlowAccessProtocol!

    var addressC = Flow.Address(hex: "0xe242ccfb4b8ea3e2")
    let publicKeyC = try! P256.KeyAgreement.PublicKey(rawRepresentation: "adbf18dae6671e6b6a92edf00c79166faba6babf6ec19bd83eabf690f386a9b13c8e48da67973b9cf369f56e92ec25ede5359539f687041d27d0143afd14bca9".hexValue)
    let privateKeyC = try! P256.Signing.PrivateKey(rawRepresentation: "1eb79c40023143821983dc79b4e639789ea42452e904fda719f5677a1f144208".hexValue)

    func testEncodeTx() async throws {
        // Example in Testnet

        // Admin key
        let address = addressC
        let signer = [ECDSA_P256_Signer(address: address, keyIndex: 0, privateKey: privateKeyC)]

        // User publick key
        let accountKey = Flow.AccountKey(publicKey: Flow.PublicKey(hex: privateKeyC.publicKey.rawRepresentation.hexValue),
                                         signAlgo: .ECDSA_P256,
                                         hashAlgo: .SHA2_256,
                                         weight: 1000)

        flow.configure(chainID: .testnet)

        var unsignedTx = try! await flow.buildTransaction {
            cadence {
                """
                    transaction(publicKey: String) {
                        prepare(signer: AuthAccount) {
                            let account = AuthAccount(payer: signer)
                            account.keys.add(publicKey.decodeHex())
                        }
                    }
                """
            }

            proposer {
                Flow.TransactionProposalKey(address: addressC, keyIndex: 0)
            }

            authorizers {
                address
            }

            arguments {
                [.string(accountKey.encoded!.hexValue)]
            }

            // optional
            gasLimit {
                1000
            }
        }

        let signedTx = try! await unsignedTx.sign(signers: signer)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try! encoder.encode(signedTx)
        let object = try! JSONSerialization.jsonObject(with: jsonData)
        let data = try! JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        print(String(data: data, encoding: .utf8)!)
    }
}
