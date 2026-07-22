import Combine
import Foundation

@MainActor
final class VibrationViewModel: ObservableObject {
    @Published private(set) var state: MeasurementSessionState = .idle
    @Published private(set) var currentMagnitude = 0.0
    @Published private(set) var rmsMagnitude = 0.0
    @Published private(set) var peakMagnitude = 0.0
    @Published private(set) var samples: [VibrationSample] = []

    var isDemo: Bool { provider.isDemo }
    var isCalibrating: Bool {
        if case .calibrating = state { return true }
        return false
    }

    var calibrationProgress: Double {
        if case let .calibrating(progress) = state { return progress }
        return state == .active ? 1 : 0
    }

    private(set) var isProviderRunning = false

    private let provider: any VibrationProviding
    private let feedback: any MeasurementFeedbackProviding
    private let calibrationSampleCount = 50
    private var calibrationVectors: [AccelerationVector] = []
    private var baselineVector = AccelerationVector(x: 0, y: 0, z: 0)
    private var noiseFloorMG = 3.0
    private var previousSmoothed: Double?
    private var hasStartedSession = false
    private var soundEnabled = true
    private var hapticsEnabled = true

    init() {
        provider = MotionProviderFactory.makeVibrationProvider()
        feedback = MeasurementFeedbackController()
    }

    init(
        provider: any VibrationProviding,
        feedback: any MeasurementFeedbackProviding = MeasurementFeedbackController()
    ) {
        self.provider = provider
        self.feedback = feedback
    }

    func configureFeedback(soundEnabled: Bool, hapticsEnabled: Bool) {
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
    }

    func start() {
        guard provider.isAvailable else {
            state = .unsupported
            return
        }
        guard !isProviderRunning, state != .paused else { return }
        if !hasStartedSession {
            hasStartedSession = true
            calibrate()
        }
        startProvider()
    }

    func stop() {
        guard isProviderRunning else { return }
        provider.stop()
        isProviderRunning = false
    }

    func calibrate() {
        guard state != .paused else { return }
        calibrationVectors.removeAll(keepingCapacity: true)
        previousSmoothed = nil
        baselineVector = AccelerationVector(x: 0, y: 0, z: 0)
        noiseFloorMG = 3
        currentMagnitude = 0
        rmsMagnitude = 0
        peakMagnitude = 0
        samples.removeAll(keepingCapacity: true)
        state = .calibrating(progress: 0)
    }

    func togglePause() {
        switch state {
        case .active:
            stop()
            state = .paused
        case .paused:
            state = .active
            startProvider()
        default:
            break
        }
    }

    private func startProvider() {
        isProviderRunning = true
        provider.start { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(vector): process(vector)
            case .failure:
                provider.stop()
                isProviderRunning = false
                state = .failed
            }
        }
    }

    private func process(_ vector: AccelerationVector) {
        if isCalibrating {
            calibrationVectors.append(vector)
            let progress = min(1, Double(calibrationVectors.count) / Double(calibrationSampleCount))
            state = .calibrating(progress: progress)
            if calibrationVectors.count >= calibrationSampleCount,
               let calibratedBaseline = VibrationMath.baselineVector(from: calibrationVectors) {
                baselineVector = calibratedBaseline
                noiseFloorMG = VibrationMath.noiseFloorMG(
                    from: calibrationVectors,
                    baseline: calibratedBaseline
                )
                state = .active
                feedback.calibrationCompleted(
                    soundEnabled: soundEnabled,
                    hapticsEnabled: hapticsEnabled
                )
            }
            return
        }

        guard state == .active else { return }
        let adjusted = VibrationMath.noiseGatedMagnitudeMG(
            of: vector,
            baseline: baselineVector,
            noiseFloorMG: noiseFloorMG
        )
        let smoothed = VibrationMath.smoothed(previous: previousSmoothed, current: adjusted)
        previousSmoothed = smoothed
        currentMagnitude = smoothed
        peakMagnitude = max(peakMagnitude, adjusted)
        samples.append(VibrationSample(timestamp: .now, magnitude: smoothed))
        if samples.count > 150 { samples.removeFirst(samples.count - 150) }
        rmsMagnitude = VibrationMath.rms(of: Array(samples.suffix(50).map(\.magnitude)))
    }
}
