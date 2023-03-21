import ComposableArchitecture
import SwiftUI

struct RocketLaunch: Reducer {
    struct State: Equatable {
        var prepared = false
        var launched = false
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case rocketPrepared
        case rocketLaunched
    }

    @Dependency(\.motionClient) var motionClient
    private enum MotionWatchId {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.prepared = false
            state.launched = false
            return .run { send in
                try await motionClient.wasMovedUpPicked()
                await send(.rocketPrepared)
                await send(.rocketLaunched, animation: .easeInOut(duration: 1))
            }
            .cancellable(id: MotionWatchId.self)

        case .onDisappear:
            return .cancel(id: MotionWatchId.self)

        case .rocketPrepared:
            state.prepared = true
            return .none

        case .rocketLaunched:
            state.launched = true
            return .none
        }
    }
}

struct RocketLaunchView: View {
    let store: StoreOf<RocketLaunch>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationStack {
                VStack(spacing: 16) {
                    Image(viewStore.prepared ? "Rocket Flying" : "Rocket Idle")
                        .offset(y: viewStore.launched ? -UIScreen.main.bounds.height : 0)

                    Text(viewStore.launched ? "Launch successfull!" : "Move your phone up to launch the rocket")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                }
                .navigationTitle("Launch")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { viewStore.send(.onAppear) }
            }
        })
    }
}

struct RocketLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        RocketLaunchView(
            store: Store(
                initialState: RocketLaunch.State(),
                reducer: RocketLaunch()
            )
        )
    }
}
