import CoreMotion
import Foundation

typealias BarometerHandler = @MainActor @Sendable (Result<BarometerReading, any Error>) -> Void

@MainActor
protocol BarometerProviding: AnyObject {
    var availability: BarometerAvailability { get }
    var isDemo: Bool { get }
    func start(handler: @escaping BarometerHandler)
    func stop()
}

@MainActor
final class CoreMotionBarometerProvider: BarometerProviding {
    private let altimeter = CMAltimeter()

    var availability: BarometerAvailability {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return .unsupported }
        switch CMAltimeter.authorizationStatus() {
        case .denied, .restricted:
            return .denied
        default:
            return .available
        }
    }

    let isDemo = false

    func start(handler: @escaping BarometerHandler) {
        guard availability == .available else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
            Task { @MainActor in
                if let error {
                    handler(.failure(error))
                    return
                }
                guard let data else { return }
                handler(.success(BarometerReading(
                    pressureKPa: data.pressure.doubleValue,
                    relativeAltitudeMeters: data.relativeAltitude.doubleValue
                )))
            }
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}

@MainActor
final class DemoBarometerProvider: BarometerProviding {
    private var timer: Timer?
    private var phase = 0.0

    let availability: BarometerAvailability = .available
    let isDemo = true

    func start(handler: @escaping BarometerHandler) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                phase += 0.08
                handler(.success(BarometerReading(
                    pressureKPa: 101.325 + sin(phase * 0.7) * 0.035,
                    relativeAltitudeMeters: sin(phase) * 1.8
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
final class UnavailableBarometerProvider: BarometerProviding {
    let availability: BarometerAvailability
    let isDemo = false

    init(availability: BarometerAvailability) {
        self.availability = availability
    }

    func start(handler: @escaping BarometerHandler) {}
    func stop() {}
}

@MainActor
enum BarometerProviderFactory {
    static func make() -> any BarometerProviding {
        #if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-barometerUnsupported") {
            return UnavailableBarometerProvider(availability: .unsupported)
        }
        if arguments.contains("-barometerDenied") {
            return UnavailableBarometerProvider(availability: .denied)
        }
        return DemoBarometerProvider()
        #else
        return CoreMotionBarometerProvider()
        #endif
    }
}
