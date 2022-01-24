import ComposableArchitecture
import SwiftUI
import SwiftUIRefresh

struct HomeView: View {
    let store: Store<HomeVM.State, HomeVM.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                VStack(alignment: .leading) {
                    Button(action: {
                        print(viewStore.state.address)
                    }) {
                        Text("アドレス: \n\(viewStore.state.address.hex)")
                            .lineLimit(nil)
                    }
                    Spacer().frame(height: 20)
                    Text("\(viewStore.state.balance) Flow")
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 100,
                            maxHeight: 100,
                            alignment: .center
                        )
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(5.0)
                        .font(.title2)
                }
                .padding()
                .background(Color.black)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("ホーム", displayMode: .inline)
            .onAppear {
                viewStore.send(.startInitialize)
            }
            .overlay(
                Group {
                    if viewStore.state.shouldShowHUD {
                        HUD(isLoading: viewStore.binding(
                            get: \.shouldShowHUD,
                            send: HomeVM.Action.shouldShowHUD
                        ))
                    }
                }, alignment: .center
            )
            .pullToRefresh(isShowing: viewStore.binding(
                get: \.shouldPullToRefresh,
                send: HomeVM.Action.shouldPullToRefresh
            )) {
                viewStore.send(.startRefresh)
            }
        }
    }
}
