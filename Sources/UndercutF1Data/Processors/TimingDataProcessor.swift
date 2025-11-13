import Foundation

public final class TimingDataProcessor: ProcessorBase<TimingDataPoint> {
    public private(set) var driversByLap: [Int: [String: TimingDataPoint.Driver]] = [:]
    public private(set) var bestLaps: [String: TimingDataPoint.Driver] = [:]

    public override func didMerge(update: TimingDataPoint, timestamp: Date) async {
        for (driverNumber, partialUpdate) in update.lines {
            mutateLatest { latest in
                guard var driverState = latest.lines[driverNumber] else { return }

                if partialUpdate.pitOut == true || partialUpdate.inPit == true {
                    driverState.isPitLap = true
                    latest.lines[driverNumber] = driverState
                }

                let snapshot = driverState

                if let lap = partialUpdate.numberOfLaps {
                    var lapDrivers = driversByLap[lap] ?? [:]
                    lapDrivers[driverNumber] = snapshot
                    driversByLap[lap] = lapDrivers

                    if driverState.pitOut != true && driverState.inPit != true {
                        driverState.isPitLap = false
                        latest.lines[driverNumber] = driverState
                    }
                }

                if let bestLapValue = partialUpdate.bestLapTime.value, !bestLapValue.isEmpty {
                    handleNewBestLap(driverNumber: driverNumber, partialUpdate: partialUpdate, updated: snapshot)
                } else if (snapshot.bestLapTime.value ?? "").isEmpty {
                    bestLaps.removeValue(forKey: driverNumber)
                }

                latest.lines[driverNumber] = driverState
            }
        }
    }

    private func handleNewBestLap(
        driverNumber: String,
        partialUpdate: TimingDataPoint.Driver,
        updated: TimingDataPoint.Driver
    ) {
        guard let newValue = partialUpdate.bestLapTime.value,
              let newTime = TimeUtilities.parseTimeSpan(newValue) else {
            return
        }

        if let existing = bestLaps[driverNumber],
           let existingValue = existing.bestLapTime.value,
           let existingTime = TimeUtilities.parseTimeSpan(existingValue) {
            if newTime < existingTime {
                bestLaps[driverNumber] = updated
            }
        } else {
            bestLaps[driverNumber] = updated
        }
    }
}
