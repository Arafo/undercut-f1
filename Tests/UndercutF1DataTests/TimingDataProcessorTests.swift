import XCTest
@testable import UndercutF1Data

final class TimingDataProcessorTests: XCTestCase {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }()

    private func payload(for dataPoint: TimingDataPoint) throws -> JSONValue {
        let data = try encoder.encode(dataPoint)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Encoding", code: 0)
        }
        return try JSONValue.parse(from: json)
    }

    func testVerifyDataUpdate() async throws {
        let processor = TimingDataProcessor()

        var first = TimingDataPoint()
        var driver = TimingDataPoint.Driver()
        driver.line = 1
        driver.gapToLeader = "+1.000"
        driver.inPit = true
        var bestLap = TimingDataPoint.Driver.BestLap()
        bestLap.value = "1.11"
        driver.bestLapTime = bestLap
        first.lines["1"] = driver

        var second = TimingDataPoint()
        var secondDriver = TimingDataPoint.Driver()
        secondDriver.inPit = false
        second.lines["1"] = secondDriver

        for data in [first, second] {
            let payload = try payload(for: data)
            await processor.process(type: .timingData, payload: payload, timestamp: Date())
        }

        guard let line = processor.latest.lines["1"] else {
            XCTFail("Missing driver line")
            return
        }

        XCTAssertEqual(line.line, 1)
        XCTAssertEqual(line.inPit, false)
        XCTAssertEqual(line.gapToLeader, "+1.000")
        XCTAssertEqual(line.bestLapTime.value, "1.11")
    }

    func testVerifyBestLapUpdatesOnImprovement() async throws {
        let processor = TimingDataProcessor()

        var first = TimingDataPoint()
        var driver = TimingDataPoint.Driver()
        driver.line = 1
        driver.numberOfLaps = 1
        var initialBest = TimingDataPoint.Driver.BestLap()
        initialBest.value = "1:34.678"
        driver.bestLapTime = initialBest
        first.lines["1"] = driver

        var second = TimingDataPoint()
        var secondDriver = TimingDataPoint.Driver()
        secondDriver.numberOfLaps = 2
        var faster = TimingDataPoint.Driver.BestLap()
        faster.value = "1:20.123"
        secondDriver.bestLapTime = faster
        second.lines["1"] = secondDriver

        for data in [first, second] {
            let payload = try payload(for: data)
            await processor.process(type: .timingData, payload: payload, timestamp: Date())
        }

        guard let line = processor.latest.lines["1"] else {
            XCTFail("Missing driver line")
            return
        }

        XCTAssertEqual(line.line, 1)
        XCTAssertEqual(line.bestLapTime.value, "1:20.123")
        XCTAssertEqual(processor.bestLaps["1"]?.bestLapTime.value, "1:20.123")
    }

    func testVerifyBestLapDoesNotUpdateOnSlowerLap() async throws {
        let processor = TimingDataProcessor()

        var first = TimingDataPoint()
        var driver = TimingDataPoint.Driver()
        driver.line = 1
        driver.numberOfLaps = 1
        var initialBest = TimingDataPoint.Driver.BestLap()
        initialBest.value = "1:34.678"
        driver.bestLapTime = initialBest
        first.lines["1"] = driver

        var second = TimingDataPoint()
        var secondDriver = TimingDataPoint.Driver()
        secondDriver.numberOfLaps = 2
        var slower = TimingDataPoint.Driver.BestLap()
        slower.value = "1:50.123"
        secondDriver.bestLapTime = slower
        second.lines["1"] = secondDriver

        for data in [first, second] {
            let payload = try payload(for: data)
            await processor.process(type: .timingData, payload: payload, timestamp: Date())
        }

        guard let line = processor.latest.lines["1"] else {
            XCTFail("Missing driver line")
            return
        }

        XCTAssertEqual(line.line, 1)
        XCTAssertEqual(line.bestLapTime.value, "1:50.123")
        XCTAssertEqual(processor.bestLaps["1"]?.bestLapTime.value, "1:34.678")
    }
}
