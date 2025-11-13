import Foundation

public final class PositionDataProcessor: ProcessorBase<PositionDataPoint> {
    public override func didMerge(update: PositionDataPoint, timestamp: Date) async {
        mutateLatest { latest in
            var current = latest.position.last ?? PositionDataPoint.PositionData()
            for item in update.position {
                if let ts = item.timestamp {
                    current.timestamp = ts
                }
                for (driver, entry) in item.entries {
                    if var existing = current.entries[driver] {
                        existing.merge(with: entry)
                        current.entries[driver] = existing
                    } else {
                        current.entries[driver] = entry
                    }
                }
            }
            latest.position = [current]
        }
    }
}
