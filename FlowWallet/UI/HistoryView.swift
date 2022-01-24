import ComposableArchitecture
import SwiftUI

struct HistoryView: View {
    let store: Store<HistoryVM.State, HistoryVM.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("履歴", displayMode: .inline)
            .onAppear {
                viewStore.send(.startInitialize)
            }
            .overlay(
                Group {
                    if viewStore.state.shouldShowHUD {
                        HUD(isLoading: viewStore.binding(
                            get: \.shouldShowHUD,
                            send: HistoryVM.Action.shouldShowHUD
                        ))
                    }
                }, alignment: .center
            )
            .pullToRefresh(isShowing: viewStore.binding(
                get: \.shouldPullToRefresh,
                send: HistoryVM.Action.shouldPullToRefresh
            )) {
                viewStore.send(.startRefresh)
            }
        }
    }
}
