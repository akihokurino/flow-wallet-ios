//
//  FlowAddress
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
    /// The data structure of address in Flow blockchain
    /// At the most time, it represents account address
    public struct Address: FlowEntity, Equatable, Hashable, Codable {
        public var data: Data

        public init(hex: String) {
            data = hex.hexValue.data
        }

        public init(data: Data) {
            self.data = data
        }

        internal init(bytes: [UInt8]) {
            data = bytes.data
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(hex.addHexPrefix())
        }
    }
}

extension Flow.Address: CustomStringConvertible {
    public var description: String { data.hexValue }
}
