import ArgumentParser
import Foundation

struct GlobalOptions: ParsableArguments {
    @Option(name: .customLong("with-api"), help: "Whether the API endpoint should be exposed at http://localhost:61937")
    var apiEnabled: Bool?

    @Option(name: .customLong("data-directory"), help: "The directory for timing data import/export")
    var dataDirectory: String?

    @Option(name: .customLong("log-directory"), help: "The directory where logs will be written")
    var logDirectory: String?

    @Option(name: .customLong("verbose"), help: "Whether verbose logging should be enabled")
    var verbose: Bool?

    @Option(name: .customLong("notify"), help: "Whether audible BEL notifications are emitted for race control updates")
    var notify: Bool?

    @Option(name: .customLong("prefer-ffmpeg"), help: "Prefer ffplay for Team Radio playback")
    var preferFfmpeg: Bool?

    @Option(name: .customLong("force-graphics-protocol"), help: "Force a graphics protocol for terminal rendering")
    var forceGraphicsProtocol: GraphicsProtocol?

    @Option(name: .customLong("external-sync-enabled"), help: "Enable external media player synchronisation")
    var externalSyncEnabled: Bool?

    @Option(name: .customLong("external-sync-service"), help: "External sync service type (e.g. Kodi)")
    var externalSyncService: ExternalSyncServiceType?

    @Option(name: .customLong("external-sync-url"), help: "External sync service base URL")
    var externalSyncURL: URL?

    @Option(name: .customLong("external-sync-interval"), help: "External sync WebSocket retry interval (ms)")
    var externalSyncInterval: Int?

    func asConsoleOptions() -> ConsoleOptions {
        var sync = ExternalPlayerSyncOptions()
        sync.enabled = externalSyncEnabled
        sync.serviceType = externalSyncService
        sync.url = externalSyncURL
        sync.webSocketConnectInterval = externalSyncInterval

        return ConsoleOptions(
            dataDirectory: dataDirectory,
            logDirectory: logDirectory,
            apiEnabled: apiEnabled,
            verbose: verbose,
            notify: notify,
            preferFfmpegPlayback: preferFfmpeg,
            forceGraphicsProtocol: forceGraphicsProtocol,
            externalPlayerSync: sync
        )
    }
}
