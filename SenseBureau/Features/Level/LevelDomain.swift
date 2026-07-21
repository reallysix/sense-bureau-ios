import Foundation

struct LevelAttitude: Equatable, Sendable {
    let xDegrees: Double
    let yDegrees: Double
}

enum LevelMath {
    static func adjusted(_ attitude: LevelAttitude, zero: LevelAttitude) -> LevelAttitude {
        LevelAttitude(
            xDegrees: attitude.xDegrees - zero.xDegrees,
            yDegrees: attitude.yDegrees - zero.yDegrees
        )
    }

    static func magnitude(of attitude: LevelAttitude) -> Double {
        min(90, hypot(attitude.xDegrees, attitude.yDegrees))
    }

    static func average(of values: [LevelAttitude]) -> LevelAttitude? {
        guard !values.isEmpty else { return nil }
        return LevelAttitude(
            xDegrees: values.map(\.xDegrees).reduce(0, +) / Double(values.count),
            yDegrees: values.map(\.yDegrees).reduce(0, +) / Double(values.count)
        )
    }
}
