import Foundation

enum MeasurementSessionState: Equatable, Sendable {
    case idle
    case calibrating(progress: Double)
    case active
    case paused
    case unsupported
    case failed
}
