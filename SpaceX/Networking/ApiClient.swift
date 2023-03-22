import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

struct ApiClient {
    var fetchRocketList: @Sendable () async throws -> [Rocket]
}

extension DependencyValues {
    var apiClient: ApiClient {
        get { self[ApiClient.self] }
        set { self[ApiClient.self] = newValue }
    }
}

extension ApiClient: DependencyKey {

    init(baseURL: String) {
        fetchRocketList = {
            guard let url = URL(string: "\(baseURL)/rockets") else {
                throw "Invalid endpoint URL"
            }
            let (data, _) = try await URLSession.shared.data(from: url)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(formatter)
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            return try decoder.decode([Rocket].self, from: data)
        }
    }

    static let liveValue = Self(baseURL: "https://api.spacexdata.com/v3")

    static let previewValue = Self(
        fetchRocketList: { Rocket.mocks }
    )

    static let testValue = Self(
        fetchRocketList: unimplemented("\(Self.self).fetchRocketList")
    )
}
