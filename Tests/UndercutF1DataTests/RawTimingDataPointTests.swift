import XCTest
@testable import UndercutF1Data

final class RawTimingDataPointTests: XCTestCase {
    func testEncodingProducesExpectedKeys() throws {
        let jsonString = "{\"example\":true}"
        let date = ISO8601DateFormatter().date(from: "2024-01-01T12:34:56Z")!
        let dataPoint = try RawTimingDataPoint(type: "Heartbeat", jsonString: jsonString, dateTime: date)
        let data = try JSONEncoder().encode(dataPoint)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["Type"] as? String, "Heartbeat")
        XCTAssertNotNil(object?["Json"])
        XCTAssertNotNil(object?["DateTime"])
    }
}
