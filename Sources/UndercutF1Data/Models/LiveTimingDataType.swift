import Foundation

public enum LiveTimingDataType: String, CaseIterable, Sendable {
    case heartbeat = "Heartbeat"
    case extrapolatedClock = "ExtrapolatedClock"
    case timingStats = "TimingStats"
    case timingAppData = "TimingAppData"
    case weatherData = "WeatherData"
    case trackStatus = "TrackStatus"
    case driverList = "DriverList"
    case raceControlMessages = "RaceControlMessages"
    case sessionInfo = "SessionInfo"
    case sessionData = "SessionData"
    case lapCount = "LapCount"
    case timingData = "TimingData"
    case teamRadio = "TeamRadio"
    case carData = "CarData"
    case position = "Position"
    case championshipPrediction = "ChampionshipPrediction"
    case pitLaneTimeCollection = "PitLaneTimeCollection"
    case pitStopSeries = "PitStopSeries"
    case pitStop = "PitStop"
}
