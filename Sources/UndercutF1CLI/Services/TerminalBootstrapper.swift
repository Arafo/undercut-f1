import Foundation
import UndercutF1Data

struct TerminalBootstrapper {
    let services: ServiceContainer

    func run() async {
        services.logger.info("Launching terminal client with data directory: \(services.options.dataDirectory.path)")
        var apiHost: APIHost?
        var liveTiming: LiveTimingDependencies?
        if services.options.apiEnabled {
            services.logger.info("API host requested on port 61937")
            var liveOptions = services.options.liveTimingOptions()
            liveOptions.apiEnabled = true
            let dependencies = LiveTimingDependencies(options: liveOptions)
            dependencies.timingService.start()
            liveTiming = dependencies
            let context = APIContext(
                dateTimeProvider: dependencies.dateTimeProvider,
                sessionInfoProcessor: dependencies.processors.sessionInfo,
                timingDataProcessor: dependencies.processors.timingData,
                timingService: dependencies.timingService
            )
            let host = APIHost(context: context, logger: services.logger)
            do {
                try host.start()
                apiHost = host
            } catch {
                services.logger.error("Failed to start API host: \(error.localizedDescription)")
            }
        }
        if services.options.preferFfmpegPlayback {
            services.logger.debug("FFmpeg playback preference enabled")
        }
        if let protocolOverride = services.options.forceGraphicsProtocol {
            services.logger.debug("Graphics protocol forced to \(protocolOverride.rawValue)")
        }
        services.logger.notice("Swift terminal client pipeline is not yet implemented. This command currently performs start-up validation only.")
        if let apiHost {
            services.logger.notice("API host active on http://127.0.0.1:\(APIHost.defaultPort). Press Ctrl+C to exit.")
            do {
                try await withTaskCancellationHandler {
                    try await apiHost.run()
                } onCancel: {
                    Task { await apiHost.shutdown() }
                }
            } catch {
                services.logger.error("API host exited with error: \(error.localizedDescription)")
            }
            await apiHost.shutdown()
        }
        liveTiming?.timingService.stop()
    }
}

private extension ResolvedConsoleOptions {
    func liveTimingOptions() -> LiveTimingOptions {
        LiveTimingOptions(
            dataDirectory: dataDirectory,
            logDirectory: logDirectory,
            apiEnabled: apiEnabled,
            verbose: verbose,
            notify: notify,
            formula1AccessToken: formula1AccessToken
        )
    }
}
