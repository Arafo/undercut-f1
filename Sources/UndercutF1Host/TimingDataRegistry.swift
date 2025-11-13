import Foundation
import UndercutF1Data

public actor TimingDataRegistry {
    public typealias LatestProvider = @Sendable () async -> AnyEncodable?
    public typealias LapHistoryProvider = @Sendable (_ lapNumber: Int) async -> AnyEncodable?
    public typealias BestLapProvider = @Sendable () async -> AnyEncodable?

    private var latestProviders: [LiveTimingDataType: LatestProvider]
    private var lapHistoryProvider: LapHistoryProvider?
    private var bestLapProvider: BestLapProvider?

    public init(
        latestProviders: [LiveTimingDataType: LatestProvider] = [:],
        lapHistoryProvider: LapHistoryProvider? = nil,
        bestLapProvider: BestLapProvider? = nil
    ) {
        self.latestProviders = latestProviders
        self.lapHistoryProvider = lapHistoryProvider
        self.bestLapProvider = bestLapProvider
    }

    public func registerLatestProvider(
        for type: LiveTimingDataType,
        provider: @escaping LatestProvider
    ) {
        latestProviders[type] = provider
    }

    public func registerLapHistory(
        provider: @escaping LapHistoryProvider,
        bestLapProvider: @escaping BestLapProvider
    ) {
        lapHistoryProvider = provider
        self.bestLapProvider = bestLapProvider
    }

    public func latest(for type: LiveTimingDataType) async -> AnyEncodable? {
        guard let provider = latestProviders[type] else { return nil }
        return await provider()
    }

    public func lap(number: Int) async -> AnyEncodable? {
        guard let provider = lapHistoryProvider else { return nil }
        return await provider(number)
    }

    public func bestLaps() async -> AnyEncodable? {
        guard let provider = bestLapProvider else { return nil }
        return await provider()
    }
}
