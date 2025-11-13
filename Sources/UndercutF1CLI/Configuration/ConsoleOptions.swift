import Foundation

struct ConsoleOptions: Codable, Sendable, Equatable {
    var dataDirectory: String?
    var logDirectory: String?
    var apiEnabled: Bool?
    var verbose: Bool?
    var notify: Bool?
    var formula1AccessToken: String?
    var preferFfmpegPlayback: Bool?
    var forceGraphicsProtocol: GraphicsProtocol?
    var externalPlayerSync: ExternalPlayerSyncOptions?

    init(
        dataDirectory: String? = nil,
        logDirectory: String? = nil,
        apiEnabled: Bool? = nil,
        verbose: Bool? = nil,
        notify: Bool? = nil,
        formula1AccessToken: String? = nil,
        preferFfmpegPlayback: Bool? = nil,
        forceGraphicsProtocol: GraphicsProtocol? = nil,
        externalPlayerSync: ExternalPlayerSyncOptions? = nil
    ) {
        self.dataDirectory = dataDirectory
        self.logDirectory = logDirectory
        self.apiEnabled = apiEnabled
        self.verbose = verbose
        self.notify = notify
        self.formula1AccessToken = formula1AccessToken
        self.preferFfmpegPlayback = preferFfmpegPlayback
        self.forceGraphicsProtocol = forceGraphicsProtocol
        self.externalPlayerSync = externalPlayerSync
    }

    func merging(overrides: ConsoleOptions) -> ConsoleOptions {
        ConsoleOptions(
            dataDirectory: overrides.dataDirectory ?? dataDirectory,
            logDirectory: overrides.logDirectory ?? logDirectory,
            apiEnabled: overrides.apiEnabled ?? apiEnabled,
            verbose: overrides.verbose ?? verbose,
            notify: overrides.notify ?? notify,
            formula1AccessToken: overrides.formula1AccessToken ?? formula1AccessToken,
            preferFfmpegPlayback: overrides.preferFfmpegPlayback ?? preferFfmpegPlayback,
            forceGraphicsProtocol: overrides.forceGraphicsProtocol ?? forceGraphicsProtocol,
            externalPlayerSync: externalPlayerSync?.merging(overrides: overrides.externalPlayerSync) ?? overrides.externalPlayerSync
        )
    }
}

struct ResolvedConsoleOptions: Sendable, Equatable {
    var dataDirectory: URL
    var logDirectory: URL
    var apiEnabled: Bool
    var verbose: Bool
    var notify: Bool
    var formula1AccessToken: String?
    var preferFfmpegPlayback: Bool
    var forceGraphicsProtocol: GraphicsProtocol?
    var externalPlayerSync: ExternalPlayerSyncOptions

    init(overrides: ConsoleOptions = ConsoleOptions()) {
        let defaults = ConsoleDefaults()
        dataDirectory = URL(fileURLWithPath: overrides.dataDirectory ?? defaults.defaultDataDirectory.path)
        logDirectory = URL(fileURLWithPath: overrides.logDirectory ?? defaults.defaultLogDirectory.path)
        apiEnabled = overrides.apiEnabled ?? false
        verbose = overrides.verbose ?? false
        notify = overrides.notify ?? true
        formula1AccessToken = overrides.formula1AccessToken
        preferFfmpegPlayback = overrides.preferFfmpegPlayback ?? false
        forceGraphicsProtocol = overrides.forceGraphicsProtocol
        externalPlayerSync = overrides.externalPlayerSync ?? ExternalPlayerSyncOptions()
    }
}

struct ConsoleDefaults {
    let environment: [String: String]
    let fileManager: FileManager

    init(environment: [String: String] = ProcessInfo.processInfo.environment, fileManager: FileManager = .default) {
        self.environment = environment
        self.fileManager = fileManager
    }

    var defaultConfigFile: URL { defaultConfigDirectory.appendingPathComponent("config.json", isDirectory: false) }

    var defaultConfigDirectory: URL {
#if os(Windows)
        if let appData = environment["APPDATA"], !appData.isEmpty {
            return URL(fileURLWithPath: appData).appendingPathComponent("undercut-f1", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("AppData\\Roaming\\undercut-f1", isDirectory: true)
#else
        if let xdg = environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg).appendingPathComponent("undercut-f1", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("undercut-f1", isDirectory: true)
#endif
    }

    var defaultDataDirectory: URL {
#if os(Windows)
        if let localAppData = environment["LOCALAPPDATA"], !localAppData.isEmpty {
            return URL(fileURLWithPath: localAppData)
                .appendingPathComponent("undercut-f1", isDirectory: true)
                .appendingPathComponent("data", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("AppData\\Local\\undercut-f1\\data", isDirectory: true)
#else
        if let xdg = environment["XDG_DATA_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg)
                .appendingPathComponent("undercut-f1", isDirectory: true)
                .appendingPathComponent("data", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("share", isDirectory: true)
            .appendingPathComponent("undercut-f1", isDirectory: true)
            .appendingPathComponent("data", isDirectory: true)
#endif
    }

    var defaultLogDirectory: URL {
#if os(Windows)
        if let localAppData = environment["LOCALAPPDATA"], !localAppData.isEmpty {
            return URL(fileURLWithPath: localAppData)
                .appendingPathComponent("undercut-f1", isDirectory: true)
                .appendingPathComponent("logs", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("AppData\\Local\\undercut-f1\\logs", isDirectory: true)
#else
        if let xdg = environment["XDG_STATE_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg)
                .appendingPathComponent("undercut-f1", isDirectory: true)
                .appendingPathComponent("logs", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("state", isDirectory: true)
            .appendingPathComponent("undercut-f1", isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
#endif
    }
}
