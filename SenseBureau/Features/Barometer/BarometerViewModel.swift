import Combine
import Foundation

@MainActor
final class BarometerViewModel: ObservableObject {
    @Published private(set) var state: MeasurementSessionState = .idle
    @Published private(set) var pressureKPa = 0.0
    @Published private(set) var pressureChangeKPa = 0.0
    @Published private(set) var relativeAltitudeMeters = 0.0
    @Published private(set) var peakAltitudeMeters = 0.0
    @Published private(set) var samples: [BarometerSample] = []
    @Published private(set) var hasReading = false

    var isDemo: Bool { provider.isDemo }
    private(set) var isProviderRunning = false

    private let provider: any BarometerProviding
    private var referencePressureKPa: Double?
    private var baselineSessionAltitudeMeters = 0.0
    private var sessionAltitudeMeters = 0.0
    private var runStartSessionAltitudeMeters = 0.0
    private var runStartRawAltitudeMeters: Double?

    init() {
        provider = BarometerProviderFactory.make()
    }

    init(provider: any BarometerProviding) {
        self.provider = provider
    }

    func start() {
        switch provider.availability {
        case .unsupported:
            state = .unsupported
            return
        case .denied:
            state = .denied
            return
        case .available:
            break
        }

        guard !isProviderRunning, state != .paused else { return }
        state = .active
        runStartSessionAltitudeMeters = sessionAltitudeMeters
        runStartRawAltitudeMeters = nil
        isProviderRunning = true
        provider.start { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(reading):
                process(reading)
            case .failure:
                provider.stop()
                isProviderRunning = false
                state = .failed
            }
        }
    }

    func stop() {
        guard isProviderRunning else { return }
        provider.stop()
        isProviderRunning = false
    }

    func setBaseline() {
        guard state == .active, hasReading else { return }
        referencePressureKPa = pressureKPa
        baselineSessionAltitudeMeters = sessionAltitudeMeters
        pressureChangeKPa = 0
        relativeAltitudeMeters = 0
        peakAltitudeMeters = 0
        samples.removeAll(keepingCapacity: true)
    }

    func togglePause() {
        switch state {
        case .active:
            stop()
            state = .paused
        case .paused:
            state = .active
            start()
        default:
            break
        }
    }

    private func process(_ reading: BarometerReading) {
        guard state == .active else { return }
        if runStartRawAltitudeMeters == nil {
            runStartRawAltitudeMeters = reading.relativeAltitudeMeters
        }
        let rawOrigin = runStartRawAltitudeMeters ?? reading.relativeAltitudeMeters
        sessionAltitudeMeters = runStartSessionAltitudeMeters
            + reading.relativeAltitudeMeters
            - rawOrigin

        pressureKPa = reading.pressureKPa
        if referencePressureKPa == nil {
            referencePressureKPa = reading.pressureKPa
        }
        pressureChangeKPa = BarometerMath.pressureChange(
            current: pressureKPa,
            reference: referencePressureKPa ?? pressureKPa
        )
        relativeAltitudeMeters = sessionAltitudeMeters - baselineSessionAltitudeMeters
        peakAltitudeMeters = max(peakAltitudeMeters, abs(relativeAltitudeMeters))
        hasReading = true
        samples.append(BarometerSample(
            timestamp: .now,
            pressureKPa: pressureKPa,
            relativeAltitudeMeters: relativeAltitudeMeters
        ))
        if samples.count > 120 { samples.removeFirst(samples.count - 120) }
    }
}
