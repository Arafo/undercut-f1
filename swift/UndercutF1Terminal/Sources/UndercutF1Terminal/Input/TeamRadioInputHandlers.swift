import Foundation

public final class PlayTeamRadioInputHandler: InputHandler {
    private let audioPlayer: AudioPlaybackController
    private let state: State
    private let store: TeamRadioStore

    public init(audioPlayer: AudioPlaybackController, state: State, store: TeamRadioStore) {
        self.audioPlayer = audioPlayer
        self.state = state
        self.store = store
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(key: .enter)] }
    public var description: String {
        if audioPlayer.isPlaying { return "[olive]⏹ Stop[/]" }
        if audioPlayer.hasError { return "[red]Playback Error[/]" }
        return "► Play Radio"
    }

    public var applicableScreens: Set<Screen> { Set([.teamRadio]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 40

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        if audioPlayer.isPlaying {
            audioPlayer.stop()
            return
        }

        guard let message = store.orderedMessages.element(at: state.cursorOffset) else { return }
        let url = try await store.downloadMessage(withID: message.id)
        audioPlayer.play(fileAt: url)
    }
}

public final class TranscribeTeamRadioInputHandler: InputHandler {
    private let state: State
    private let store: TeamRadioStore
    private let transcriptionProvider: TranscriptionProvider
    private let logger: Logger
    private var task: Task<Void, Never>? = nil
    private var lastError: Error? = nil

    public init(
        state: State,
        store: TeamRadioStore,
        transcriptionProvider: TranscriptionProvider,
        logger: Logger
    ) {
        self.state = state
        self.store = store
        self.transcriptionProvider = transcriptionProvider
        self.logger = logger
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "t")] }
    public var applicableScreens: Set<Screen> { Set([.teamRadio]) }
    public let sortIndex: Int = 41
    public var isEnabled: Bool { true }

    public var description: String {
        if let task, !task.isCompleted {
            return "[olive]Transcribing...[/]"
        }

        if lastError != nil {
            return "[red]Transcribe (Errored)[/]"
        }

        return "Transcribe"
    }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        guard transcriptionProvider.isModelDownloaded else {
            state.currentScreen = .downloadTranscription
            return
        }

        if let task, !task.isCompleted {
            logger.info("Asked to start transcribing, but already working")
            return
        }

        let index = state.cursorOffset
        lastError = nil
        task = Task { [weak self] in
            await self?.transcribeEntry(at: index)
        }
    }

    private func transcribeEntry(at index: Int) async {
        guard let message = store.orderedMessages.element(at: index) else { return }
        defer { task = nil }

        do {
            try await store.transcribeMessage(withID: message.id)
            lastError = nil
        } catch {
            let text = "Failed to transcribe team radio: \(error.localizedDescription)"
            logger.error(text, error: error)
            message.transcription = text
            lastError = error
        }
    }
}

public final class DownloadTranscriptionModelInputHandler: InputHandler {
    private let transcriptionProvider: TranscriptionProvider
    private let state: State
    private let logger: Logger
    private var task: Task<Void, Never>? = nil
    private var lastError: Error? = nil

    public init(transcriptionProvider: TranscriptionProvider, state: State, logger: Logger) {
        self.transcriptionProvider = transcriptionProvider
        self.state = state
        self.logger = logger
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(key: .enter)] }
    public var applicableScreens: Set<Screen> { Set([.downloadTranscription]) }
    public let sortIndex: Int = 40
    public var isEnabled: Bool { true }

    public var description: String {
        if let task, !task.isCompleted {
            return "[olive]Downloading, Please Wait...[/]"
        }

        if lastError != nil {
            return "[red]Error, Retry?[/]"
        }

        return "Download"
    }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        if let task, !task.isCompleted {
            logger.info("Asked to download transcription model, but already downloading")
            return
        }

        lastError = nil
        task = Task { [weak self] in
            await self?.downloadModel()
        }
    }

    private func downloadModel() async {
        defer { task = nil }
        do {
            try await transcriptionProvider.ensureModelDownloaded()
            logger.info("Transcription model downloaded")
            state.currentScreen = .teamRadio
            lastError = nil
        } catch {
            logger.error("Failed to download transcription model", error: error)
            lastError = error
        }
    }
}

private extension Array {
    func element(at index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
