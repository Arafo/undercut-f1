import Foundation

public struct LiveTimingOptions: Sendable {
    public var dataDirectory: URL
    public var logDirectory: URL
    public var apiEnabled: Bool
    public var verbose: Bool
    public var notify: Bool
    public var formula1AccessToken: String?

    public init(
        dataDirectory: URL = LiveTimingOptions.defaultDataDirectory(),
        logDirectory: URL = LiveTimingOptions.defaultLogDirectory(),
        apiEnabled: Bool = false,
        verbose: Bool = false,
        notify: Bool = true,
        formula1AccessToken: String? = nil
    ) {
        self.dataDirectory = dataDirectory
        self.logDirectory = logDirectory
        self.apiEnabled = apiEnabled
        self.verbose = verbose
        self.notify = notify
        self.formula1AccessToken = formula1AccessToken
    }

    public static func defaultDataDirectory() -> URL {
        #if os(Windows)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("undercut-f1/data", isDirectory: true)
        #else
        let env = ProcessInfo.processInfo.environment
        if let xdg = env["XDG_DATA_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg, isDirectory: true).appendingPathComponent("undercut-f1/data", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/undercut-f1/data", isDirectory: true)
        #endif
    }

    public static func defaultLogDirectory() -> URL {
        #if os(Windows)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("undercut-f1/logs", isDirectory: true)
        #else
        let env = ProcessInfo.processInfo.environment
        if let xdg = env["XDG_STATE_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg, isDirectory: true).appendingPathComponent("undercut-f1/logs", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/state/undercut-f1/logs", isDirectory: true)
        #endif
    }
}
