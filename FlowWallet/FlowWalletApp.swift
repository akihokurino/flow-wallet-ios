import ComposableArchitecture
import Flow
import SwiftUI

@main
struct FlowWalletApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    let store: Store<RootVM.State, RootVM.Action> = Store(
        initialState: RootVM.State(),
        reducer: RootVM.reducer,
        environment: RootVM.Environment(
            mainQueue: .main,
            backgroundQueue: .init(DispatchQueue.global(qos: .background))
        )
    )

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let transport = Flow.Transport.HTTP(URL(string: "http://localhost:8888")!)
        let chainID = Flow.ChainID.custom(name: "LocalHost", transport: transport)
        flow.configure(chainID: chainID)
        
        return true
    }
}
