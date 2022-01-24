import BigInt
import Combine
import ComposableArchitecture
import CryptoKit
import Flow
import Foundation

enum RootVM {
    static let reducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startInitialize:
            let defaultAddress = Flow.Address(hex: "f8d6e0586b0a20c7")
            let defaultPrivateKey = try! P256.Signing.PrivateKey(rawRepresentation: "050ec39cef917b74e01457dd2b37f3c23113355dd483884697cabb0af2d4230d".toBytes()!)

            let getBlock = Future<Flow.Block, AppError> { promise in
                DispatchQueue.global(qos: .background).async {
                    flow.accessAPI.getLatestBlock().whenComplete { result in
                        switch result {
                        case .success(let block):
                            promise(.success(block))
                        case .failure(let error):
                            promise(.failure(AppError.plain(error.localizedDescription)))
                        }
                    }
                }
            }

            let getDefaultAccount = Future<Flow.Account, AppError> { promise in
                DispatchQueue.global(qos: .background).async {
                    flow.accessAPI.getAccountAtLatestBlock(address: defaultAddress).whenComplete { result in
                        switch result {
                        case .success(let account):
                            promise(.success(account!))
                        case .failure(let error):
                            promise(.failure(AppError.plain(error.localizedDescription)))
                        }
                    }
                }
            }

            return getBlock.flatMap { block in
                getDefaultAccount.map { ($0, block) }
            }
            .flatMap { account, block in
                Future<Flow.Address, AppError> { promise in
                    DispatchQueue.global(qos: .background).async {
                        print("---------------------")
                        print(account.address)
                        print(block.id.hex)

                        let defaultAccountKey = account.keys[0]
                        let defaultSigner = ECDSA_P256_Signer(address: defaultAddress, keyIndex: 0, privateKey: defaultPrivateKey)

                        let nextPrivateKey = P256.Signing.PrivateKey()

                        let nextAccountKey = Flow.AccountKey(
                            publicKey: Flow.PublicKey(data: nextPrivateKey.publicKey.rawRepresentation),
                            signAlgo: .ECDSA_P256,
                            hashAlgo: .SHA3_256,
                            weight: 1000,
                            sequenceNumber: 0
                        )

                        let accountKeys = [nextAccountKey]
                        let contracts: [String: String] = [:]
                        let pubKeyArg = accountKeys.compactMap { $0.encoded?.hexValue }.compactMap { Flow.Argument(value: .string($0)) }
                        let contractArg = contracts.compactMap { name, cadence in
                            Flow.Argument.Dictionary(key: .init(value: .string(name)),
                                                     value: .init(value: .string(Flow.Script(text: cadence).hex)))
                        }

                        var unsignedTx = try! flow.buildTransaction {
                            cadence {
                                """
                                    transaction(publicKeys: [String], contracts: {String: String}) {
                                        prepare(signer: AuthAccount) {
                                            let acct = AuthAccount(payer: signer)

                                            for key in publicKeys {
                                                acct.addPublicKey(key.decodeHex())
                                            }

                                            for contract in contracts.keys {
                                                acct.contracts.add(name: contract, code: contracts[contract]!.decodeHex())
                                            }
                                        }
                                    }
                                """
                            }
                            proposer {
                                Flow.TransactionProposalKey(address: defaultAddress, keyIndex: defaultAccountKey.id, sequenceNumber: BigInt(defaultAccountKey.sequenceNumber))
                            }
                            payer {
                                defaultAddress
                            }
                            arguments {
                                [.array(pubKeyArg), .dictionary(contractArg)]
                            }
                            gasLimit {
                                9999
                            }
                            refBlock {
                                block.id.hex
                            }
                        }

                        let signedTx = try! unsignedTx.signEnvelope(signers: [defaultSigner])

                        try! flow.sendTransaction(signedTransaction: signedTx).whenComplete { result in
                            switch result {
                            case .success(let account):
                                promise(.success(Flow.Address(hex: "f8d6e0586b0a20c7")))
                            case .failure(let error):
                                promise(.failure(AppError.plain(error.localizedDescription)))
                            }
                        }
                    }
                }
            }
            .subscribe(on: environment.backgroundQueue)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(RootVM.Action.endInitialize)
        case .endInitialize(.success(let address)):
            state.homeView = HomeVM.State(address: address)
            state.historyView = HistoryVM.State(address: address)
            return .none
        case .endInitialize(.failure(_)):
            return .none
        case .homeView(let action):
            return .none
        case .historyView(let action):
            return .none
        }
    }
    .connect(
        HomeVM.reducer,
        state: \.homeView,
        action: /RootVM.Action.homeView,
        environment: { _environment in
            HomeVM.Environment(
                mainQueue: _environment.mainQueue,
                backgroundQueue: _environment.backgroundQueue
            )
        }
    )
    .connect(
        HistoryVM.reducer,
        state: \.historyView,
        action: /RootVM.Action.historyView,
        environment: { _environment in
            HistoryVM.Environment(
                mainQueue: _environment.mainQueue,
                backgroundQueue: _environment.backgroundQueue
            )
        }
    )
}

extension RootVM {
    enum Action: Equatable {
        case startInitialize
        case endInitialize(Result<Flow.Address, AppError>)

        case homeView(HomeVM.Action)
        case historyView(HistoryVM.Action)
    }

    struct State: Equatable {
        var homeView: HomeVM.State?
        var historyView: HistoryVM.State?
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
