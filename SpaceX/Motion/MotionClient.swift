import ComposableArchitecture
import CoreMotion
import Foundation
import XCTestDynamicOverlay

struct MotionClient {
    var wasMovedUpPicked: @Sendable () async -> Void
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
            motionManager.startAccelerometerUpdates()

            var resultFound = false
            while !Task.isCancelled && !resultFound {
                try? await Task.sleep(for: .milliseconds(50))
                if let accelerationZ = motionManager.accelerometerData?.acceleration.z, accelerationZ < -1.5 {
                    resultFound = true
                }
            }

            motionManager.stopAccelerometerUpdates()
        }
    )

    static let previewValue = Self(
        wasMovedUpPicked: {
            try? await Task.sleep(for: .seconds(2))
        }
    )

    static let testValue = Self(
        wasMovedUpPicked: unimplemented("\(Self.self).wasPicked")
    )
}
