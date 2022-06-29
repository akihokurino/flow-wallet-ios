//
//  FlowCollection
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

public extension Flow {
    /// A batch of transactions that have been included in the same block
    struct Collection: Codable {
        public let id: ID
        public let transactionIds: [ID]

        public init(id: Flow.ID, transactionIds: [Flow.ID]) {
            self.id = id
            self.transactionIds = transactionIds
        }
    }

    ///
    struct CollectionGuarantee: Codable {
        public let collectionId: ID
        public let signatures: [Signature]

        enum CodingKeys: CodingKey {
            case collectionId
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            collectionId = try container.decode(Flow.ID.self, forKey: .collectionId)

            // HTTP return signature as string, mismatch with gRPC one
            signatures = []
        }

        public init(id: Flow.ID, signatures: [Flow.Signature]) {
            collectionId = id
            self.signatures = signatures
        }
    }
}
