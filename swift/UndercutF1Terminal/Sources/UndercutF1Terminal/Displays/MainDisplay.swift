import Foundation

public protocol MainDisplayDataSource {
    func loadMetadata() async throws -> MainDisplayMetadata
}

public struct MainDisplayMetadata {
    public enum AccountStatus: Equatable {
        case loggedIn(expiry: Date)
        case expiredToken(expiry: Date?)
        case needsLogin
    }

    public let accountStatus: AccountStatus
    public let currentVersion: String
    public let latestVersion: String?

    public init(accountStatus: AccountStatus, currentVersion: String, latestVersion: String? = nil) {
        self.accountStatus = accountStatus
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
    }
}

public final class MainDisplay: Display {
    public let screen: Screen = .main

    private let dataSource: MainDisplayDataSource
    private let dateFormatter: DateFormatter

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    public init(dataSource: MainDisplayDataSource, dateFormatter: DateFormatter = MainDisplay.makeDateFormatter()) {
        self.dataSource = dataSource
        self.dateFormatter = dateFormatter
    }

    public func render() async throws -> RenderNode {
        let metadata = try await dataSource.loadMetadata()
        let title = SimpleTextNode(text: Self.banner)
        let content = SimpleTextNode(text: Self.instructions(accountDetail: accountDetailText(for: metadata.accountStatus)))
        let footer = SimpleTextNode(text: footerText(currentVersion: metadata.currentVersion, latestVersion: metadata.latestVersion))
        return PanelNode(body: RowsNode(rows: [title, content, footer]))
    }

    private func accountDetailText(for status: MainDisplayMetadata.AccountStatus) -> String {
        switch status {
        case let .loggedIn(expiry):
            return "Logged in to F1 TV account. Token will expire on \(dateFormatter.string(from: expiry))."
        case let .expiredToken(expiry):
            var lines = ["Formula 1 account token has expired! Please run the following to log back in:", "> undercutf1 login"]
            if let expiry {
                lines.insert("Token expired on \(dateFormatter.string(from: expiry)).", at: 1)
            }
            return lines.joined(separator: "\n")
        case .needsLogin:
            return [
                "Some features (like Driver Tracker) require an F1 TV subscription. Run the following to login:",
                "> undercutf1 login",
                "See https://github.com/JustAman62/undercut-f1#f1-tv-account-login for details"
            ].joined(separator: "\n")
        }
    }

    private func footerText(currentVersion: String, latestVersion: String?) -> String {
        var line = "Version: \(currentVersion)"
        if let latestVersion, latestVersion != currentVersion {
            line += "  A newer version is available: \(latestVersion)"
        }
        return [
            "GitHub: https://github.com/JustAman62/undercut-f1",
            line
        ].joined(separator: "\n")
    }

    private static func instructions(accountDetail: String) -> String {
        [
            "Welcome to Undercut F1.",
            "",
            "To start a live timing session, press S then L.",
            "To replay a recorded/imported session, press S then F.",
            "",
            "Once a session is started, navigate to the Timing Tower using T.",
            "Use the arrow keys ◄/► to switch between timing pages.",
            "Use N/M/,/. to adjust the stream delay, and ▲/▼ to use the cursor.",
            "Press Shift with these keys to adjust by a higher amount.",
            "",
            "You can download old session data from Formula 1 by running:",
            "> undercutf1 import",
            "",
            accountDetail
        ].joined(separator: "\n")
    }

    private static let banner: String = [
        "   __  __  _   __  ____    ______  ____    ______  __  __  ______        ______  ___",
        "  / / / / / | / / / __ \\  / ____/ / __ \\  / ____/ / / / / /_  __/       / ____/ <  /",
        " / / / / /  |/ / / / / / / __/   / /_/ / / /     / / / /   / /         / /_     / /",
        "/ /_/ / / /|  / / /_/ / / /___  / _, _/ / /___  / /_/ /   / /         / __/    / /",
        "\\____/ /_/ |_/ /_____/ /_____/ /_/ |_|  \\____/  \\____/   /_/         /_/      /_/"
    ].joined(separator: "\n")
}
