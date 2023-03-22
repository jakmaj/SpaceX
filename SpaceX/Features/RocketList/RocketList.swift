import ComposableArchitecture
import SwiftUI

struct RocketList: Reducer {
    struct State: Equatable {
        var rockets: IdentifiedArrayOf<Rocket> = []
        var isActivityIndicatorVisible = true
    }

    enum Action: Equatable {
        case downloadList
        case downloadListResult(TaskResult<[Rocket]>)
        case rowAction(id: Rocket.ID, action: RocketDetail.Action)
    }

    @Dependency(\.apiClient) var apiClient
    private enum DownloadListId {}

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
        }
    }
}

struct RocketListView: View {
    let store: StoreOf<RocketList>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationStack {
                ZStack {
                    List {
                        ForEachStore(
                            store.scope(state: \.rockets, action: RocketList.Action.rowAction(id:action:))
                        ) { rowStore in
                            WithViewStore(rowStore, observe: { $0 }, content: { rowViewStore in
                                NavigationLink {
                                    RocketDetailView(store: rowStore)
                                } label: {
                                    RocketListCellView(rocket: rowViewStore.state)
                                }
                            })
                        }
                    }
                    if viewStore.isActivityIndicatorVisible {
                        ProgressView()
                    }
                }
                .navigationTitle("Rockets")
                .task { await viewStore.send(.downloadList).finish() }
            }
        })
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
