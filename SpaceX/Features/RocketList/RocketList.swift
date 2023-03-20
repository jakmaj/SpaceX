import ComposableArchitecture
import SwiftUI

struct RocketList: Reducer {
    struct State: Equatable {
        var rockets: IdentifiedArrayOf<Rocket> = []
        var isActivityIndicatorVisible = true
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case downloadListResult(TaskResult<IdentifiedArrayOf<Rocket>>)
        case rowAction(id: Rocket.ID, action: RocketDetail.Action)
    }

    @Dependency(\.apiClient) var apiClient
    private enum DownloadListId {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .task {
                let result = await TaskResult { try await apiClient.fetchRocketList() }
                return .downloadListResult(result)
            }
            .cancellable(id: DownloadListId.self)

        case .onDisappear:
            return .cancel(id: DownloadListId.self)

        case let .downloadListResult(.success(rockets)):
            state.rockets = rockets
            state.isActivityIndicatorVisible = false
            return .none

        case let .downloadListResult(.failure(error)):
            //TODO: handle error
            print("RocketList - downloadListResult - error: \(error)")
            state.isActivityIndicatorVisible = false
            return .none
        }
    }
}

struct RocketListView: View {
    let store: StoreOf<RocketList>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ZStack {
                    List {
                        ForEachStore(
                            store.scope(state: \.rockets, action: RocketList.Action.rowAction(id:action:))
                        ) { rowStore in
                            WithViewStore(rowStore, observe: { $0 }) { rowViewStore in
                                NavigationLink {
                                    RocketDetailView(store: rowStore)
                                } label: {
                                    RocketListCellView(rocket: rowViewStore.state)
                                }
                            }
                        }
                    }
                    if viewStore.isActivityIndicatorVisible {
                        ProgressView()
                    }
                }
                .navigationTitle("Rockets")
                .onAppear { viewStore.send(.onAppear) }
            }
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
