import ArgumentParser
#if canImport(WinSDK)
import WinSDK
#endif

struct LoginCommand: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "login",
        abstract: "Login to your Formula 1 account to unlock all data feeds."
    )

    @OptionGroup()
    var verbose: VerboseOption

    func run() throws {
        prepareForLoginIfNeeded()
        CommandHandler.login(isVerbose: verbose.isVerbose)
    }
}

struct LogoutCommand: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "logout",
        abstract: "Logout of your Formula 1 account."
    )

    @OptionGroup()
    var verbose: VerboseOption

    func run() throws {
        _ = verbose // Accept verbose flag for parity with the .NET CLI.
        CommandHandler.logout()
    }
}

private func prepareForLoginIfNeeded() {
    #if canImport(WinSDK)
    // Swift does not currently expose a direct way to replicate the Unknown -> STA transition from .NET.
    // Calling CoInitializeEx with COINIT_APARTMENTTHREADED configures the thread for COM STA components,
    // which is required before presenting a WebView on Windows.
    _ = WinSDK.CoInitializeEx(nil, DWORD(COINIT_APARTMENTTHREADED.rawValue))
    #endif
}
