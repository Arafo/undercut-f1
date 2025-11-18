import Foundation

// MARK: - SignalR feed plumbing

/// Topics that are published by the F1 live timing SignalR hub.
public enum LiveTimingTopic: String, Decodable {
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
    case carData = "CarData.z"
    case position = "Position.z"
    case championshipPrediction = "ChampionshipPrediction"
    case pitLaneTimeCollection = "PitLaneTimeCollection"
    case pitStopSeries = "PitStopSeries"
    case pitStop = "PitStop"
}

/// Envelope emitted by the SignalR client when the `feed` method is invoked.
public struct SignalRFeedEnvelope {
    public let topic: LiveTimingTopic
    public let payload: Data
    public let timestamp: Date
}

/// Strongly-typed events produced once the payload has been decoded.
public enum LiveTimingEvent {
    case timingData(Date, TimingDataPoint)
    case lapCount(Date, LapCountDataPoint)
    case sessionInfo(Date, SessionInfoDataPoint)
    case driverList(Date, DriverListDataPoint)
    case timingAppData(Date, TimingAppDataPoint)
    case carData(Date, CarDataPoint)
    case position(Date, PositionDataPoint)
    case raceControlMessages(Date, RaceControlMessageDataPoint)
    case unhandled(Date, LiveTimingTopic, Data)
}

/// Helper that maps SignalR envelopes to strongly-typed events.
public final class LiveTimingFeedMapper {
    private let decoder: JSONDecoder
    private let iso8601WithFractionalSeconds = ISO8601DateFormatter()

    public init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        iso8601WithFractionalSeconds.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]
    }

    /// Entry point used from the SignalR callback to convert a payload to a Swift model.
    public func map(_ envelope: SignalRFeedEnvelope) throws -> LiveTimingEvent {
        switch envelope.topic {
        case .timingData:
            let point = try decoder.decode(TimingDataPoint.self, from: envelope.payload)
            return .timingData(envelope.timestamp, point)
        case .lapCount:
            let point = try decoder.decode(LapCountDataPoint.self, from: envelope.payload)
            return .lapCount(envelope.timestamp, point)
        case .sessionInfo:
            let point = try decoder.decode(SessionInfoDataPoint.self, from: envelope.payload)
            return .sessionInfo(envelope.timestamp, point)
        case .driverList:
            let point = try decoder.decode(DriverListDataPoint.self, from: envelope.payload)
            return .driverList(envelope.timestamp, point)
        case .timingAppData:
            let point = try decoder.decode(TimingAppDataPoint.self, from: envelope.payload)
            return .timingAppData(envelope.timestamp, point)
        case .carData:
            let point = try decoder.decode(CarDataPoint.self, from: envelope.payload)
            return .carData(envelope.timestamp, point)
        case .position:
            let point = try decoder.decode(PositionDataPoint.self, from: envelope.payload)
            return .position(envelope.timestamp, point)
        case .raceControlMessages:
            let point = try decoder.decode(RaceControlMessageDataPoint.self, from: envelope.payload)
            return .raceControlMessages(envelope.timestamp, point)
        default:
            return .unhandled(envelope.timestamp, envelope.topic, envelope.payload)
        }
    }

    /// Utility for SignalR libraries that surface the feed payload as `[String: Any]`.
    /// Converts the dictionary to `Data` so it can be decoded with the `JSONDecoder` above.
    public func makeEnvelope(topic: String, objectPayload: Any, isoTimestamp: String) throws -> SignalRFeedEnvelope {
        guard let knownTopic = LiveTimingTopic(rawValue: topic) else {
            throw NSError(domain: "LiveTimingFeed", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown topic: \(topic)"])
        }

        let data: Data
        if let alreadyData = objectPayload as? Data {
            data = alreadyData
        } else {
            data = try JSONSerialization.data(withJSONObject: objectPayload)
        }

        let timestamp = iso8601WithFractionalSeconds.date(from: isoTimestamp)
            ?? ISO8601DateFormatter().date(from: isoTimestamp)
            ?? Date()

        return SignalRFeedEnvelope(topic: knownTopic, payload: data, timestamp: timestamp)
    }
}

// MARK: - Timing tower models

public struct TimingDataPoint: Decodable {
    public let lines: [String: Driver]

