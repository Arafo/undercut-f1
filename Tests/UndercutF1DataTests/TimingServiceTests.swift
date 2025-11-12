import XCTest
@testable import UndercutF1Data

final class TimingServiceTests: XCTestCase {
    func testQueueProcessesImmediately() async throws {
        let expectation = XCTestExpectation(description: "Processor invoked")
        struct TestProcessor: TimingProcessor {
            let expectation: XCTestExpectation
            func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async {
                if type == .heartbeat {
                    expectation.fulfill()
                }
            }
        }

        let processor = TestProcessor(expectation: expectation)
        let service = TimingService(processors: [processor])
        await service.start()
        await service.enqueue(type: "Heartbeat", data: "{\"example\":true}", timestamp: Date())
        await fulfillment(of: [expectation], timeout: 2.0)
        await service.stop()
    }
}
