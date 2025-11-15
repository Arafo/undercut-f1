import Foundation

public extension TimingDataPoint.Driver {
    func gapToLeaderSeconds() -> Decimal? {
        guard let gap = gapToLeader?.trimmingCharacters(in: .whitespacesAndNewlines), !gap.isEmpty else {
            return nil
        }
        if gap.uppercased().contains("LAP") {
            return 0
        }
        return Decimal(string: gap)
    }
}

public extension TimingDataPoint.Driver.Interval {
    func intervalSeconds() -> Decimal? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if value.uppercased().contains("LAP") {
            return 0
        }
        return Decimal(string: value)
    }
}

public extension Dictionary where Key == String, Value == TimingDataPoint.Driver {
    func smartGapToLeaderSeconds(for driverNumber: String) -> Decimal? {
        guard let driver = self[driverNumber] else {
            return nil
        }

        if let gap = driver.gapToLeader, !gap.uppercased().contains(" L") {
            return driver.gapToLeaderSeconds()
        }

        guard let interval = driver.intervalToPositionAhead?.value, !interval.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }

        let ordered = self
            .sorted { (lhs, rhs) -> Bool in
                let leftLine = lhs.value.line ?? Int.max
                let rightLine = rhs.value.line ?? Int.max
                if leftLine == rightLine {
                    return lhs.key < rhs.key
                }
                return leftLine < rightLine
            }

        guard let lastUnlapped = (ordered.last { $0.value.gapToLeaderSeconds() != nil } ?? ordered.first)?.value,
              let baseGap = lastUnlapped.gapToLeaderSeconds() else {
            return nil
        }

        let targetLine = driver.line ?? Int.max
        let lastUnlappedLine = lastUnlapped.line ?? Int.min

        let additional = ordered
            .filter { entry in
                let line = entry.value.line ?? Int.max
                return line > lastUnlappedLine && line <= targetLine
            }
            .reduce(Decimal(0)) { partial, entry in
                partial + (entry.value.intervalToPositionAhead?.intervalSeconds() ?? 0)
            }

        return baseGap + additional
    }
}

public extension TimingDataPoint.Driver.BestLap {
    func toTimeInterval() -> TimeInterval? {
        guard let value = value else { return nil }
        return TimeUtilities.parseTimeSpan(value)
    }
}

public extension TimingDataPoint.Driver.LapSectorTime {
    func toTimeInterval() -> TimeInterval? {
        guard let value = value else { return nil }
        return TimeUtilities.parseTimeSpan(value)
    }
}
