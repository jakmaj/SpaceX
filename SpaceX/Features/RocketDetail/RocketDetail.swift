import ComposableArchitecture
import SwiftUI

struct RocketDetail: Reducer {
    struct State: Identifiable, Equatable {
        var rocket: Rocket
        var launch: RocketLaunch.State

        var route: Route?

        var id: Rocket.ID { rocket.id }
    }

    enum Route: Equatable {
        case launch
    }

    enum Action: Equatable {
        case showLaunch
        case showNavigation(Bool)

        case launchAction(RocketLaunch.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .showLaunch:
                state.route = .launch
                return .none

            case .showNavigation(false):
                state.route = nil
                return .none

            case .showNavigation(true):
                return .none

            case .launchAction:
                return .none
            }
        }

        Scope(state: \.launch, action: /Action.launchAction) {
            RocketLaunch()
        }
    }
}

struct RocketDetailView: View {
    let store: StoreOf<RocketDetail>
    @ObservedObject var viewStore: ViewStoreOf<RocketDetail>

    init(store: StoreOf<RocketDetail>) {
        self.store = store
        viewStore = ViewStore(store, observe: { $0 })
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                Text("rocket_detail.overview")
                    .font(.headline)
                Text(viewStore.rocket.description)

                Text("rocket_detail.parameters")
                    .font(.headline)
                HStack(spacing: 16) {
                    parameterBox(title: "rocket_detail.height", value: viewStore.rocket.height, unit: "m")
                    parameterBox(title: "rocket_detail.diameter", value: viewStore.rocket.diameter, unit: "m")
                    parameterBox(title: "rocket_detail.mass", value: viewStore.rocket.mass, unit: "t")
                }

                stageBox(title: "rocket_detail.first_stage", stage: viewStore.rocket.stageOne)
                stageBox(title: "rocket_detail.second_stage", stage: viewStore.rocket.stageTwo)

                Text("rocket_detail.photos")
                    .font(.headline)

                ForEach(viewStore.rocket.photos, id: \.self) { urlString in
                    photo(url: URL(string: urlString))
                }
            }
            .padding()
        }
        .navigationTitle(viewStore.rocket.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                viewStore.send(.showLaunch)
            } label: {
                Text("rocket_detail.launch")
            }
        }
        .universalNavigationDestination(
            isPresented: viewStore.binding(
                get: { $0.route != nil },
                send: RocketDetail.Action.showNavigation
            ),
            destination: { destination }
        )
    }

    func parameterBox(title: LocalizedStringKey, value: Double, unit: String) -> some View {
        VStack {
            Text("\(Int(value))\(unit)")
                .lineLimit(1)
                .font(.title)
                .bold()
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .background(RoundedRectangle(cornerRadius: 16).foregroundColor(Color("ParameterBackground")))
    }

    func stageBox(title: LocalizedStringKey, stage: Rocket.Stage) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            HStack {
                Image("Reusable")
                Text(stage.reusable ? "rocket_detail.reusable" : "rocket_detail.not_reusable")
                Spacer()
            }
            HStack {
                Image("Engine")
                Text("rocket_detail.engines \(stage.engines)")
            }
            HStack {
                Image("Fuel")
                Text("rocket_detail.tons_of_fuel \(Int(stage.fuelAmountTons))")
            }
            if let burnTime = stage.burnTimeSec {
                HStack {
                    Image("Burn")
                    Text("rocket_detail.seconds_burn_time \(Int(burnTime))")
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).foregroundColor(Color("StageBackground")))
    }

    func photo(url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(16)
        } placeholder: {
            ProgressView()
        }
    }

    @ViewBuilder
    var destination: some View {
        switch viewStore.state.route {
        case .launch:
            RocketLaunchView(store: store.scope(
                state: \.launch,
                action: RocketDetail.Action.launchAction
            ))

        case .none:
            EmptyView()
        }
    }
}

struct RocketDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RocketDetailView(
            store: Store(
                initialState: RocketDetail.State(
                    rocket: Rocket.mocks[1],
                    launch: RocketLaunch.State()
                ),
                reducer: RocketDetail()
            )
        )
    }
}
