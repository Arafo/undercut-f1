import Foundation

public struct LiveTimingProcessorCatalog: @unchecked Sendable {
    public let heartbeat: HeartbeatProcessor
    public let lapCount: LapCountProcessor
    public let timingApp: TimingAppDataProcessor
    public let trackStatus: TrackStatusProcessor
    public let weather: WeatherProcessor
    public let championshipPrediction: ChampionshipPredictionProcessor
    public let timingStats: TimingStatsProcessor
    public let pitStopSeries: PitStopSeriesProcessor
    public let pitLaneTimeCollection: PitLaneTimeCollectionProcessor
    public let carData: CarDataProcessor
    public let driverList: DriverListProcessor
    public let position: PositionDataProcessor
    public let sessionInfo: SessionInfoProcessor
    public let raceControlMessages: RaceControlMessageProcessor
    public let teamRadio: TeamRadioProcessor
    public let timingData: TimingDataProcessor
    public let extrapolatedClock: ExtrapolatedClockProcessor

    public var all: [TimingProcessor] {
        [
            heartbeat,
            lapCount,
            timingApp,
            trackStatus,
            weather,
            championshipPrediction,
            timingStats,
            pitStopSeries,
            pitLaneTimeCollection,
            carData,
            driverList,
            position,
            sessionInfo,
            raceControlMessages,
            teamRadio,
            timingData,
            extrapolatedClock
        ]
    }

    public init(
        dateTimeProvider: DateTimeProviding,
        notifyService: NotifyService,
        httpClientFactory: HTTPClientFactory,
        transcriptionProvider: TranscriptionProviding,
        sessionLogger: SessionInfoLogging = ConsoleSessionLogger()
    ) {
        heartbeat = HeartbeatProcessor()
        lapCount = LapCountProcessor()
        timingApp = TimingAppDataProcessor()
        trackStatus = TrackStatusProcessor()
        weather = WeatherProcessor()
        championshipPrediction = ChampionshipPredictionProcessor()
        timingStats = TimingStatsProcessor()
        pitStopSeries = PitStopSeriesProcessor()
        pitLaneTimeCollection = PitLaneTimeCollectionProcessor()
        carData = CarDataProcessor()
        driverList = DriverListProcessor()
        position = PositionDataProcessor()
        sessionInfo = SessionInfoProcessor(httpClientFactory: httpClientFactory, logger: sessionLogger)
        raceControlMessages = RaceControlMessageProcessor(notifyService: notifyService)
        teamRadio = TeamRadioProcessor(
            sessionInfoProcessor: sessionInfo,
            transcriptionProvider: transcriptionProvider,
            httpClientFactory: httpClientFactory
        )
        timingData = TimingDataProcessor()
        extrapolatedClock = ExtrapolatedClockProcessor(dateTimeProvider: dateTimeProvider)
    }
}
