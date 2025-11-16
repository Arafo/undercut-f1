import Foundation
import UndercutF1Data

struct TerminalBootstrapper {
    let services: ServiceContainer

    func run() async {
        services.logger.info("Launching terminal client with data directory: \(services.options.dataDirectory.path)")
        do {
            let runtime = try buildRuntime()
            services.logger.info("Initialised \(runtime.dependencies.processors.all.count) processors")
            services.logger.info("Live Timing topics subscribed: \(LiveTimingClient.topics.count)")
            if services.options.apiEnabled {
                services.logger.info("API host requested on port 61937 (implementation pending in Swift)")
            }
            if services.options.preferFfmpegPlayback {
                services.logger.debug("FFmpeg playback preference enabled")
            }
            if let protocolOverride = services.options.forceGraphicsProtocol {
                services.logger.debug("Graphics protocol forced to \(protocolOverride.rawValue)")
            }
            services.logger.notice("Terminal pipeline bootstrap complete. Rendering loop coming soon.")
        } catch {
            services.logger.error("Failed to initialise live timing runtime: \(error.localizedDescription)")
        }
    }

    private func buildRuntime() throws -> TerminalRuntime {
        let liveOptions = services.options.liveTimingOptions()
        let account = services.options.formula1AccessToken.map { Formula1Account(accessToken: $0) }
        let dependencies = LiveTimingDependencies(
            options: liveOptions,
            formula1Account: account,
            userAgent: "UndercutF1SwiftCLI/1.0"
        )
        return TerminalRuntime(dependencies: dependencies)
    }
}

private struct TerminalRuntime {
    let dependencies: LiveTimingDependencies
}
