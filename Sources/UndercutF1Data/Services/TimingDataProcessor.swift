import Foundation

public actor TimingDataProcessor: TimingProcessor {
    public private(set) var latest = TimingDataPoint()
    public private(set) var driversByLap: [Int: [String: TimingDataPoint.Driver]] = [:]
    public private(set) var bestLaps: [String: TimingDataPoint.Driver] = [:]

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        encoder.outputFormatting = []
    }

    public func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async {
        guard type == .timingData else { return }
        guard let data = try? encoder.encode(payload) else { return }
        guard let update = try? decoder.decode(TimingDataPoint.self, from: data) else { return }

        latest.merge(with: update)

        for (driverNumber, partialUpdate) in update.lines {
            trackPitLaps(driverNumber: driverNumber, partialUpdate: partialUpdate)
            guard let updated = latest.lines[driverNumber] else { continue }
            guard let cloned = clone(driver: updated) else { continue }

            if let laps = partialUpdate.numberOfLaps {
                handleNewLap(driverNumber: driverNumber, laps: laps, updated: cloned)
            }

            if let bestValue = partialUpdate.bestLapTime.value, !bestValue.isEmpty {
                handleNewBestLap(driverNumber: driverNumber, partialUpdate: partialUpdate, updated: cloned)
            }

            if updated.bestLapTime.value?.isEmpty ?? true {
                bestLaps.removeValue(forKey: driverNumber)
            }
        }
    }

    private func clone(driver: TimingDataPoint.Driver) -> TimingDataPoint.Driver? {
        guard let data = try? encoder.encode(driver) else { return nil }
        return try? decoder.decode(TimingDataPoint.Driver.self, from: data)
    }

    private func handleNewBestLap(
        driverNumber: String,
        partialUpdate: TimingDataPoint.Driver,
        updated: TimingDataPoint.Driver
    ) {
        if let existing = bestLaps[driverNumber] {
            guard
                let newLap = partialUpdate.bestLapTime.timeInterval(),
                let existingLap = existing.bestLapTime.timeInterval(),
                newLap < existingLap
            else {
                return
            }
            bestLaps[driverNumber] = updated
        } else {
            bestLaps[driverNumber] = updated
        }
    }

    private func handleNewLap(
        driverNumber: String,
        laps: Int,
        updated: TimingDataPoint.Driver
    ) {
        var lapDrivers = driversByLap[laps] ?? [:]
        if lapDrivers[driverNumber] == nil {
            lapDrivers[driverNumber] = updated
        } else {
            lapDrivers[driverNumber] = updated
        }
        driversByLap[laps] = lapDrivers

        if updated.pitOut != true && updated.inPit != true {
            latest.lines[driverNumber]?.isPitLap = false
        }
    }

    private func trackPitLaps(driverNumber: String, partialUpdate: TimingDataPoint.Driver) {
        if partialUpdate.pitOut == true || partialUpdate.inPit == true {
            latest.lines[driverNumber]?.isPitLap = true
        }
    }
}
