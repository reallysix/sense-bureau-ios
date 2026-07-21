import Combine
import Foundation

@MainActor
final class LevelViewModel: ObservableObject {
    @Published private(set) var state: MeasurementSessionState = .idle
    @Published private(set) var attitude = LevelAttitude(xDegrees: 0, yDegrees: 0)
    @Published private(set) var tiltMagnitude = 0.0

    var isDemo: Bool { provider.isDemo }
    var isZeroing: Bool {
        if case .calibrating = state { return true }
        return false
    }

    var zeroProgress: Double {
        if case let .calibrating(progress) = state { return progress }
        return state == .active ? 1 : 0
    }

    private(set) var isProviderRunning = false

    private let provider: any LevelProviding
    private let feedback: any MeasurementFeedbackProviding
    private let zeroSampleCount = 12
    private var rawAttitude = LevelAttitude(xDegrees: 0, yDegrees: 0)
    private var zeroOffset = LevelAttitude(xDegrees: 0, yDegrees: 0)
    private var zeroSamples: [LevelAttitude] = []
    private var soundEnabled = true
    private var hapticsEnabled = true

    init() {
        provider = MotionProviderFactory.makeLevelProvider()
        feedback = MeasurementFeedbackController()
    }

    init(
        provider: any LevelProviding,
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
        if state == .idle { state = .active }
        startProvider()
    }

    func stop() {
        guard isProviderRunning else { return }
        provider.stop()
        isProviderRunning = false
    }

    func zero() {
        guard state == .active else { return }
        zeroSamples.removeAll(keepingCapacity: true)
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
            case let .success(attitude): process(attitude)
            case .failure:
                provider.stop()
                isProviderRunning = false
                state = .failed
            }
        }
    }

    private func process(_ newAttitude: LevelAttitude) {
        rawAttitude = newAttitude

        if isZeroing {
            zeroSamples.append(newAttitude)
            let progress = min(1, Double(zeroSamples.count) / Double(zeroSampleCount))
            state = .calibrating(progress: progress)
            if zeroSamples.count >= zeroSampleCount,
               let average = LevelMath.average(of: zeroSamples) {
                zeroOffset = average
                state = .active
                feedback.calibrationCompleted(
                    soundEnabled: soundEnabled,
                    hapticsEnabled: hapticsEnabled
                )
            }
        }

        attitude = LevelMath.adjusted(rawAttitude, zero: zeroOffset)
        tiltMagnitude = LevelMath.magnitude(of: attitude)
    }
}
