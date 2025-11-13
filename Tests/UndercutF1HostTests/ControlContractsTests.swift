import XCTest
@testable import UndercutF1Web

final class ControlContractsTests: XCTestCase {
    func testControlResponseEncodingMatchesCamelCase() throws {
        let response = ControlResponse(clockPaused: true, sessionRunning: true, sessionName: "Race")
        let data = try JSONCoders.encoder.encode(response)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["clockPaused"] as? Bool, true)
        XCTAssertEqual(json["sessionRunning"] as? Bool, true)
        XCTAssertEqual(json["sessionName"] as? String, "Race")
    }

    func testControlErrorProvidesExpectedMessage() {
        let error = ControlError(.noRunningSession)
        XCTAssertEqual(error.reason, "No session is currently running")
        XCTAssertEqual(error.status, .badRequest)
    }

    func testControlRequestDecodingRejectsUnknownOperation() {
        let payload = "{\"operation\":\"Invalid\"}".data(using: .utf8)!
        do {
            _ = try JSONCoders.decoder.decode(ControlRequest.self, from: payload)
            XCTFail("Expected to throw")
        } catch let error as ControlError {
            XCTAssertEqual(error.errorCode, .unknownOperation)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
