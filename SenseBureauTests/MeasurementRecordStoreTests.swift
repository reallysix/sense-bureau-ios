import SwiftData
import XCTest
@testable import SenseBureau

final class MeasurementRecordStoreTests: XCTestCase {
    @MainActor
    func testSaveAndRecentReturnsNewestFirst() throws {
        let container = try makeContainer()
        let store = MeasurementRecordStore(context: container.mainContext)

        try store.save(MeasurementRecord(
            capturedAt: Date(timeIntervalSince1970: 100),
            kind: .magneticField,
            value: 42,
            unit: "μT",
            peakValue: 51
        ))
        try store.save(MeasurementRecord(
            capturedAt: Date(timeIntervalSince1970: 200),
            kind: .vibration,
            value: 1.6,
            unit: "m/s²"
        ))

        let records = try store.recent()

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.map(\.kind), [.vibration, .magneticField])
        XCTAssertEqual(records.last?.peakValue, 51)
    }

    @MainActor
    func testRecentHonorsLimitAndDeleteAllClearsRecords() throws {
        let container = try makeContainer()
        let store = MeasurementRecordStore(context: container.mainContext)
        try store.save(MeasurementRecord(kind: .magneticField, value: 18, unit: "μT"))
        try store.save(MeasurementRecord(kind: .level, value: 2, unit: "°"))

        XCTAssertEqual(try store.recent(limit: 1).count, 1)

        try store.deleteAll()
        XCTAssertTrue(try store.recent().isEmpty)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeasurementRecord.self,
            configurations: configuration
        )
    }
}
