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
        builder.ensureConfigFileExists()
        _ = builder.bootstrap(commandLine: global.asConsoleOptions())

        Swift.print("Logging out will remove your access token stored in the config file.")
        Swift.print("To log back in again in the future, simply run undercutf1 login.")
        Swift.print()

        let configStore = ConfigFileStore()
        var config = try configStore.load()
        config.removeValue(forKey: "formula1AccessToken")
        try configStore.save(config)

        Swift.print("Logout successful. Your token has been removed from \(configStore.pathDescription).")
    }
}
