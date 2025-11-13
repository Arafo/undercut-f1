import Foundation

public final class StartSimulatedSessionInputHandler: InputHandler {
    private let jsonClient: JsonTimingClient
    private let displayOptions: StartSimulatedSessionOptions
    private let state: State

    public init(jsonClient: JsonTimingClient, displayOptions: StartSimulatedSessionOptions, state: State) {
        self.jsonClient = jsonClient
        self.displayOptions = displayOptions
        self.state = state
    }

    public var keyBindings: [KeyBinding] {
        [
            KeyBinding(key: .enter),
            KeyBinding(key: .right),
            KeyBinding(character: "l")
        ]
    }

    public var displayBindings: [KeyBinding] { [KeyBinding(key: .right)] }
    public var description: String { "Select" }
    public var applicableScreens: Set<Screen> { Set([.startSimulatedSession]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 41

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        let directories = try await jsonClient.fetchDirectories()
        displayOptions.sessions = directories

        if displayOptions.selectedLocation == nil {
            guard let directory = directories.element(at: state.cursorOffset) else { return }
            let index = directories.firstIndex { $0.name == directory.name } ?? state.cursorOffset
            displayOptions.selectedLocation = index
            state.cursorOffset = 0
            return
        }

        guard let selectedIndex = displayOptions.selectedLocation else { return }
        guard let directory = directories.element(at: selectedIndex) else { return }
        guard let session = directory.sessions.element(at: state.cursorOffset) else { return }

        await jsonClient.loadSimulationData(from: session.directory)
        state.currentScreen = .timingTower
        state.cursorOffset = 0
    }
}

public final class StartSimulatedSessionDeselectInputHandler: InputHandler {
    private let displayOptions: StartSimulatedSessionOptions
    private let state: State

    public init(displayOptions: StartSimulatedSessionOptions, state: State) {
        self.displayOptions = displayOptions
        self.state = state
    }

    public var keyBindings: [KeyBinding] {
        [
            KeyBinding(key: .left),
            KeyBinding(character: "h")
        ]
    }

    public var displayBindings: [KeyBinding] { [KeyBinding(key: .left)] }
    public var description: String { "Deselect" }
    public var applicableScreens: Set<Screen> { Set([.startSimulatedSession]) }
    public let sortIndex: Int = 42
    public var isEnabled: Bool { displayOptions.selectedLocation != nil }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        state.cursorOffset = displayOptions.selectedLocation ?? state.cursorOffset
        displayOptions.selectedLocation = nil
    }
}

public final class StartLiveSessionInputHandler: InputHandler {
    private let sessionInfo: SessionInfoProvider
    private let liveClient: LiveTimingClient
    private let state: State

    public init(sessionInfo: SessionInfoProvider, liveClient: LiveTimingClient, state: State) {
        self.sessionInfo = sessionInfo
        self.liveClient = liveClient
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "l")] }
    public var description: String { "Start Live Session" }
    public var applicableScreens: Set<Screen> { Set([.manageSession]) }
    public let sortIndex: Int = 40
    public var isEnabled: Bool { !sessionInfo.hasActiveSession }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        try await liveClient.start()
        state.currentScreen = .timingTower
        state.cursorOffset = 0
    }
}

private extension Array {
    func element(at index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
