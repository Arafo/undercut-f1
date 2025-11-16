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

        let configStore = ConfigFileStore()
        let validator = Formula1TokenValidator()
        let configPath = configStore.pathDescription

        let existingResult = validator.validate(token: services.options.formula1AccessToken)
        if case let .success = existingResult.status,
           let payload = existingResult.payload,
           !Calendar.current.isDate(payload.expiryDate, inSameDayAs: Date()) {
            Swift.print()
            Swift.print("An access token is already configured in \(configPath).")
            Swift.print(payloadDescription(payload))
            Swift.print("This token will expire on \(format(date: payload.expiryDate)), at which point you'll need to login again.")
            Swift.print("If you'd like to log in again, please first logout using undercutf1 logout.")
            return
        }

        Swift.print(loginPreamble(configPath: configPath))
        guard confirm("Proceed to login?", defaultValue: false) else { return }

        Swift.print("Opening the Formula 1 login page in your browser...")
        launchBrowser()
        Swift.print()
        Swift.print("Once logged in, open your browser's developer tools, copy the login-session cookie value, and paste it below.")
        Swift.print("(See README instructions if you need a refresher.)")
        Swift.print()

        guard let token = prompt("Paste the login-session cookie value"), !token.isEmpty else {
            throw ExitCode(1)
        }

        let result = validator.validate(token: token)
        guard result.status == .success, let payload = result.payload else {
            Swift.print()
            Swift.print("Invalid token received from login. Please ensure the account has an active F1 TV subscription and try again.")
            Swift.print("Auth result: \(result.status)")
            if let payload = result.payload {
                Swift.print(payloadDescription(payload))
            }
            throw ExitCode(1)
        }

        var config = try configStore.load()
        config["formula1AccessToken"] = token
        try configStore.save(config)

        Swift.print()
        Swift.print("Login successful. Your access token has been saved in \(configPath).")
        Swift.print("This token will expire on \(format(date: payload.expiryDate)), at which point you'll need to login again.")
    }

    private func loginPreamble(configPath: String) -> String {
        """
        Login to your Formula 1 Account (which has any level of F1 TV subscription) to access all the Live Timing feeds and unlock all features of undercut-f1.

        An account is NOT needed for undercut-f1 to function, it only unlocks the following features:
        - Driver Tracker (live position of cars on track)
        - Pit Stop times
        - Championship tables with live prediction
        - DRS active indicator on Timing Screen

        Additionally, logging in is NOT required if you import data for already completed sessions, as all data is always available after a session is complete.

        Once logged in, your access token will be stored in \(configPath). Your actual account credentials will not be stored anywhere.
        Simply remove the token entry from the file, or run undercutf1 logout to prevent undercut-f1 from using your token.
        """
    }

    private func confirm(_ prompt: String, defaultValue: Bool) -> Bool {
        let suffix = defaultValue ? "[Y/n]" : "[y/N]"
        let response = readLine(prompt: "\(prompt) \(suffix) ")?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let response, !response.isEmpty else { return defaultValue }
        return ["y", "yes"].contains(response.lowercased())
    }

    private func prompt(_ message: String) -> String? {
        readLine(prompt: "\(message): ")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func payloadDescription(_ payload: Formula1TokenValidator.TokenPayload) -> String {
        "Token expires on \(format(date: payload.expiryDate)) with subscription status \(payload.subscriptionStatus)."
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func readLine(prompt: String) -> String? {
        Swift.print(prompt, terminator: "")
        return Swift.readLine()
    }

    private func launchBrowser() {
        let url = "https://account.formula1.com/#/en/login"
        #if os(macOS)
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [url]
        try? process.run()
        #elseif os(Linux)
        let process = Process()
        process.launchPath = "/usr/bin/xdg-open"
        process.arguments = [url]
        try? process.run()
        #elseif os(Windows)
        let process = Process()
        process.launchPath = "cmd.exe"
        process.arguments = ["/c", "start", "", url]
        try? process.run()
        #endif
    }
}
