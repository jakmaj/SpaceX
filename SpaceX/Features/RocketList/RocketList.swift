import ComposableArchitecture
import SwiftUI

struct RocketList: Reducer {
    struct State: Equatable {
        var rockets: IdentifiedArrayOf<Rocket> = []
        var isActivityIndicatorVisible = true

        var route: Route?
    }

    enum Route: Equatable {
        case detail(Rocket.ID)
    }

    enum Action: Equatable {
        case downloadList
        case downloadListResult(TaskResult<[Rocket]>)

        case showDetail(Rocket.ID)
        case showNavigation(Bool)

        case detailAction(id: Rocket.ID, action: RocketDetail.Action)
    }

    @Dependency(\.apiClient) var apiClient

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .downloadList:
            return .task {
                let result = await TaskResult { try await apiClient.fetchRocketList() }
                return .downloadListResult(result)
            }

        case let .downloadListResult(.success(rockets)):
            state.rockets = IdentifiedArray(uniqueElements: rockets)
            state.isActivityIndicatorVisible = false
            return .none

        case let .downloadListResult(.failure(error)):
            // TODO: handle error
            print("RocketList - downloadListResult - error: \(error)")
            state.isActivityIndicatorVisible = false
            return .none

        case let .showDetail(rocketId):
            state.route = .detail(rocketId)
            return .none

        case .showNavigation(false):
            state.route = nil
            return .none

        case .showNavigation(true):
            return .none
        }
    }
}

struct RocketListView: View {
    let store: StoreOf<RocketList>
    @ObservedObject var viewStore: ViewStoreOf<RocketList>

    init(store: StoreOf<RocketList>) {
        self.store = store
        viewStore = ViewStore(store, observe: { $0 })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(viewStore.rockets, id: \.id) { rocket in
                        Button {
                            viewStore.send(.showDetail(rocket.id))
                        } label: {
                            RocketListCellView(rocket: rocket)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if viewStore.isActivityIndicatorVisible {
                    ProgressView()
                }
            }
            .navigationTitle("Rockets")
            .task { await viewStore.send(.downloadList).finish() }
            .universalNavigationDestination(
                isPresented: viewStore.binding(
                    get: { $0.route != nil },
                    send: RocketList.Action.showNavigation
                ),
                destination: { destination }
            )
        }
    }

    @ViewBuilder
    var destination: some View {
        switch viewStore.state.route {
        case let .detail(rocketId):
            IfLetStore(
                store.scope(
                    state: {
                        $0.rockets[id: rocketId]
                    },
                    action: {
                        .detailAction(id: rocketId, action: $0)
                    }
                ),
                then: RocketDetailView.init(store:)
            )

        case .none:
            EmptyView()
        }
    }
}

struct RocketListCellView: View {
    let rocket: Rocket

    var body: some View {
        HStack {
            Image("Rocket")
            VStack(alignment: .leading) {
                Text(rocket.name)
                    .font(.headline)
                Text("First flight: \(rocket.firstFlight.dateString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct RocketListView_Previews: PreviewProvider {
    static var previews: some View {
        RocketListView(
            store: Store(
                initialState: RocketList.State(),
                reducer: RocketList()
            )
        )
    }
}
