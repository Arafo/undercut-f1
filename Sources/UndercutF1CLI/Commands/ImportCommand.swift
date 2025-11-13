import ArgumentParser
import Foundation

struct ImportCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import data from the F1 Live Timing API"
    )

    @OptionGroup()
    var global: GlobalOptions

    @Argument(help: "The year the meeting took place")
    var year: Int

    @Option(name: .customLong("meeting-key"), help: "Meeting key to inspect")
    var meetingKey: Int?

    @Option(name: .customLong("session-key"), help: "Session key to import")
    var sessionKey: Int?

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.info("Preparing import pipeline for year=\(year) meeting=\(meetingKey?.description ?? "*") session=\(sessionKey?.description ?? "*")")
        services.logger.notice("Swift data importer is not yet implemented. No remote calls were made.")
    }
}
