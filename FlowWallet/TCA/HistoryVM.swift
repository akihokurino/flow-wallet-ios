import Combine
import ComposableArchitecture
import Foundation
import Flow

enum HistoryVM {
    static let reducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
            case .startInitialize:
                guard !state.isInitialized else {
                    return .none
                }

                state.shouldShowHUD = true

                let address = state.address
                let task = Future<String, AppError> { promise in
                    DispatchQueue.global(qos: .background).async {
                        promise(.success(""))
                    }
                }

                return task
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(HistoryVM.Action.endInitialize)
            case .endInitialize(.success):
                state.isInitialized = true
                state.shouldShowHUD = false
                return .none
            case .endInitialize(.failure(_)):
                state.isInitialized = true
                state.shouldShowHUD = false
                return .none
            case .startRefresh:
                state.shouldPullToRefresh = true

                let address = state.address
                let task = Future<String, AppError> { promise in
                    DispatchQueue.global(qos: .background).async {
                        promise(.success(""))
                    }
                }

                return task
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(HistoryVM.Action.endRefresh)
            case .endRefresh(.success):
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

extension HistoryVM {
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
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
