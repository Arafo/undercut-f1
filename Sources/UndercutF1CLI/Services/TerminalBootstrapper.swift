import Foundation

struct TerminalBootstrapper {
    let services: ServiceContainer

    func run() async {
        services.logger.info("Launching terminal client with data directory: \(services.options.dataDirectory.path)")
        if services.options.apiEnabled {
            services.logger.info("API host requested on port 61937")
        }
        if services.options.preferFfmpegPlayback {
            services.logger.debug("FFmpeg playback preference enabled")
        }
        if let protocolOverride = services.options.forceGraphicsProtocol {
            services.logger.debug("Graphics protocol forced to \(protocolOverride.rawValue)")
        }
        services.logger.notice("Swift terminal client pipeline is not yet implemented. This command currently performs start-up validation only.")
    }
}
