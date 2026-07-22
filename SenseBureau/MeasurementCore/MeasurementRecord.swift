import Foundation
import SwiftData

enum MeasurementKind: String, CaseIterable, Codable, Hashable, Sendable {
    case magneticField
    case vibration
    case level
    case barometer
}

@Model
final class MeasurementRecord {
    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    var kindRawValue: String
    var value: Double
    var unit: String
    var peakValue: Double?

    var kind: MeasurementKind {
        get { MeasurementKind(rawValue: kindRawValue) ?? .magneticField }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        capturedAt: Date = .now,
        kind: MeasurementKind,
        value: Double,
        unit: String,
        peakValue: Double? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        kindRawValue = kind.rawValue
        self.value = value
        self.unit = unit
        self.peakValue = peakValue
    }
}

@MainActor
final class MeasurementRecordStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ record: MeasurementRecord) throws {
        context.insert(record)
        try context.save()
    }

    func recent(limit: Int = 20) throws -> [MeasurementRecord] {
        var descriptor = FetchDescriptor<MeasurementRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(0, limit)
        return try context.fetch(descriptor)
    }

    func delete(_ record: MeasurementRecord) throws {
        context.delete(record)
        try context.save()
    }

    func deleteAll() throws {
        let records = try context.fetch(FetchDescriptor<MeasurementRecord>())
        for record in records {
            context.delete(record)
        }
        try context.save()
    }
}
