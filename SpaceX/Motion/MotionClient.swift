import ComposableArchitecture
import CoreMotion
import Foundation
import XCTestDynamicOverlay

struct MotionClient {
    var wasMovedUpPicked: @Sendable () async throws -> Void
}

extension DependencyValues {
    var motionClient: MotionClient {
        get { self[MotionClient.self] }
        set { self[MotionClient.self] = newValue }
    }
}

extension MotionClient: DependencyKey {
    static let liveValue = Self(
        wasMovedUpPicked: {
            let motionManager = CMMotionManager()
            motionManager.accelerometerUpdateInterval = 1/60

            await withCheckedContinuation { continuation in
                motionManager.startAccelerometerUpdates(to: .main) { data, error in
                    if let error {
                        print("RocketList - wasMovedUpPicked - error: \(error)")
                        return
                    }

                    if let accelerationZ = data?.acceleration.z, accelerationZ < -1.5 {
                        continuation.resume()
                    }
                }
            }

            motionManager.stopAccelerometerUpdates()
        }
    )

    static let previewValue = Self(
        wasMovedUpPicked: {
            try await Task.sleep(for: .seconds(2))
        }
    )

    static let testValue = Self(
        wasMovedUpPicked: unimplemented("\(Self.self).wasPicked")
    )
}
