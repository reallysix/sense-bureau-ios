import Foundation

struct MagneticVector: Equatable, Sendable {
    let x: Double
    let y: Double
    let z: Double
}

struct MagneticFieldSample: Identifiable, Equatable, Sendable {
    let id = UUID()
    let timestamp: Date
    let magnitude: Double
}

enum MagneticFieldMath {
    static func magnitude(of vector: MagneticVector) -> Double {
        sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }

    static func smoothed(previous: Double?, current: Double, alpha: Double = 0.24) -> Double {
        guard let previous else { return current }
        return alpha * current + (1 - alpha) * previous
    }

    static func baseline(from values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let trim = values.count >= 10 ? values.count / 10 : 0
        let kept = sorted.dropFirst(trim).dropLast(trim)
        guard !kept.isEmpty else { return nil }
        return kept.reduce(0, +) / Double(kept.count)
    }
}

