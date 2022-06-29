//
import Combine
//  FlowSigner
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
import Foundation

/// A protocol for signer to use private key to sign the data
public protocol FlowSigner {
    /// Address in the flow blockchain
    var address: Flow.Address { get set }

    /// The index of the public key
    var hashAlgo: Flow.HashAlgorithm { get set }

    /// The index of the public key
    var signatureAlgo: Flow.SignatureAlgorithm { get set }

    // The index of the public key
    var keyIndex: Int { get set }

    /// Sign the data with account private key
    /// - parameters:
    ///     - signableData: The data to be signed
    /// - returns: The signed data
    func sign(signableData: Data) async throws -> Data

    // TODO: - Add async sign method
    //    func signAsync(signableData: Data) -> Future<Data, Error>
}

// extension FlowSigner {
//    func signAsync(signableData: Data) -> Future<Data, Error> {
//        return Future { $0(.failure(Flow.FError.generic)) }
//    }
// }
