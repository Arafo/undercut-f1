import ArgumentParser
import Foundation

struct InfoCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Print diagnostics about undercutf1"
    )

    @OptionGroup()
    var global: GlobalOptions

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.info("Collecting terminal diagnostics")
        services.logger.notice("Info display rendering is not yet implemented in Swift. Logging resolved configuration instead.")
        services.logger.info("Verbose: \(services.options.verbose) Notify: \(services.options.notify) FFMPEG: \(services.options.preferFfmpegPlayback)")
        if let forced = services.options.forceGraphicsProtocol {
            services.logger.info("Forced graphics protocol: \(forced.rawValue)")
        }
    }
}
