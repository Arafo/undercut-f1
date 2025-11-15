import XCTest
@testable import UndercutF1Data

final class ProcessorSnapshotProviderTests: XCTestCase {
    func testSnapshotAtIndexEncodesLatestPayload() async throws {
        let processor = HeartbeatProcessor()
        var dataPoint = HeartbeatDataPoint()
        dataPoint.utc = Date(timeIntervalSince1970: 123)
        let payloadData = try LiveTimingDecoding.encoder.encode(dataPoint)
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: payloadData)
        await processor.process(type: .heartbeat, payload: jsonValue, timestamp: Date())

        let provider = ProcessorSnapshotProvider(processors: [processor])
        let snapshot = provider.snapshot(at: 0)

        XCTAssertEqual(snapshot?.name, "HeartbeatProcessor")
        XCTAssertTrue(snapshot?.payload.contains("Utc") == true)
    }

    func testSnapshotOutOfBoundsReturnsNil() {
        let provider = ProcessorSnapshotProvider(processors: [])
        XCTAssertNil(provider.snapshot(at: 1))
    }
}
