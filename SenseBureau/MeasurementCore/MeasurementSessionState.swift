import Foundation

enum MeasurementSessionState: Equatable, Sendable {
    case idle
    case calibrating(progress: Double)
    case active
    case paused
    case unsupported
    case denied
    case failed

    var preventsMeasurementDisplay: Bool {
        switch self {
        case .unsupported, .denied, .failed:
            true
        default:
            false
        }
    }
}
