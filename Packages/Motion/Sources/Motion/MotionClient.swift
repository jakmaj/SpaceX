import ComposableArchitecture
import CoreMotion
import Foundation
import XCTestDynamicOverlay

public struct MotionClient {
    public var wasMovedUp: @Sendable () async -> Void
}

public extension DependencyValues {
    var motionClient: MotionClient {
        get { self[MotionClient.self] }
        set { self[MotionClient.self] = newValue }
    }
}

extension MotionClient: DependencyKey {

    public init() {
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

    public static let liveValue = Self()

    public static let previewValue = Self(
        wasMovedUp: { try? await Task.sleep(for: .seconds(2)) }
    )

    public static let testValue = Self(
        wasMovedUp: unimplemented("\(Self.self).wasPicked")
    )
}
