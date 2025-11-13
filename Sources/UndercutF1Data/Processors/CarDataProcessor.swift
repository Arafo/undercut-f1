import Foundation

public final class CarDataProcessor: ProcessorBase<CarDataPoint> {
    public override func didMerge(update: CarDataPoint, timestamp: Date) async {
        mutateLatest { latest in
            if latest.entries.count > 1 {
                latest.entries = Array(latest.entries.suffix(1))
            }
        }
    }
}
