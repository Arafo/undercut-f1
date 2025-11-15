import ArgumentParser
import Foundation
import UndercutF1Data

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

        let loader = builder.loader
        let defaults = loader.defaults
        let configPath = defaults.defaultConfigFile
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let existingValidation = Formula1Account.validate(token: services.options.formula1AccessToken)
        if existingValidation.result == .success, let payload = existingValidation.payload {
            if !Calendar.current.isDateInToday(payload.expiry) {
                services.logger.notice("An active token already exists (expires \(formatter.string(from: payload.expiry))). Run 'undercutf1 logout' to replace it early.")
                return
            }
        }

        print(
            """
            Login to your Formula 1 Account (with an active F1 TV subscription) to unlock driver tracker, pit stop times, championship tables, and radio transcription.

            A browser window will open so you can sign in. Once authenticated, copy the value of the 'login-session' cookie for formula1.com (or static.formula1.com) and paste it here when prompted. The token is stored in \(configPath.path).
            """
        )

        guard confirm("Proceed to login?") else {
            services.logger.notice("Login aborted by user request.")
            return
        }

        openLoginPage()
        guard let token = promptForToken() else {
            services.logger.error("No token supplied. Unable to complete login.")
            return
        }

        let validation = Formula1Account.validate(token: token)
        guard validation.result == .success, let payload = validation.payload else {
            services.logger.error("Invalid token received. Result: \(validation.result)")
            return
        }

        var configuration = loader.readConfigDictionary()
        configuration["formula1AccessToken"] = token
        try loader.writeConfigDictionary(configuration)

        services.logger.notice("Login successful. Token stored in \(configPath.path). Expires \(formatter.string(from: payload.expiry)).")
    }

    private func confirm(_ message: String) -> Bool {
        print("\(message) [y/N]: ", terminator: "")
        guard let response = readLine(strippingNewline: true) else { return false }
        let value = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value == "y" || value == "yes"
    }

    private func promptForToken() -> String? {
        print("Paste the login-session cookie value and press return (leave blank to cancel):", terminator: " ")
        guard let input = readLine(strippingNewline: true) else { return nil }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func openLoginPage() {
        #if os(macOS)
        let command = "/usr/bin/open"
        let arguments = ["https://account.formula1.com/#/en/login"]
        #elseif os(Linux)
        let command = "/usr/bin/xdg-open"
        let arguments = ["https://account.formula1.com/#/en/login"]
        #else
        let command = "cmd"
        let arguments = ["/c", "start", "", "https://account.formula1.com/#/en/login"]
        #endif
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        try? process.run()
    }
}
