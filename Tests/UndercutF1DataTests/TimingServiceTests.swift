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

    func testInflatesZippedPayloadBeforeProcessing() async throws {
        let expectation = XCTestExpectation(description: "Car data processed")
        struct TestProcessor: TimingProcessor {
            let expectation: XCTestExpectation
            func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async {
                guard type == .carData else { return }
                if case .object = payload {
                    expectation.fulfill()
                }
            }
        }

        let processor = TestProcessor(expectation: expectation)
        let service = TimingService(processors: [processor])
        await service.start()
        let compressed = "pZfBbtswDIbfxeesICmKIn0t9gbbZcMOxVBgA4Yeut6KvnsdienUio4TDwiSIPAvUdTPj8zz9Pnh6fH3/d9p/v48fX36Oc0TAfEnKMvrC6aZeAa8yQWLmn6bDtPt3ePy9POEx7fbX3cPD/d/6g8wzVkyHCZavvBhStOMh4mnefkp13c+fry81CcGLVPJTUtVSyvaFGgRLZUqptTUuaoRRj2HeknS9JaqvtQHzQY5QqQHYa161Fz13EVfo/i3QJg4EGyH1+7wOEaPUfhi0FJn7fCpqhOPaomDtxY8QeqSJ2nUa6A30bY7oXa5i85OUfKsiOeeyroeqz4yzhK/u47YtgII3QN6WkD62//gnhZBaB9IpwxmW1+gRVCCBQooNfv4DaTVE6TIPsLQ7F/O1w6vmN/tQyq9+XXQ5xzolb32TLrNj1X8QS1R8hWUm1qH0N+fvESZQ8hk7p62vaymXqPULac39AV69w+lv6xwjpBqWBi3CclGPeWuImTClqqMOwhJRF4ksIuQJF4jxr3FR5PEhMSCqVm8wC5Ckl+TQE/I0WUhIQtK6j3qhCyXEpJTckL27YXlMkIux7OWPPTkyZWIfOML0rr+HCLB2PsjbgUQ2wfIMyCyD5Gc8jZj1xEpaqnnxPWEbJgovX3G9r5CyCyePm/vTsixw4aENGJ0vHO3u1yIyFJv/Xj0se4vQmRJFlz+5YiE7NCiBLsRSTd0ZC3jJiJTbrt5N78KkeAuyXA9IsHIq4zzRp5ilxhELsEIcWtTpGMi04bJY0ayU076MQCDOS5kpPgAjtDvzgFiY0ieZli0vpGG0ceUzOotQnFjgZCSaqcqBdhHSXHnEcpWACuU9GGGHDNXUzKLbmP2DCXlNIvhYKBtRgrofzAynQYM7QGfxx4bMhJhmRDa7eM7SI6MDSEpCu1fhPI+SOob48o+SBYvPkr9IBpA8sfLKw=="
        let wrapped = "\"\(compressed)\""
        await service.enqueue(type: "CarData.z", data: wrapped, timestamp: Date())
        await fulfillment(of: [expectation], timeout: 2.0)
        await service.stop()
    }
}
