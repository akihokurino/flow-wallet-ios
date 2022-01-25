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
            let defaultAddress = Flow.Address(hex: "0xf8d6e0586b0a20c7")
            let defaultPrivateKey = try! P256.Signing.PrivateKey(rawRepresentation: "94e798c159bcdfc1445087fb587ef589574c3951d7e3e0e0e0dd20c6061bf67c".hexValue)

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
                        let defaultAccountKey = account.keys[0]

                        let newPrivateKey = P256.Signing.PrivateKey()
                        let newAccountKey = Flow.AccountKey(
                            publicKey: Flow.PublicKey(data: newPrivateKey.publicKey.rawRepresentation),
                            signAlgo: .ECDSA_P256,
                            hashAlgo: .SHA3_256,
                            weight: 1000
                        )

                        let pubKeyArg = [newAccountKey]
                            .compactMap { $0.encoded?.hexValue }
                            .compactMap { Flow.Argument(value: .string($0)) }

                        let code = """
                        transaction(publicKeys: [String]) {
                            prepare(signer: AuthAccount) {
                                let acct = AuthAccount(payer: signer)
                                for key in publicKeys {
                                    acct.addPublicKey(key.decodeHex())
                                }
                            }
                        }
                        """

                        var unsignedTx = try! flow.buildTransaction {
                            cadence {
                                code
                            }
                            arguments {
                                [.array(pubKeyArg)]
                            }
                            proposer {
                                Flow.TransactionProposalKey(
                                    address: defaultAddress,
                                    keyIndex: defaultAccountKey.id,
                                    sequenceNumber: BigInt(defaultAccountKey.sequenceNumber)
                                )
                            }
                            payer {
                                defaultAddress
                            }
                            authorizers {
                                defaultAddress
                            }
                            gasLimit {
                                9999
                            }
                            refBlock {
                                block.id
                            }
                        }

                        let signer = ECDSA_P256_Signer(address: defaultAddress, keyIndex: 0, privateKey: defaultPrivateKey)
                        let signedTx = try! unsignedTx.signEnvelope(signers: [signer])
                        try! flow.sendTransaction(signedTransaction: signedTx).whenComplete { result in
                            switch result {
                            case .success(let id):
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
