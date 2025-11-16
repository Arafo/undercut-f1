import XCTest
@testable import UndercutF1Data

final class TimingDataPointExtensionsTests: XCTestCase {
    func testGapToLeaderSeconds() {
        let cases: [(String?, Decimal?)] = [
            ("LAP 10", 0),
            ("+1", 1),
            ("+1.123", Decimal(string: "1.123")),
            ("1L", nil)
        ]

        for (input, expected) in cases {
            var driver = TimingDataPoint.Driver()
            driver.gapToLeader = input
            XCTAssertEqual(driver.gapToLeaderSeconds(), expected)
        }
    }

    func testIntervalSeconds() {
        let cases: [(String?, Decimal?)] = [
            ("LAP 10", 0),
            ("+1", 1),
            ("+1.123", Decimal(string: "1.123")),
            ("1L", nil)
        ]

        for (input, expected) in cases {
            var interval = TimingDataPoint.Driver.Interval()
            interval.value = input
            XCTAssertEqual(interval.intervalSeconds(), expected)
        }
    }

    func testLapSectorTimeToTimeInterval() {
        let cases: [(String, TimeInterval)] = [
            ("1:23.456", 83.456),
            ("23.456", 23.456)
        ]

        for (input, expected) in cases {
            var lap = TimingDataPoint.Driver.LapSectorTime()
            lap.value = input
            XCTAssertEqual(lap.toTimeInterval(), expected, accuracy: 0.0001)
        }
    }

    func testBestLapToTimeInterval() {
        let cases: [(String, TimeInterval)] = [
            ("1:23.456", 83.456),
            ("23.456", 23.456)
        ]

        for (input, expected) in cases {
            var lap = TimingDataPoint.Driver.BestLap()
            lap.value = input
            XCTAssertEqual(lap.toTimeInterval(), expected, accuracy: 0.0001)
        }
    }
}
