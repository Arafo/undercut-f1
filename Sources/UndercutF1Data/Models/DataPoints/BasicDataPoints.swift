import Foundation

public struct HeartbeatDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .heartbeat
    public var utc: Date?

    public init() {}

    public mutating func merge(with other: HeartbeatDataPoint) {
        if let utc = other.utc {
            self.utc = utc
        }
    }

    private enum CodingKeys: String, CodingKey {
        case utc = "Utc"
    }
}

public struct LapCountDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .lapCount
    public var currentLap: Int?
    public var totalLaps: Int?

    public init() {}

    public mutating func merge(with other: LapCountDataPoint) {
        if let currentLap = other.currentLap {
            self.currentLap = currentLap
        }
        if let totalLaps = other.totalLaps {
            self.totalLaps = totalLaps
        }
    }

    private enum CodingKeys: String, CodingKey {
        case currentLap = "CurrentLap"
        case totalLaps = "TotalLaps"
    }
}

public struct TrackStatusDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .trackStatus
    public var status: String?
    public var message: String?

    public init() {}

    public mutating func merge(with other: TrackStatusDataPoint) {
        if let status = other.status {
            self.status = status
        }
        if let message = other.message {
            self.message = message
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status = "Status"
        case message = "Message"
    }
}

public struct WeatherDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .weatherData
    public var airTemp: String?
    public var humidity: String?
    public var pressure: String?
    public var rainfall: String?
    public var trackTemp: String?
    public var windDirection: String?
    public var windSpeed: String?

    public init() {}

    public mutating func merge(with other: WeatherDataPoint) {
        if let airTemp = other.airTemp { self.airTemp = airTemp }
        if let humidity = other.humidity { self.humidity = humidity }
        if let pressure = other.pressure { self.pressure = pressure }
        if let rainfall = other.rainfall { self.rainfall = rainfall }
        if let trackTemp = other.trackTemp { self.trackTemp = trackTemp }
        if let windDirection = other.windDirection { self.windDirection = windDirection }
        if let windSpeed = other.windSpeed { self.windSpeed = windSpeed }
    }

    private enum CodingKeys: String, CodingKey {
        case airTemp = "AirTemp"
        case humidity = "Humidity"
        case pressure = "Pressure"
        case rainfall = "Rainfall"
        case trackTemp = "TrackTemp"
        case windDirection = "WindDirection"
        case windSpeed = "WindSpeed"
    }
}

public struct ExtrapolatedClockDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .extrapolatedClock
    public var utc: Date?
    public var remaining: String = "99:00:00"
    public var extrapolating: Bool = false

    public init() {}

    public mutating func merge(with other: ExtrapolatedClockDataPoint) {
        if let utc = other.utc {
            self.utc = utc
        }
        if other.remaining != "99:00:00" || self.remaining == "99:00:00" {
            self.remaining = other.remaining
        }
        self.extrapolating = other.extrapolating
    }

    private enum CodingKeys: String, CodingKey {
        case utc = "Utc"
        case remaining = "Remaining"
        case extrapolating = "Extrapolating"
    }
}

public struct TimingStatsDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .timingStats
    public var lines: [String: Driver] = [:]

    public init() {}

    public mutating func merge(with other: TimingStatsDataPoint) {
        lines.mergeInPlace(other.lines)
    }

    public struct Driver: Codable, Mergeable, Sendable {
        public var bestSpeeds: [String: Stat] = [:]

        public init() {}

        public mutating func merge(with other: Driver) {
            bestSpeeds.mergeInPlace(other.bestSpeeds)
        }

        public struct Stat: Codable, Mergeable, Sendable {
            public var value: String?
            public var position: Int?

            public init() {}

            public mutating func merge(with other: Stat) {
                if let value = other.value { self.value = value }
                if let position = other.position { self.position = position }
            }

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case position = "Position"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case bestSpeeds = "BestSpeeds"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lines = "Lines"
    }
}

public struct ChampionshipPredictionDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .championshipPrediction
    public var drivers: [String: Driver] = [:]
    public var teams: [String: Team] = [:]

    public init() {}

    public mutating func merge(with other: ChampionshipPredictionDataPoint) {
        drivers.mergeInPlace(other.drivers)
        teams.mergeInPlace(other.teams)
    }

    public struct Driver: Codable, Mergeable, Sendable {
        public var racingNumber: String?
        public var currentPosition: Int?
        public var predictedPosition: Int?
        public var currentPoints: Decimal?
        public var predictedPoints: Decimal?

        public init() {}

        public mutating func merge(with other: Driver) {
            if let racingNumber = other.racingNumber { self.racingNumber = racingNumber }
            if let currentPosition = other.currentPosition { self.currentPosition = currentPosition }
            if let predictedPosition = other.predictedPosition { self.predictedPosition = predictedPosition }
            if let currentPoints = other.currentPoints { self.currentPoints = currentPoints }
            if let predictedPoints = other.predictedPoints { self.predictedPoints = predictedPoints }
        }

        private enum CodingKeys: String, CodingKey {
            case racingNumber = "RacingNumber"
            case currentPosition = "CurrentPosition"
            case predictedPosition = "PredictedPosition"
            case currentPoints = "CurrentPoints"
            case predictedPoints = "PredictedPoints"
        }
    }

    public struct Team: Codable, Mergeable, Sendable {
        public var teamName: String?
        public var currentPosition: Int?
        public var predictedPosition: Int?
        public var currentPoints: Decimal?
        public var predictedPoints: Decimal?

        public init() {}

        public mutating func merge(with other: Team) {
            if let teamName = other.teamName { self.teamName = teamName }
            if let currentPosition = other.currentPosition { self.currentPosition = currentPosition }
            if let predictedPosition = other.predictedPosition { self.predictedPosition = predictedPosition }
            if let currentPoints = other.currentPoints { self.currentPoints = currentPoints }
            if let predictedPoints = other.predictedPoints { self.predictedPoints = predictedPoints }
        }

        private enum CodingKeys: String, CodingKey {
            case teamName = "TeamName"
            case currentPosition = "CurrentPosition"
            case predictedPosition = "PredictedPosition"
            case currentPoints = "CurrentPoints"
            case predictedPoints = "PredictedPoints"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case drivers = "Drivers"
        case teams = "Teams"
    }
}
