import Foundation

struct AccelerationVector: Equatable, Sendable {
    let x: Double
    let y: Double
    let z: Double
}

struct VibrationSample: Identifiable, Equatable, Sendable {
    let id = UUID()
    let timestamp: Date
    let magnitude: Double
}

enum VibrationMath {
    static func magnitudeMG(of vector: AccelerationVector) -> Double {
        sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z) * 1_000
    }

    static func baseline(from values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let trim = values.count >= 10 ? values.count / 10 : 0
        let kept = sorted.dropFirst(trim).dropLast(trim)
        guard !kept.isEmpty else { return nil }
        return kept.reduce(0, +) / Double(kept.count)
    }

    static func smoothed(previous: Double?, current: Double, alpha: Double = 0.2) -> Double {
        guard let previous else { return current }
        return alpha * current + (1 - alpha) * previous
    }

    static func rms(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let meanSquare = values.reduce(0) { $0 + $1 * $1 } / Double(values.count)
        return sqrt(meanSquare)
    }
}
