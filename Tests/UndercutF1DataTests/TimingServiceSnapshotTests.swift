import XCTest
@testable import UndercutF1Data

final class TimingServiceSnapshotTests: XCTestCase {
    func testProcessSubscriptionDataMatchesSnapshot() async throws {
        let fixture = try DataFixtures.string(named: "subscribe_snapshot", withExtension: "json")
        let referenceDate = Date(timeIntervalSince1970: 1_713_456_000)
        let timingService = TimingService(clock: { referenceDate })

        await timingService.processSubscriptionData(fixture)
        let pending = await timingService.snapshotPendingItems()

        struct SnapshotItem: Codable, Equatable {
            let type: String
            let data: String?
            let timestamp: String
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let snapshot = pending.map { item in
            SnapshotItem(
                type: item.0,
                data: item.1,
                timestamp: formatter.string(from: item.2)
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(snapshot), encoding: .utf8)!

        let expected = try DataFixtures.string(named: "api_queue_snapshot", withExtension: "json")
        XCTAssertEqual(json, expected, "Snapshot mismatch. Actual output:\n\(json)")
    }
}
