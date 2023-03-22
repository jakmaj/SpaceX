import ComposableArchitecture
import CoreMotion
import Foundation
import XCTestDynamicOverlay

struct MotionClient {
    var wasMovedUp: @Sendable () async -> Void
}

extension DependencyValues {
    var motionClient: MotionClient {
        get { self[MotionClient.self] }
        set { self[MotionClient.self] = newValue }
    }
}

extension MotionClient: DependencyKey {

    init() {
        wasMovedUp = {
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
    }

    static let liveValue = Self()

    static let previewValue = Self(
        wasMovedUp: { try? await Task.sleep(for: .seconds(2)) }
    )

    static let testValue = Self(
        wasMovedUp: unimplemented("\(Self.self).wasPicked")
    )
}
