import ArgumentParser
import Foundation

struct ImportCommand: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "import",
        abstract: "Imports data from the F1 Live Timing API for offline replay."
    )

    @Argument(help: "The year the meeting took place.")
    var year: Int

    @Option(name: [.customLong("meeting-key"), .customLong("meeting"), .short], help: "The Meeting Key of the session to import")
    var meetingKey: Int?

    @Option(name: [.customLong("session-key"), .customLong("session"), .short], help: "The Session Key inside the meeting to import")
    var sessionKey: Int?

    @OptionGroup()
    var directories: DirectoryOptions

    @OptionGroup()
    var verbose: VerboseOption

    func run() throws {
        CommandHandler.importSession(
            year: year,
            meetingKey: meetingKey,
            sessionKey: sessionKey,
            dataDirectory: directories.dataDirectory,
            logDirectory: directories.logDirectory,
            isVerbose: verbose.isVerbose
        )
    }
}
