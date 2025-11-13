import Foundation
import Logging

struct ServiceContainer: Sendable {
    let options: ResolvedConsoleOptions
    let logger: Logger
    let clipboard: Clipboard
    let httpClient: URLSession

    init(options: ResolvedConsoleOptions, logger: Logger, clipboard: Clipboard, httpClient: URLSession) {
        self.options = options
        self.logger = logger
        self.clipboard = clipboard
        self.httpClient = httpClient
    }
}

struct ServiceContainerBuilder {
    let loader: ConfigurationLoader

    init(loader: ConfigurationLoader = ConfigurationLoader()) {
        self.loader = loader
    }

    func bootstrap(commandLine: ConsoleOptions) -> ServiceContainer {
        let resolved = loader.mergedOptions(commandLine: commandLine)

        let loggingLevel: Logger.Level = resolved.verbose ? .debug : .info
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = loggingLevel
            return handler
        }
        var logger = Logger(label: "dev.justaman.undercutf1.cli")
        logger.logLevel = loggingLevel

        let clipboard = SystemClipboard()
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "UndercutF1SwiftCLI/1.0"
        ]
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration)

        return ServiceContainer(options: resolved, logger: logger, clipboard: clipboard, httpClient: session)
    }

    func ensureConfigFileExists() {
        let schema = URL(string: "https://raw.githubusercontent.com/JustAman62/undercut-f1/refs/heads/master/config.schema.json")!
        do {
            try loader.ensureConfigFileExists(schemaURL: schema)
        } catch {
            var logger = Logger(label: "dev.justaman.undercutf1.cli")
            logger.error("Failed to write default configuration: \(error.localizedDescription)")
        }
    }
}
