import AVFoundation
import Foundation
import UIKit

@MainActor
protocol MeasurementFeedbackProviding: AnyObject {
    func calibrationCompleted(soundEnabled: Bool, hapticsEnabled: Bool)
    func thresholdExceeded(soundEnabled: Bool, hapticsEnabled: Bool)
}

@MainActor
final class MeasurementFeedbackController: MeasurementFeedbackProviding {
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode?

    func calibrationCompleted(soundEnabled: Bool, hapticsEnabled: Bool) {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if soundEnabled {
            playTone(frequency: 660, duration: 0.09)
        }
    }

    func thresholdExceeded(soundEnabled: Bool, hapticsEnabled: Bool) {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        if soundEnabled {
            playTone(frequency: 880, duration: 0.08)
        }
    }

    private func playTone(frequency: Double, duration: Double) {
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channel = buffer.floatChannelData?[0]
        else { return }

        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let attack = min(1, Double(frame) / 180)
            let release = min(1, Double(Int(frameCount) - frame) / 540)
            let envelope = min(attack, release)
            channel[frame] = Float(sin(2 * .pi * frequency * time) * 0.08 * envelope)
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try engine.start()
            player.scheduleBuffer(buffer)
            player.play()
            audioEngine = engine
            audioPlayer = player
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(Int(duration * 1_000) + 50))
                guard self?.audioEngine === engine else { return }
                player.stop()
                engine.stop()
                self?.audioEngine = nil
                self?.audioPlayer = nil
            }
        } catch {
            audioEngine = nil
            audioPlayer = nil
        }
    }
}
