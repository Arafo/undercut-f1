import XCTest
@testable import UndercutF1Data

final class TeamRadioProcessorTests: XCTestCase {
    func testSendsNotificationForNewCapture() async throws {
        let handler = TestNotificationHandler()
        let notifyService = NotifyService(handlers: [handler], options: LiveTimingOptions())
        let httpFactory = HTTPClientFactory(userAgent: "test", proxyBaseURL: nil)
        let sessionInfo = SessionInfoProcessor(httpClientFactory: httpFactory)
        let processor = TeamRadioProcessor(
            sessionInfoProcessor: sessionInfo,
            transcriptionProvider: MockTranscriptionProvider(),
            httpClientFactory: httpFactory,
            notifyService: notifyService
        )

        var capture = TeamRadioDataPoint.Capture()
        capture.racingNumber = "1"
        capture.utc = Date()

        var dataPoint = TeamRadioDataPoint()
        dataPoint.captures["1"] = capture
        let payload = try JSONDecoder().decode(JSONValue.self, from: LiveTimingDecoding.encoder.encode(dataPoint))

        await processor.process(type: .teamRadio, payload: payload, timestamp: Date())
        XCTAssertEqual(handler.callCount, 1)

        // Processing the same capture should not produce another notification
        await processor.process(type: .teamRadio, payload: payload, timestamp: Date())
        XCTAssertEqual(handler.callCount, 1)
    }
}

private final class TestNotificationHandler: NotificationHandling {
    private(set) var callCount: Int = 0
    func onNotification() async {
        callCount += 1
    }
}

private struct MockTranscriptionProvider: TranscriptionProviding {
    var isModelDownloaded: Bool { true }
    var modelPath: URL { URL(fileURLWithPath: "/tmp/model.bin") }
    var downloadProgress: Double { 1.0 }
    func transcribe(from file: URL) async throws -> String { "" }
    func ensureModelDownloaded() async throws {}
}
