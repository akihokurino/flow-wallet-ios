import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: Store<RootVM.State, RootVM.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            TabView {
                NavigationView {
                    IfLetStore(
                        store.scope(
                            state: { $0.homeView },
                            action: RootVM.Action.homeView
                        ),
                        then: HomeView.init(store:)
                    )
                }
                .tabItem {
                    VStack {
                        Image(systemName: "wallet.pass")
                        Text("ホーム")
                    }
                }.tag(1)
            }
            .onAppear {
                viewStore.send(.startInitialize)
            }
        }
    }
}
