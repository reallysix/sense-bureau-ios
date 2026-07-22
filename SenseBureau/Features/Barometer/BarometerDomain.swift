import Foundation

enum BarometerAvailability: Equatable, Sendable {
    case available
    case unsupported
    case denied
}

struct BarometerReading: Equatable, Sendable {
    let pressureKPa: Double
    let relativeAltitudeMeters: Double
}

struct BarometerSample: Identifiable, Equatable, Sendable {
    let id = UUID()
    let timestamp: Date
    let pressureKPa: Double
    let relativeAltitudeMeters: Double
}

enum BarometerMath {
    static func pressureChange(current: Double, reference: Double) -> Double {
        current - reference
    }
}
