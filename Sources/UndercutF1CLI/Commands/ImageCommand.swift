import ArgumentParser
import Foundation

struct ImageCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "image",
        abstract: "Display an image in the terminal"
    )

    @OptionGroup()
    var global: GlobalOptions

    @Argument(help: "Path to the image file")
    var file: String

    @Argument(help: "Graphics protocol to use")
    var graphicsProtocol: GraphicsProtocol

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        let url = URL(fileURLWithPath: file)
        services.logger.info("Requested image render using \(graphicsProtocol.rawValue) for file \(url.path)")

        let renderer = ImageRenderer()
        do {
            try renderer.render(file: url, using: graphicsProtocol)
        } catch {
            services.logger.error("Failed to render image: \(error.localizedDescription)")
            throw error
        }
    }
}
