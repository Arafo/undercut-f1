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
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())

        var configuration = builder.loader.readConfigDictionary()
        guard configuration.removeValue(forKey: "formula1AccessToken") != nil else {
            services.logger.notice("No Formula 1 access token found in the config file.")
            return
        }

        try builder.loader.writeConfigDictionary(configuration)
        services.logger.notice("Logout successful. Token removed from \(builder.loader.defaults.defaultConfigFile.path).")
    }
}
