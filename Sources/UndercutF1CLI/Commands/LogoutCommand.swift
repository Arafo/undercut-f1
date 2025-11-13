import ArgumentParser
import Foundation

struct LogoutCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Logout of your Formula 1 account"
    )

    @OptionGroup()
    var global: GlobalOptions

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.notice("Logout flow is not yet implemented in Swift. Remove the token from the config file manually.")
    }
}
