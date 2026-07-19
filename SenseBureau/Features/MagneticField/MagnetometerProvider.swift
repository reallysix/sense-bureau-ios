import CoreMotion
import Foundation

typealias MagnetometerHandler = @MainActor @Sendable (Result<MagneticVector, any Error>) -> Void

@MainActor
protocol MagnetometerProviding: AnyObject {
    var isAvailable: Bool { get }
    var isDemo: Bool { get }
    func start(handler: @escaping MagnetometerHandler)
    func stop()
}

@MainActor
final class CoreMotionMagnetometerProvider: MagnetometerProviding {
    private let manager = CMMotionManager()

    var isAvailable: Bool { manager.isMagnetometerAvailable }
    let isDemo = false

    func start(handler: @escaping MagnetometerHandler) {
        guard isAvailable else { return }
        manager.magnetometerUpdateInterval = 1.0 / 20.0
        manager.startMagnetometerUpdates(to: .main) { data, error in
            Task { @MainActor in
                if let error {
                    handler(.failure(error))
                    return
                }
                guard let field = data?.magneticField else { return }
                handler(.success(MagneticVector(x: field.x, y: field.y, z: field.z)))
            }
        }
    }

    func stop() {
        manager.stopMagnetometerUpdates()
    }
}

@MainActor
final class DemoMagnetometerProvider: MagnetometerProviding {
    private var timer: Timer?
    private var phase = 0.0

    let isAvailable = true
    let isDemo = true

    func start(handler: @escaping MagnetometerHandler) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.phase += 0.075
                let slowWave = sin(self.phase) * 8
                let sweep = sin(self.phase * 0.17) * 18
                let pulse = pow(max(0, sin(self.phase * 0.31)), 8) * 52
                handler(.success(MagneticVector(
                    x: 27 + slowWave,
                    y: 18 + sweep,
                    z: 31 + pulse
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
enum MagnetometerProviderFactory {
    static func make() -> MagnetometerProviding {
        #if targetEnvironment(simulator)
        DemoMagnetometerProvider()
        #else
        CoreMotionMagnetometerProvider()
        #endif
    }
}
