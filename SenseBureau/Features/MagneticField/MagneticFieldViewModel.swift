import Combine
import Foundation
import UIKit

@MainActor
final class MagneticFieldViewModel: ObservableObject {
    enum SessionState: Equatable {
        case idle
        case calibrating(progress: Double)
        case active
        case paused
        case unsupported
        case failed
    }

    @Published private(set) var state: SessionState = .idle
    @Published private(set) var fieldStrength = 0.0
    @Published private(set) var baseline = 0.0
    @Published private(set) var relativeChange = 0.0
    @Published private(set) var peakChange = 0.0
    @Published private(set) var samples: [MagneticFieldSample] = []

    let alertThreshold = 30.0

    var isDemo: Bool { provider.isDemo }
    var isRunning: Bool { state == .active || isCalibrating }
    var isCalibrating: Bool {
        if case .calibrating = state { return true }
        return false
    }

    var calibrationProgress: Double {
        if case let .calibrating(progress) = state { return progress }
        return state == .active ? 1 : 0
    }

    private let provider: MagnetometerProviding
    private let calibrationSampleCount = 30
    private var calibrationValues: [Double] = []
    private var previousSmoothed: Double?
    private var hasTriggeredThreshold = false

    init() {
        provider = MagnetometerProviderFactory.make()
    }

    init(provider: MagnetometerProviding) {
        self.provider = provider
    }

    func start() {
        guard provider.isAvailable else {
            state = .unsupported
            return
        }
        calibrate()
        provider.start { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(vector): process(vector)
            case .failure: state = .failed
            }
        }
    }

    func calibrate() {
        calibrationValues.removeAll(keepingCapacity: true)
        previousSmoothed = nil
        baseline = 0
        relativeChange = 0
        peakChange = 0
        samples.removeAll(keepingCapacity: true)
        state = .calibrating(progress: 0)
    }

    func togglePause() {
        switch state {
        case .active:
            provider.stop()
            state = .paused
        case .paused:
            state = .active
            provider.start { [weak self] result in
                guard let self else { return }
                if case let .success(vector) = result { process(vector) }
            }
        default:
            break
        }
    }

    func stop() {
        provider.stop()
    }

    private func process(_ vector: MagneticVector) {
        let raw = MagneticFieldMath.magnitude(of: vector)
        let smoothed = MagneticFieldMath.smoothed(previous: previousSmoothed, current: raw)
        previousSmoothed = smoothed
        fieldStrength = smoothed

        if isCalibrating {
            calibrationValues.append(smoothed)
            let progress = min(1, Double(calibrationValues.count) / Double(calibrationSampleCount))
            state = .calibrating(progress: progress)
            if calibrationValues.count >= calibrationSampleCount,
               let calibratedBaseline = MagneticFieldMath.baseline(from: calibrationValues) {
                baseline = calibratedBaseline
                state = .active
            }
            return
        }

        guard state == .active else { return }
        relativeChange = abs(smoothed - baseline)
        peakChange = max(peakChange, relativeChange)
        samples.append(MagneticFieldSample(timestamp: .now, magnitude: relativeChange))
        if samples.count > 72 { samples.removeFirst(samples.count - 72) }
        updateThresholdFeedback()
    }

    private func updateThresholdFeedback() {
        if relativeChange >= alertThreshold, !hasTriggeredThreshold {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            hasTriggeredThreshold = true
        } else if relativeChange < alertThreshold * 0.7 {
            hasTriggeredThreshold = false
        }
    }
}
