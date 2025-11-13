import Foundation

public protocol Clipboard {
    func setText(_ text: String) async throws
}

public protocol ProcessorSnapshotProvider {
    func latestSnapshot(for index: Int) async -> String?
}

public protocol DateTimeProvider {
    var isPaused: Bool { get }
    var delay: TimeInterval { get set }
    func togglePause()
}

public protocol TimingHistoryMetricsProvider {
    var latestLapWithData: Int { get }
}

public protocol DriverSelectionProvider {
    func driverNumber(forLine line: Int) -> Int?
    func toggleSelection(for driverNumber: Int)
}

public protocol AudioPlaybackController {
    var isPlaying: Bool { get }
    var hasError: Bool { get }
    func play(fileAt url: URL)
    func stop()
}

public final class TeamRadioMessage {
    public let id: String
    public var transcription: String?

    public init(id: String, transcription: String? = nil) {
        self.id = id
        self.transcription = transcription
    }
}

public protocol TeamRadioStore: AnyObject {
    var orderedMessages: [TeamRadioMessage] { get }
    func downloadMessage(withID id: String) async throws -> URL
    func transcribeMessage(withID id: String) async throws
}

public protocol TranscriptionProvider {
    var isModelDownloaded: Bool { get }
    func ensureModelDownloaded() async throws
}

public protocol JsonTimingClient {
    func fetchDirectories() async throws -> [SimulatedSessionDirectory]
    func loadSimulationData(from directory: String) async
}

public struct SimulatedSessionDirectory {
    public let name: String
    public let sessions: [SimulatedSession]

    public init(name: String, sessions: [SimulatedSession]) {
        self.name = name
        self.sessions = sessions
    }
}

public struct SimulatedSession {
    public let directory: String
    public let label: String

    public init(directory: String, label: String) {
        self.directory = directory
        self.label = label
    }
}

public final class StartSimulatedSessionOptions {
    public var selectedLocation: Int?
    public var sessions: [SimulatedSessionDirectory]

    public init(selectedLocation: Int? = nil, sessions: [SimulatedSessionDirectory] = []) {
        self.selectedLocation = selectedLocation
        self.sessions = sessions
    }
}

public protocol SessionInfoProvider {
    var hasActiveSession: Bool { get }
}

public protocol LiveTimingClient {
    func start() async throws
}

public protocol Logger {
    func info(_ message: String)
    func error(_ message: String, error: Error?)
}