    public struct Driver: Decodable {
        public struct Interval: Decodable {
            public let value: String?
            public let catching: Bool?

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case catching = "Catching"
            }
        }

        public struct LapSectorTime: Decodable {
            public struct Segment: Decodable {
                public let status: StatusFlags?

                private enum CodingKeys: String, CodingKey {
                    case status = "Status"
                }
            }

            public let value: String?
            public let overallFastest: Bool?
            public let personalFastest: Bool?
            public let segments: [Int: Segment]?

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case overallFastest = "OverallFastest"
                case personalFastest = "PersonalFastest"
                case segments = "Segments"
            }
        }

        public struct BestLap: Decodable {
            public let value: String?
            public let lap: Int?

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case lap = "Lap"
            }
        }

        public struct StatusFlags: OptionSet, Decodable {
            public let rawValue: Int

            public static let personalBest = StatusFlags(rawValue: 1)
            public static let overallBest = StatusFlags(rawValue: 2)
            public static let pitLane = StatusFlags(rawValue: 16)
            public static let chequeredFlag = StatusFlags(rawValue: 1024)
            public static let segmentComplete = StatusFlags(rawValue: 2048)

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(Int.self)
                self.init(rawValue: rawValue)
            }
        }

        public let gapToLeader: String?
        public let intervalToPositionAhead: Interval?
        public let line: Int?
        public let position: String?
        public let inPit: Bool?
        public let pitOut: Bool?
        public let numberOfPitStops: Int?
        public let isPitLap: Bool
        public let numberOfLaps: Int?
        public let lastLapTime: LapSectorTime?
        public let sectors: [String: LapSectorTime]
        public let bestLapTime: BestLap
        public let knockedOut: Bool?
        public let retired: Bool?
        public let stopped: Bool?
        public let status: StatusFlags?

        private enum CodingKeys: String, CodingKey {
            case gapToLeader = "GapToLeader"
            case intervalToPositionAhead = "IntervalToPositionAhead"
            case line = "Line"
            case position = "Position"
            case inPit = "InPit"
            case pitOut = "PitOut"
            case numberOfPitStops = "NumberOfPitStops"
            case isPitLap = "IsPitLap"
            case numberOfLaps = "NumberOfLaps"
            case lastLapTime = "LastLapTime"
            case sectors = "Sectors"
            case bestLapTime = "BestLapTime"
            case knockedOut = "KnockedOut"
            case retired = "Retired"
            case stopped = "Stopped"
            case status = "Status"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            gapToLeader = try container.decodeIfPresent(String.self, forKey: .gapToLeader)
            intervalToPositionAhead = try container.decodeIfPresent(Interval.self, forKey: .intervalToPositionAhead)
            line = try container.decodeIfPresent(Int.self, forKey: .line)
            position = try container.decodeIfPresent(String.self, forKey: .position)
            inPit = try container.decodeIfPresent(Bool.self, forKey: .inPit)
            pitOut = try container.decodeIfPresent(Bool.self, forKey: .pitOut)
            numberOfPitStops = try container.decodeIfPresent(Int.self, forKey: .numberOfPitStops)
            isPitLap = try container.decodeIfPresent(Bool.self, forKey: .isPitLap) ?? false
            numberOfLaps = try container.decodeIfPresent(Int.self, forKey: .numberOfLaps)
            lastLapTime = try container.decodeIfPresent(LapSectorTime.self, forKey: .lastLapTime)
            sectors = try container.decodeIfPresent([String: LapSectorTime].self, forKey: .sectors) ?? [:]
            bestLapTime = try container.decodeIfPresent(BestLap.self, forKey: .bestLapTime) ?? BestLap(value: nil, lap: nil)
            knockedOut = try container.decodeIfPresent(Bool.self, forKey: .knockedOut)
            retired = try container.decodeIfPresent(Bool.self, forKey: .retired)
            stopped = try container.decodeIfPresent(Bool.self, forKey: .stopped)
            status = try container.decodeIfPresent(StatusFlags.self, forKey: .status)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lines = "Lines"
    }
}

public struct LapCountDataPoint: Decodable {
    public let currentLap: Int?
    public let totalLaps: Int?

    private enum CodingKeys: String, CodingKey {
        case currentLap = "CurrentLap"
        case totalLaps = "TotalLaps"
    }
}

