import Common
import ComposableArchitecture
import Model
import Networking
import SwiftUI

struct RocketList: Reducer {
    struct State: Equatable {
        var rocketDetails: IdentifiedArrayOf<RocketDetail.State> = []
        var isActivityIndicatorVisible = true

        var route: Route?
        var alert: AlertState<AlertAction>?
    }

    enum Route: Equatable {
        case detail(Rocket.ID)
    }

    enum Action: Equatable {
        case downloadList
        case downloadListResult(TaskResult<[Rocket]>)

        case showDetail(Rocket.ID)
        case showNavigation(Bool)
        case alert(AlertAction)

        case detailAction(id: Rocket.ID, action: RocketDetail.Action)
    }

    enum AlertAction: Equatable {
        case retry
        case dismiss
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
                print("RocketList - downloadListResult - error: \(error)")
                state.alert = AlertState.showError()
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

            case .alert(.retry):
                return .send(.downloadList)

            case .alert(.dismiss):
                state.alert = nil
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
            .navigationTitle("rocket_list.title")
            .task { await viewStore.send(.downloadList).finish() }
            .alert(store.scope(state: \.alert, action: RocketList.Action.alert), dismiss: .dismiss)
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
                Text("rocket_list.first_flight \(rocket.firstFlight.dateString)")
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

extension AlertState where Action == RocketList.AlertAction {
    static func showError() -> Self {
        Self(
            title: TextState("rocket_list.error_alert.title"),
            message: TextState("rocket_list.error_alert.message"),
            buttons: [
                .default(TextState("rocket_list.error_alert.retry"), action: .send(.retry))
            ]
        )
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
