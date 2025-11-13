import XCTest
@testable import UndercutF1Data

private actor TestDateTimeProvider: DateTimeProviding {
    private let current: Date
    init(current: Date) { self.current = current }
    func currentUTC() async -> Date { current }
    func setDelay(_ delay: TimeInterval) async {}
    func getDelay() async -> TimeInterval { 0 }
    func togglePause() async {}
    func isPaused() async -> Bool { false }
}

final class ExtrapolatedClockProcessorTests: XCTestCase {
    func testExtrapolatedRemaining() async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let cases: [(String, Date, TimeInterval)] = [
            (
                "{ \"Utc\": \"2024-05-04T20:00:00.998Z\", \"Remaining\": \"00:17:59\", \"Extrapolating\": true }",
                formatter.date(from: "2024-05-04T20:00:01.998Z")!,
                TimeInterval(17 * 60 + 58)
            ),
            (
                "{ \"Utc\": \"2024-05-04T20:00:00.998Z\", \"Remaining\": \"00:17:59\", \"Extrapolating\": false }",
                formatter.date(from: "2024-05-04T20:00:00.998Z")!,
                TimeInterval(17 * 60 + 59)
            ),
            (
                "{ \"Utc\": \"2024-05-04T20:00:00.998Z\", \"Remaining\": \"00:17:59\", \"Extrapolating\": true }",
                formatter.date(from: "2024-05-04T20:05:09.998Z")!,
                TimeInterval(12 * 60 + 50)
            ),
        ]

        for (json, currentDate, expected) in cases {
            let provider = TestDateTimeProvider(current: currentDate)
            let processor = ExtrapolatedClockProcessor(dateTimeProvider: provider)
            let payload = try JSONValue.parse(from: json)
            await processor.process(type: .extrapolatedClock, payload: payload, timestamp: currentDate)
            let remaining = await processor.extrapolatedRemaining()
            XCTAssertNotNil(remaining)
            if let remaining {
                XCTAssertEqual(remaining, expected, accuracy: 0.01)
            }
        }
    }
}
