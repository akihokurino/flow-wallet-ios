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
            let defaultAddress = Flow.Address(hex: Env["WALLET_ADDRESS"]!)
            let defaultPrivateKey = try! P256.Signing.PrivateKey(rawRepresentation: Env["WALLET_SECRET"]!.hexValue)

            let getBlock = Future<Flow.Block, AppError> { promise in
                Task.detached {
                    do {
                        let block = try await flow.accessAPI.getLatestBlock(sealed: true)
                        promise(.success(block))
                    } catch {
                        promise(.failure(AppError.plain(error.localizedDescription)))
                    }
                }
            }

            let getDefaultAccount = Future<Flow.Account, AppError> { promise in
                Task.detached {
                    do {
                        let account = try await flow.accessAPI.getAccountAtLatestBlock(address: defaultAddress)
                        promise(.success(account))
                    } catch {
                        promise(.failure(AppError.plain(error.localizedDescription)))
                    }
                }
            }

            return getBlock.flatMap { block in
                getDefaultAccount.map { ($0, block) }
            }
            .flatMap { account, block in
                Future<Flow.Address, AppError> { promise in
                    Task.detached {
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

                        do {
                            var unsignedTx = try await flow.buildTransaction {
                                cadence {
                                    code
                                }
                                arguments {
                                    [.array(pubKeyArg)]
                                }
                                proposer {
                                    Flow.TransactionProposalKey(
                                        address: defaultAddress,
                                        keyIndex: defaultAccountKey.index,
                                        sequenceNumber: defaultAccountKey.sequenceNumber
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
                            let signedTx = try await unsignedTx.signEnvelope(signers: [signer])
                            _ = try await flow.sendTransaction(signedTransaction: signedTx)
                            
                            promise(.success(defaultAddress))
                        } catch {
                            promise(.failure(AppError.plain(error.localizedDescription)))
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
            return .none
        case .endInitialize(.failure(_)):
            return .none
        case .homeView(let action):
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
}

extension RootVM {
    enum Action: Equatable {
        case startInitialize
        case endInitialize(Result<Flow.Address, AppError>)

        case homeView(HomeVM.Action)
    }

    struct State: Equatable {
        var homeView: HomeVM.State?
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
