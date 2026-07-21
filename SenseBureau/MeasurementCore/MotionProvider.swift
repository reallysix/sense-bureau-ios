import CoreMotion
import Foundation

typealias VibrationHandler = @MainActor @Sendable (Result<AccelerationVector, any Error>) -> Void
typealias LevelHandler = @MainActor @Sendable (Result<LevelAttitude, any Error>) -> Void

@MainActor
protocol VibrationProviding: AnyObject {
    var isAvailable: Bool { get }
    var isDemo: Bool { get }
    func start(handler: @escaping VibrationHandler)
    func stop()
}

@MainActor
protocol LevelProviding: AnyObject {
    var isAvailable: Bool { get }
    var isDemo: Bool { get }
    func start(handler: @escaping LevelHandler)
    func stop()
}

@MainActor
final class CoreMotionVibrationProvider: VibrationProviding {
    private let manager = CMMotionManager()

    var isAvailable: Bool { manager.isDeviceMotionAvailable }
    let isDemo = false

    func start(handler: @escaping VibrationHandler) {
        guard isAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 50.0
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            Task { @MainActor in
                if let error {
                    handler(.failure(error))
                    return
                }
                guard let acceleration = motion?.userAcceleration else { return }
                handler(.success(AccelerationVector(
                    x: acceleration.x,
                    y: acceleration.y,
                    z: acceleration.z
                )))
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

@MainActor
final class CoreMotionLevelProvider: LevelProviding {
    private let manager = CMMotionManager()

    var isAvailable: Bool { manager.isDeviceMotionAvailable }
    let isDemo = false

    func start(handler: @escaping LevelHandler) {
        guard isAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            Task { @MainActor in
                if let error {
                    handler(.failure(error))
                    return
                }
                guard let attitude = motion?.attitude else { return }
                handler(.success(LevelAttitude(
                    xDegrees: attitude.roll * 180 / .pi,
                    yDegrees: attitude.pitch * 180 / .pi
                )))
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

@MainActor
final class DemoVibrationProvider: VibrationProviding {
    private var timer: Timer?
    private var phase = 0.0

    let isAvailable = true
    let isDemo = true

    func start(handler: @escaping VibrationHandler) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                phase += 0.17
                let pulse = pow(max(0, sin(phase * 0.21)), 12) * 0.055
                handler(.success(AccelerationVector(
                    x: sin(phase) * 0.014 + pulse,
                    y: sin(phase * 1.37) * 0.009,
                    z: cos(phase * 0.73) * 0.006
                )))
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

@MainActor
final class DemoLevelProvider: LevelProviding {
    private var timer: Timer?
    private var phase = 0.0

    let isAvailable = true
    let isDemo = true

    func start(handler: @escaping LevelHandler) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                phase += 0.018
                handler(.success(LevelAttitude(
                    xDegrees: sin(phase) * 4.2,
                    yDegrees: cos(phase * 0.83) * 2.8
                )))
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

@MainActor
enum MotionProviderFactory {
    static func makeVibrationProvider() -> any VibrationProviding {
        #if targetEnvironment(simulator)
        DemoVibrationProvider()
        #else
        CoreMotionVibrationProvider()
        #endif
    }

    static func makeLevelProvider() -> any LevelProviding {
        #if targetEnvironment(simulator)
        DemoLevelProvider()
        #else
        CoreMotionLevelProvider()
        #endif
    }
}
