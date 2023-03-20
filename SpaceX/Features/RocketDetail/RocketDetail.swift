import ComposableArchitecture
import SwiftUI

struct RocketDetail: Reducer {

    typealias State = Rocket

    enum Action: Equatable {
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    }
}

struct RocketDetailView: View {
    let store: StoreOf<RocketDetail>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ScrollView(.vertical) {
                }
                .navigationTitle(viewStore.name)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct RocketDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RocketDetailView(
            store: Store(
                initialState: Rocket.mocks[0],
                reducer: RocketDetail()
            )
        )
    }
}
