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

import Foundation

public protocol FlowAccessProtocol {
    func ping() async throws -> Bool

    func getLatestBlockHeader() async throws -> Flow.BlockHeader

    func getBlockHeaderById(id: Flow.ID) async throws -> Flow.BlockHeader

    func getBlockHeaderByHeight(height: UInt64) async throws -> Flow.BlockHeader

    func getLatestBlock(sealed: Bool) async throws -> Flow.Block

    func getBlockById(id: Flow.ID) async throws -> Flow.Block

    func getBlockByHeight(height: UInt64) async throws -> Flow.Block

    func getCollectionById(id: Flow.ID) async throws -> Flow.Collection

    func sendTransaction(transaction: Flow.Transaction) async throws -> Flow.ID

    func getTransactionById(id: Flow.ID) async throws -> Flow.Transaction

    func getTransactionResultById(id: Flow.ID) async throws -> Flow.TransactionResult

    func getAccountAtLatestBlock(address: Flow.Address) async throws -> Flow.Account

    func getAccountByBlockHeight(address: Flow.Address, height: UInt64) async throws -> Flow.Account

    func executeScriptAtLatestBlock(script: Flow.Script, arguments: [Flow.Argument]) async throws -> Flow.ScriptResponse

    func executeScriptAtLatestBlock(script: Flow.Script, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse

    func executeScriptAtBlockId(script: Flow.Script, blockId: Flow.ID, arguments: [Flow.Argument]) async throws -> Flow.ScriptResponse

    func executeScriptAtBlockId(script: Flow.Script, blockId: Flow.ID, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse

    func executeScriptAtBlockHeight(script: Flow.Script, height: UInt64, arguments: [Flow.Argument]) async throws -> Flow.ScriptResponse

    func executeScriptAtBlockHeight(script: Flow.Script, height: UInt64, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse

    func getEventsForHeightRange(type: String, range: ClosedRange<UInt64>) async throws -> [Flow.Event.Result]

    func getEventsForBlockIds(type: String, ids: Set<Flow.ID>) async throws -> [Flow.Event.Result]

//    func getNetworkParameters() async throws -> Flow.ChainID

//    func getLatestProtocolStateSnapshot() async throws -> Flow.Snapshot
}

extension FlowAccessProtocol {
    public func executeScriptAtLatestBlock(script: Flow.Script, arguments: [Flow.Argument] = []) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtLatestBlock(script: script, arguments: arguments)
    }

    public func executeScriptAtLatestBlock(script: Flow.Script, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtLatestBlock(script: script, arguments: arguments.map { $0.toArgument() })
    }

    public func executeScriptAtBlockId(script: Flow.Script, blockId: Flow.ID, arguments: [Flow.Argument] = []) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtBlockId(script: script, blockId: blockId, arguments: arguments)
    }

    public func executeScriptAtBlockId(script: Flow.Script, blockId: Flow.ID, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtBlockId(script: script, blockId: blockId, arguments: arguments.map { $0.toArgument() })
    }

    public func executeScriptAtBlockHeight(script: Flow.Script, height: UInt64, arguments: [Flow.Argument] = []) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtBlockHeight(script: script, height: height, arguments: arguments)
    }

    public func executeScriptAtBlockHeight(script: Flow.Script, height: UInt64, arguments: [Flow.Cadence.FValue]) async throws -> Flow.ScriptResponse {
        return try await executeScriptAtBlockHeight(script: script, height: height, arguments: arguments.map { $0.toArgument() })
    }
}
