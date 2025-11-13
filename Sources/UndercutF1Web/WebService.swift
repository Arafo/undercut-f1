import Vapor
import UndercutF1Data
import UndercutF1Host

public final class WebService {
    private var application: Application?
    private let environment: Environment

    public static let defaultLatestTypes: [LiveTimingDataType] = [
        .driverList,
        .extrapolatedClock,
        .heartbeat,
        .lapCount,
        .raceControlMessages,
        .sessionInfo,
        .timingAppData,
        .timingData,
        .trackStatus,
        .weatherData
    ]

    public init(environment: Environment = .development) {
        self.environment = environment
    }

    public func start(
        configuration: WebServiceConfiguration,
        services: ApplicationServices,
        latestTypes: [LiveTimingDataType] = WebService.defaultLatestTypes
    ) async throws {
        guard configuration.isEnabled else { return }
        guard application == nil else { return }

        let app = Application(environment)
        app.http.server.configuration.hostname = configuration.hostname
        app.http.server.configuration.port = configuration.port
        configureContent(on: app)

        ControlRoutes.register(on: app, services: services)
        TimingRoutes.register(on: app, services: services, latestTypes: latestTypes)

        try app.start()
        application = app
    }

    public func shutdown() {
        application?.shutdown()
        application = nil
    }

    deinit {
        shutdown()
    }

    private func configureContent(on app: Application) {
        var configuration = ContentConfiguration()
        configuration.use(encoder: JSONCoders.encoder, for: .json)
        configuration.use(decoder: JSONCoders.decoder, for: .json)
        app.contentConfiguration = configuration
    }
}