public struct SessionInfoDataPoint: Decodable {
    public struct MeetingDetail: Decodable {
        public struct CircuitDetail: Decodable {
            public let key: Int?
            public let shortName: String?

            private enum CodingKeys: String, CodingKey {
                case key = "Key"
                case shortName = "ShortName"
            }
        }

        public let name: String?
        public let circuit: CircuitDetail?

        private enum CodingKeys: String, CodingKey {
            case name = "Name"
            case circuit = "Circuit"
        }
    }

    public struct CircuitPoint: Decodable {
        public let x: Int
        public let y: Int

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            x = try container.decode(Int.self)
            y = try container.decode(Int.self)
        }
    }

    public struct CircuitCorner: Decodable {
        public let number: Int
        public let x: Double
        public let y: Double

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            number = try container.decode(Int.self)
            x = try container.decode(Double.self)
            y = try container.decode(Double.self)
        }
    }

    public let key: Int?
    public let type: String?
    public let name: String?
    public let startDate: Date?
    public let endDate: Date?
    public let gmtOffset: String?
    public let path: String?
    public let meeting: MeetingDetail?
    public let circuitPoints: [CircuitPoint]
    public let circuitCorners: [CircuitCorner]
    public let circuitRotation: Int

    private enum CodingKeys: String, CodingKey {
        case key = "Key"
        case type = "Type"
        case name = "Name"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case gmtOffset = "GmtOffset"
        case path = "Path"
        case meeting = "Meeting"
        case circuitPoints = "CircuitPoints"
        case circuitCorners = "CircuitCorners"
        case circuitRotation = "CircuitRotation"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decodeIfPresent(Int.self, forKey: .key)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        gmtOffset = try container.decodeIfPresent(String.self, forKey: .gmtOffset)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        meeting = try container.decodeIfPresent(MeetingDetail.self, forKey: .meeting)

        // The additional fields are appended by the data service and may be absent in live traffic.
        circuitPoints = try container.decodeIfPresent([CircuitPoint].self, forKey: .circuitPoints) ?? []
        circuitCorners = try container.decodeIfPresent([CircuitCorner].self, forKey: .circuitCorners) ?? []
        circuitRotation = try container.decodeIfPresent(Int.self, forKey: .circuitRotation) ?? 0
    }
}

public struct DriverListDataPoint: Decodable {
    public let drivers: [String: Driver]

    public struct Driver: Decodable {
        public let racingNumber: String?
        public let broadcastName: String?
        public let fullName: String?
        public let tla: String?
        public let line: Int?
        public let teamName: String?
        public let teamColour: String?
        public let isSelected: Bool

        private enum CodingKeys: String, CodingKey {
            case racingNumber = "RacingNumber"
            case broadcastName = "BroadcastName"
            case fullName = "FullName"
            case tla = "Tla"
            case line = "Line"
            case teamName = "TeamName"
            case teamColour = "TeamColour"
            case isSelected = "IsSelected"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            racingNumber = try container.decodeIfPresent(String.self, forKey: .racingNumber)
            broadcastName = try container.decodeIfPresent(String.self, forKey: .broadcastName)
            fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
            tla = try container.decodeIfPresent(String.self, forKey: .tla)
            line = try container.decodeIfPresent(Int.self, forKey: .line)
            teamName = try container.decodeIfPresent(String.self, forKey: .teamName)
            teamColour = try container.decodeIfPresent(String.self, forKey: .teamColour)
            isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? true
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        drivers = try container.decode([String: Driver].self)
    }
}

public struct TimingAppDataPoint: Decodable {
    public struct Driver: Decodable {
        public struct Stint: Decodable {
            public let lapFlags: Int?
            public let compound: String?
            public let isNew: Bool?
            public let totalLaps: Int?
            public let startLaps: Int?
            public let lapTime: String?

            private enum CodingKeys: String, CodingKey {
                case lapFlags = "LapFlags"
                case compound = "Compound"
                case isNew = "New"
                case totalLaps = "TotalLaps"
                case startLaps = "StartLaps"
                case lapTime = "LapTime"
            }
        }

        public let gridPos: String?
        public let line: Int?
        public let stints: [String: Stint]

