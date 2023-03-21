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
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationStack {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.headline)
                        Text(viewStore.description)

                        Text("Parameters")
                            .font(.headline)
                        HStack(spacing: 16) {
                            parameterBox(title: "height", value: viewStore.height, unit: "m")
                            parameterBox(title: "diameter", value: viewStore.diameter, unit: "m")
                            parameterBox(title: "mass", value: viewStore.mass, unit: "t")
                        }

                        stageBox(title: "First Stage", stage: viewStore.stageOne)
                        stageBox(title: "Second Stage", stage: viewStore.stageTwo)

                        Text("Photos")
                            .font(.headline)

                        ForEach(viewStore.photos, id: \.self) { urlString in
                            photo(url: URL(string: urlString))
                        }
                    }
                    .padding()
                }
                .navigationTitle(viewStore.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    NavigationLink {
                        RocketLaunchView(
                            store: Store(
                                initialState: RocketLaunch.State(),
                                reducer: RocketLaunch()
                            )
                        )
                    } label: {
                        Text("Launch")
                    }
                }
            }
        })
    }

    func parameterBox(title: String, value: Double, unit: String) -> some View {
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

    func stageBox(title: String, stage: Rocket.Stage) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            HStack {
                Image("Reusable")
                Text(stage.reusable ? "reusable" : "not reusable")
                Spacer()
            }
            HStack {
                Image("Engine")
                Text(stage.engines == 1 ? "1 engine" : "\(stage.engines) engines")
            }
            HStack {
                Image("Fuel")
                Text("\(Int(stage.fuelAmountTons)) tons of fuel")
            }
            if let burnTime = stage.burnTimeSec {
                HStack {
                    Image("Burn")
                    Text("\(Int(burnTime)) seconds burn time")
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
}

struct RocketDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RocketDetailView(
            store: Store(
                initialState: Rocket.mocks[1],
                reducer: RocketDetail()
            )
        )
    }
}
