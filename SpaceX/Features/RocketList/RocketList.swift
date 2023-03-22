import ComposableArchitecture
import SwiftUI

struct RocketList: Reducer {
    struct State: Equatable {
        var rocketDetails: IdentifiedArrayOf<RocketDetail.State> = []
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

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .downloadList:
                return .task {
                    let result = await TaskResult { try await apiClient.fetchRocketList() }
                    return .downloadListResult(result)
                }

            case let .downloadListResult(.success(rockets)):
                let rocketStates = rockets.map { RocketDetail.State(rocket: $0, launch: RocketLaunch.State()) }
                state.rocketDetails = IdentifiedArray(uniqueElements: rocketStates)
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

            case .detailAction:
                return .none
            }
        }
        .forEach(\.rocketDetails, action: /Action.detailAction(id:action:)) {
            RocketDetail()
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
                    ForEach(viewStore.rocketDetails, id: \.id) { rocketDetail in
                        Button {
                            viewStore.send(.showDetail(rocketDetail.id))
                        } label: {
                            RocketListCellView(rocket: rocketDetail.rocket)
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
                        $0.rocketDetails[id: rocketId]
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
        .contentShape(Rectangle())
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
