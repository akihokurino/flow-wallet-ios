import Combine
import ComposableArchitecture
import CryptoKit
import Flow
import Foundation

enum HomeVM {
    static let reducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startInitialize:
            guard !state.isInitialized else {
                return .none
            }

            state.shouldShowHUD = true

            let address = state.address
            let task = Future<String, AppError> { promise in
                flow.accessAPI.getAccountAtLatestBlock(address: address).whenComplete { result in
                    switch result {
                    case .success(let account):
                        promise(.success("\(account!.balance)"))
                    case .failure(let error):
                        promise(.failure(AppError.plain(error.localizedDescription)))
                    }
                }
            }

            return task
                .subscribe(on: environment.backgroundQueue)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(HomeVM.Action.endInitialize)
        case .endInitialize(.success(let balance)):
            state.balance = balance
            state.isInitialized = true
            state.shouldShowHUD = false
            return .none
        case .endInitialize(.failure(_)):
            state.shouldShowHUD = false
            return .none
        case .startRefresh:
            state.shouldPullToRefresh = true

            let address = state.address
            let task = Future<String, AppError> { promise in
                flow.accessAPI.getAccountAtLatestBlock(address: address).whenComplete { result in
                    switch result {
                    case .success(let account):
                        promise(.success("\(account!.balance)"))
                    case .failure(let error):
                        promise(.failure(AppError.plain(error.localizedDescription)))
                    }
                }
            }

            return task
                .subscribe(on: environment.backgroundQueue)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(HomeVM.Action.endRefresh)
        case .endRefresh(.success(let balance)):
            state.balance = balance
            state.shouldPullToRefresh = false
            return .none
        case .endRefresh(.failure(_)):
            state.shouldPullToRefresh = false
            return .none
        case .shouldShowHUD(let val):
            state.shouldShowHUD = val
            return .none
        case .shouldPullToRefresh(let val):
            state.shouldPullToRefresh = val
            return .none
        }
    }
}

extension HomeVM {
    enum Action: Equatable {
        case startInitialize
        case endInitialize(Result<String, AppError>)
        case startRefresh
        case endRefresh(Result<String, AppError>)
        case shouldShowHUD(Bool)
        case shouldPullToRefresh(Bool)
    }

    struct State: Equatable {
        let address: Flow.Address

        var shouldShowHUD = false
        var shouldPullToRefresh = false
        var isInitialized = false
        var balance = ""
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
