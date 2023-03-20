import ComposableArchitecture
import SwiftUI

@main
struct SpaceXApp: App {
    var body: some Scene {
        WindowGroup {
            RocketListView(
                store: Store(
                    initialState: RocketList.State(),
                    reducer: RocketList()
                )
            )
        }
    }
}
