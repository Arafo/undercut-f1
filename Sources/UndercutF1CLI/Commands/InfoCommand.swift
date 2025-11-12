import ArgumentParser
import Foundation

struct InfoCommand: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "info",
        abstract: "Print diagnostics about undercutf1 and its terminal environment."
    )

    @OptionGroup()
    var directories: DirectoryOptions

    @OptionGroup()
    var verbose: VerboseOption

    @OptionGroup()
    var graphicsPreferences: GraphicsPreferences

    func run() throws {
        CommandHandler.getInfo(
            dataDirectory: directories.dataDirectory,
            logDirectory: directories.logDirectory,
            isVerbose: verbose.isVerbose,
            notify: graphicsPreferences.notify,
            preferFfmpeg: graphicsPreferences.preferFfmpeg,
            forcedGraphicsProtocol: graphicsPreferences.forcedGraphicsProtocol
        )
    }
}
