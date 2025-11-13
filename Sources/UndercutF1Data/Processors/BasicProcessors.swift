import Foundation

public final class HeartbeatProcessor: ProcessorBase<HeartbeatDataPoint> {}

public final class LapCountProcessor: ProcessorBase<LapCountDataPoint> {}

public final class TimingAppDataProcessor: ProcessorBase<TimingAppDataPoint> {}

public final class TrackStatusProcessor: ProcessorBase<TrackStatusDataPoint> {}

public final class WeatherProcessor: ProcessorBase<WeatherDataPoint> {}

public final class ChampionshipPredictionProcessor: ProcessorBase<ChampionshipPredictionDataPoint> {}

public final class TimingStatsProcessor: ProcessorBase<TimingStatsDataPoint> {}

public final class PitStopSeriesProcessor: ProcessorBase<PitStopSeriesDataPoint> {}

public final class DriverListProcessor: ProcessorBase<DriverListDataPoint> {
    public func isSelected(driverNumber: String) -> Bool {
        latest.isSelected(driverNumber: driverNumber)
    }
}

extension HeartbeatProcessor: @unchecked Sendable {}
extension LapCountProcessor: @unchecked Sendable {}
extension TimingAppDataProcessor: @unchecked Sendable {}
extension TrackStatusProcessor: @unchecked Sendable {}
extension WeatherProcessor: @unchecked Sendable {}
extension ChampionshipPredictionProcessor: @unchecked Sendable {}
extension TimingStatsProcessor: @unchecked Sendable {}
extension PitStopSeriesProcessor: @unchecked Sendable {}
extension PitLaneTimeCollectionProcessor: @unchecked Sendable {}
extension DriverListProcessor: @unchecked Sendable {}