        private enum CodingKeys: String, CodingKey {
            case gridPos = "GridPos"
            case line = "Line"
            case stints = "Stints"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            gridPos = try container.decodeIfPresent(String.self, forKey: .gridPos)
            line = try container.decodeIfPresent(Int.self, forKey: .line)
            stints = try container.decodeIfPresent([String: Stint].self, forKey: .stints) ?? [:]
        }
    }

    public let lines: [String: Driver]

    private enum CodingKeys: String, CodingKey {
        case lines = "Lines"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lines = try container.decodeIfPresent([String: Driver].self, forKey: .lines) ?? [:]
    }
}

public struct CarDataPoint: Decodable {
    public struct Entry: Decodable {
        public struct Car: Decodable {
            public struct Channels: Decodable {
                public let rpm: Int?
                public let speed: Int?
                public let gear: Int?
                public let throttle: Int?
                public let brake: Int?
                public let drs: Int?

                private enum CodingKeys: String, CodingKey {
                    case rpm = "0"
                    case speed = "2"
                    case gear = "3"
                    case throttle = "4"
                    case brake = "5"
                    case drs = "45"
                }
            }

            public let channels: Channels

            private enum CodingKeys: String, CodingKey {
                case channels = "Channels"
            }
        }

        public let utc: Date
        public let cars: [String: Car]

        private enum CodingKeys: String, CodingKey {
            case utc = "Utc"
            case cars = "Cars"
        }
    }

    public let entries: [Entry]

    private enum CodingKeys: String, CodingKey {
        case entries = "Entries"
    }
}

public struct PositionDataPoint: Decodable {
    public struct PositionData: Decodable {
        public struct Entry: Decodable {
            public enum DriverStatus: String, Decodable {
                case onTrack = "OnTrack"
                case offTrack = "OffTrack"
            }

            public let status: DriverStatus?
            public let x: Int?
            public let y: Int?
            public let z: Int?

            private enum CodingKeys: String, CodingKey {
                case status = "Status"
                case x = "X"
                case y = "Y"
                case z = "Z"
            }
        }

        public let timestamp: Date
        public let entries: [String: Entry]

        private enum CodingKeys: String, CodingKey {
            case timestamp = "Timestamp"
            case entries = "Entries"
        }
    }

    public let position: [PositionData]

    private enum CodingKeys: String, CodingKey {
        case position = "Position"
    }
}

public struct RaceControlMessageDataPoint: Decodable {
    public struct Message: Decodable {
        public let utc: Date
        public let message: String

        private enum CodingKeys: String, CodingKey {
            case utc = "Utc"
            case message = "Message"
        }
    }

    public let messages: [String: Message]

    private enum CodingKeys: String, CodingKey {
        case messages = "Messages"
    }
}

// MARK: - Example SignalR wiring

#if canImport(SwiftSignalRClient)
import SwiftSignalRClient

public final class LiveTimingSignalRClient {
    private let connection: HubConnection
    private let mapper = LiveTimingFeedMapper()

    public init(connection: HubConnection) {
        self.connection = connection
        connection.on(method: "feed", callback: feed)
    }

    private func feed(topic: String, payload: [String: Any], timestampIso8601: String) {
        do {
            let envelope = try mapper.makeEnvelope(topic: topic, objectPayload: payload, isoTimestamp: timestampIso8601)
            let event = try mapper.map(envelope)
            handle(event: event)
        } catch {
            print("Failed to decode feed payload for topic \(topic): \(error)")
        }
    }

    private func handle(event: LiveTimingEvent) {
        switch event {
        case let .timingData(_, point):
            // Update timing tower rows using `point.lines`
            print("Timing update for \(point.lines.count) drivers")
        case let .lapCount(_, lapData):
            print("Lap header => \(lapData.currentLap ?? 0)/\(lapData.totalLaps ?? 0)")
        case let .driverList(_, list):
            print("Loaded \(list.drivers.count) driver metadata entries")
        case let .timingAppData(_, tyres):
            print("Tyre update for \(tyres.lines.count) drivers")
        case let .carData(_, telemetry):
            print("Received \(telemetry.entries.count) telemetry snapshots")
        case let .position(_, positions):
            print("Position batch with \(positions.position.count) timestamps")
        case let .raceControlMessages(_, messages):
            print("Race control messages: \(messages.messages.values.map(\.message))")
        default:
            break
        }
    }
}
#endif
