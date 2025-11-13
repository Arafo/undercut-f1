import ArgumentParser
import Foundation

struct LoginCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Login to your Formula 1 account"
    )

    @OptionGroup()
    var global: GlobalOptions

    func run() async throws {
        let builder = ServiceContainerBuilder()
        builder.ensureConfigFileExists()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.notice("Login flow is not yet implemented in Swift. Use the .NET client for authentication.")
    }
}
