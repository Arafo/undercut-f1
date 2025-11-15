import Foundation

struct ConfigurationLoader {
    let fileManager: FileManager
    let defaults: ConsoleDefaults

    init(fileManager: FileManager = .default, defaults: ConsoleDefaults = ConsoleDefaults()) {
        self.fileManager = fileManager
        self.defaults = defaults
    }

    func loadFileOptions() -> ConsoleOptions {
        let url = defaults.defaultConfigFile
        guard fileManager.fileExists(atPath: url.path) else {
            return ConsoleOptions()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(ConsoleOptions.self, from: data)
        } catch {
            return ConsoleOptions()
        }
    }

    func environmentOptions() -> ConsoleOptions {
        let env = defaults.environment

        func bool(for key: String) -> Bool? {
            guard let value = env[key] else { return nil }
            return Bool(value) ?? (value as NSString).boolValue
        }

        func int(for key: String) -> Int? {
            guard let value = env[key] else { return nil }
            return Int(value)
        }

        var options = ConsoleOptions()
        options.apiEnabled = bool(for: "UNDERCUTF1_APIENABLED")
        options.verbose = bool(for: "UNDERCUTF1_VERBOSE")
        options.notify = bool(for: "UNDERCUTF1_NOTIFY")
        options.dataDirectory = env["UNDERCUTF1_DATADIRECTORY"]
        options.logDirectory = env["UNDERCUTF1_LOGDIRECTORY"]
        options.preferFfmpegPlayback = bool(for: "UNDERCUTF1_PREFERFFMPEGPLAYBACK")
        if let protocolValue = env["UNDERCUTF1_FORCEGRAPHICSPROTOCOL"],
           let protocolOption = GraphicsProtocol(argument: protocolValue) {
            options.forceGraphicsProtocol = protocolOption
        }

        var sync = ExternalPlayerSyncOptions()
        sync.enabled = bool(for: "UNDERCUTF1_EXTERNALPLAYERSYNC__ENABLED")
        if let service = env["UNDERCUTF1_EXTERNALPLAYERSYNC__SERVICETYPE"],
           let serviceType = ExternalSyncServiceType(argument: service) {
            sync.serviceType = serviceType
        }
        if let urlString = env["UNDERCUTF1_EXTERNALPLAYERSYNC__URL"], let url = URL(string: urlString) {
            sync.url = url
        }
        sync.webSocketConnectInterval = int(for: "UNDERCUTF1_EXTERNALPLAYERSYNC__WEBSOCKETCONNECTINTERVAL")
        options.externalPlayerSync = sync
        return options
    }

    func mergedOptions(commandLine: ConsoleOptions) -> ResolvedConsoleOptions {
        let fileOptions = loadFileOptions()
        let envOptions = environmentOptions()
        let combined = fileOptions
            .merging(overrides: envOptions)
            .merging(overrides: commandLine)
        return ResolvedConsoleOptions(overrides: combined)
    }

    func ensureConfigFileExists(schemaURL: URL) throws {
        let configDirectory = defaults.defaultConfigDirectory
        if !fileManager.fileExists(atPath: configDirectory.path) {
            try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        }

        let configPath = defaults.defaultConfigFile
        guard !fileManager.fileExists(atPath: configPath.path) else { return }

        let template = ["$schema": schemaURL.absoluteString]
        let data = try JSONSerialization.data(withJSONObject: template, options: [.prettyPrinted])
        try data.write(to: configPath, options: [.atomic])
    }

    func readConfigDictionary() -> [String: Any] {
        let configPath = defaults.defaultConfigFile
        guard fileManager.fileExists(atPath: configPath.path) else { return [:] }
        do {
            let data = try Data(contentsOf: configPath)
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            return object as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }

    func writeConfigDictionary(_ dictionary: [String: Any]) throws {
        let configPath = defaults.defaultConfigFile
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: configPath, options: [.atomic])
    }
}
