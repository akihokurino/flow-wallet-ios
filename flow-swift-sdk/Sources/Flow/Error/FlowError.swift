//
//  FlowError
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
    /// List of common error in Flow Swift SDK
    public enum FError: String, Error {
        case generic
        case urlEmpty
        case urlInvaild
        case declined
        case encodeFailure
        case decodeFailure
        case unauthenticated
        case emptyProposer
        case invaildPlayload
        case invaildEnvelope
        case invaildAccountInfo
        case missingSigner
        case preparingTransactionFailed
        case timeout
    }
}

extension Flow.FError: LocalizedError {
    public var errorDescription: String? {
        return rawValue
    }
}
