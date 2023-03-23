import Common
import ComposableArchitecture
import Foundation
import Model
import XCTestDynamicOverlay

public struct ApiClient {
    public var fetchRocketList: @Sendable () async throws -> [Rocket]
}

public extension DependencyValues {
    var apiClient: ApiClient {
        get { self[ApiClient.self] }
        set { self[ApiClient.self] = newValue }
    }
}

extension ApiClient: DependencyKey {

    public init(baseURL: String) {
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

    public static let liveValue = Self(baseURL: "https://api.spacexdata.com/v3")

    public static let previewValue = Self(
        fetchRocketList: { Rocket.mocks }
    )

    public static let testValue = Self(
        fetchRocketList: unimplemented("\(Self.self).fetchRocketList")
    )
}
