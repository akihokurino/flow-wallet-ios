//
//  FlowCollection
//
//  Copyright 2021 Zed Labs Pty Ltd
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

extension Flow {
    /// A batch of transactions that have been included in the same block
    public struct Collection {
        public let id: ID
        public let transactionIds: [ID]

        init(value: Flow_Entities_Collection) {
            id = ID(bytes: value.id.bytes)
            transactionIds = value.transactionIds.compactMap { ID(bytes: $0.bytes) }
        }
    }

    ///
    public struct CollectionGuarantee {
        public let id: ID
        public let signatures: [Signature]

        init(value: Flow_Entities_CollectionGuarantee) {
            id = ID(bytes: value.collectionID.bytes)
            signatures = value.signatures.compactMap { Signature(data: $0) }
        }
    }
}
