import ArgumentParser
import Foundation

struct ImageCommand: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "image",
        abstract: "Display an image in the terminal using the provided graphics protocol."
    )

    @Argument(help: "The path to the image file to render.")
    var filePath: String

    @Argument(help: "The graphics protocol to use.")
    var graphicsProtocol: GraphicsProtocol

    @OptionGroup()
    var verbose: VerboseOption

    func run() throws {
        CommandHandler.outputImage(
            filePath: filePath,
            graphicsProtocol: graphicsProtocol,
            isVerbose: verbose.isVerbose
        )
    }
}
