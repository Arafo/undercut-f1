import XCTest
@testable import UndercutF1Host
import UndercutF1Data
import UndercutF1Web

final class TimingDataRegistryTests: XCTestCase {
    func testLatestProviderReturnsValue() async throws {
        let registry = TimingDataRegistry()
        await registry.registerLatestProvider(for: .driverList) {
            AnyEncodable(["driver": "HAM"])
        }

        let payload = await registry.latest(for: .driverList)
        let data = try XCTUnwrap(payload).encodeToData()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(json["driver"], "HAM")
    }

    func testLapHistoryAndBestLaps() async throws {
        let registry = TimingDataRegistry()
        await registry.registerLapHistory(
            provider: { lap in
                AnyEncodable(["lap": lap])
            },
            bestLapProvider: {
                AnyEncodable(["lap": "best"])
            }
        )

        let lapDataOptional = await registry.lap(number: 10)
        let lapData = try XCTUnwrap(lapDataOptional)
        let lapJson = try XCTUnwrap(JSONSerialization.jsonObject(with: lapData.encodeToData()) as? [String: Int])
        XCTAssertEqual(lapJson["lap"], 10)

        let bestOptional = await registry.bestLaps()
        let best = try XCTUnwrap(bestOptional)
        let bestJson = try XCTUnwrap(JSONSerialization.jsonObject(with: best.encodeToData()) as? [String: String])
        XCTAssertEqual(bestJson["lap"], "best")
    }
}

private extension AnyEncodable {
    func encodeToData() throws -> Data {
        try JSONCoders.encoder.encode(self)
    }
}
