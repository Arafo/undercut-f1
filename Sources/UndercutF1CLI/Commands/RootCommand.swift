import ArgumentParser
import Foundation

struct RootCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(abstract: "undercutf1 root command")

    @OptionGroup()
    var global: GlobalOptions

    func run() async throws {
        let builder = ServiceContainerBuilder()
        builder.ensureConfigFileExists()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.info("Resolved configuration: data=\(services.options.dataDirectory.path), logs=\(services.options.logDirectory.path)")
        services.logger.debug("Notifications enabled: \(services.options.notify)")
        await TerminalBootstrapper(services: services).run()
    }
}
