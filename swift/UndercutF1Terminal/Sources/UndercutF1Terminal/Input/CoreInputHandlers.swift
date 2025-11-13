import Foundation

public final class EscapeInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] {
        if state.currentScreen == .main {
            return [
                KeyBinding(character: "q"),
                KeyBinding(character: "x"),
                KeyBinding(key: .controlC)
            ]
        }

        return [
            KeyBinding(key: .escape),
            KeyBinding(key: .controlC),
            KeyBinding(key: .backspace)
        ]
    }

    public var displayBindings: [KeyBinding] {
        if state.currentScreen == .main {
            return [KeyBinding(character: "q")]
        }
        return [KeyBinding(key: .escape)]
    }

    public var description: String {
        state.currentScreen == .main ? "Quit" : "Back"
    }

    public let applicableScreens: Set<Screen> = Set(Screen.allCases)
    public let sortIndex: Int = 1
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)

        switch state.currentScreen {
        case .main:
            state.currentScreen = .shutdown
        case .startSimulatedSession:
            state.currentScreen = .manageSession
        case .downloadTranscription:
            state.currentScreen = .teamRadio
        case .selectDriver:
            state.currentScreen = state.previousScreen
        default:
            state.currentScreen = .main
        }

        state.cursorOffset = 0
    }
}

public final class CursorInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] {
        [
            KeyBinding(key: .up),
            KeyBinding(character: "k"),
            KeyBinding(key: .down),
            KeyBinding(character: "j")
        ]
    }

    public var displayBindings: [KeyBinding] {
        [KeyBinding(key: .up), KeyBinding(key: .down)]
    }

    public var description: String { "Cursor \(state.cursorOffset)" }
    public let applicableScreens: Set<Screen> = Set(Screen.allCases)
    public let sortIndex: Int = 21
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        let direction: Int
        switch keyInfo.key {
        case .down, .character("j"), .character("J"):
            direction = 1
        default:
            direction = -1
        }

        var changeBy = direction
        if keyInfo.modifiers.contains(.shift) {
            changeBy *= 5
        }

        state.cursorOffset += changeBy
        if state.cursorOffset < 0 {
            state.cursorOffset = 0
        }
    }
}

public final class DelayInputHandler: InputHandler {
    private let dateTimeProvider: DateTimeProvider

    public init(dateTimeProvider: DateTimeProvider) {
        self.dateTimeProvider = dateTimeProvider
    }

    public var keyBindings: [KeyBinding] {
        [
            KeyBinding(character: "n"),
            KeyBinding(character: "m"),
            KeyBinding(character: ",", modifiers: [.control]),
            KeyBinding(character: ".", modifiers: [.control])
        ]
    }

    public var displayBindings: [KeyBinding] {
        [KeyBinding(character: "n"), KeyBinding(character: "m")]
    }

    public var description: String { "Delay" }

    public var isEnabled: Bool { !dateTimeProvider.isPaused }

    public let sortIndex: Int = 22

    public var applicableScreens: Set<Screen> {
        Set([
            .manageSession,
            .raceControl,
            .driverTracker,
            .timingTower,
            .timingHistory,
            .tyreStint,
            .debug
        ])
    }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        guard case let .character(character) = keyInfo.key else { return }
        let normalized = String(character).lowercased()

        switch normalized {
        case "n":
            updateDelay(direction: -1, modifiers: keyInfo.modifiers)
        case "m":
            updateDelay(direction: 1, modifiers: keyInfo.modifiers)
        case ",":
            updateDelay(direction: -1, modifiers: [.control])
        case ".":
            updateDelay(direction: 1, modifiers: [.control])
        default:
            break
        }
    }

    private func updateDelay(direction: Int, modifiers: KeyInfo.Modifier) {
        let step: TimeInterval
        if modifiers.contains(.shift) {
            step = 30
        } else if modifiers.contains(.control) {
            step = 1
        } else {
            step = 5
        }

        let delta = TimeInterval(direction) * step
        var updated = dateTimeProvider.delay + delta
        if updated < 0 { updated = 0 }
        dateTimeProvider.delay = updated
    }
}

public final class PauseClockInputHandler: InputHandler {
    private let dateTimeProvider: DateTimeProvider

    public init(dateTimeProvider: DateTimeProvider) {
        self.dateTimeProvider = dateTimeProvider
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "p")] }
    public var description: String {
        dateTimeProvider.isPaused ? "[olive]Resume Clock[/]" : "Pause Clock"
    }

    public var applicableScreens: Set<Screen> {
        Set([
            .manageSession,
            .raceControl,
            .driverTracker,
            .timingTower,
            .timingHistory,
            .tyreStint
        ])
    }

    public let sortIndex: Int = 23
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        dateTimeProvider.togglePause()
    }
}

public final class SwitchPageInputHandler: InputHandler {
    private let state: State
    private let metrics: TimingHistoryMetricsProvider
    private let screens: [Screen]

    public init(
        state: State,
        metrics: TimingHistoryMetricsProvider,
        screens: [Screen] = [
            .raceControl,
            .teamRadio,
            .driverTracker,
            .timingTower,
            .timingHistory,
            .tyreStint,
            .sessionStats
        ]
    ) {
        self.state = state
        self.metrics = metrics
        self.screens = screens
    }

    public var keyBindings: [KeyBinding] {
        [
            KeyBinding(key: .left),
            KeyBinding(character: "h"),
            KeyBinding(key: .right),
            KeyBinding(character: "l")
        ]
    }

    public var displayBindings: [KeyBinding] {
        [KeyBinding(key: .left), KeyBinding(key: .right)]
    }

    public var description: String {
        let index = currentIndex()
        return "Page \(index + 1)"
    }

    public var applicableScreens: Set<Screen> { Set(screens) }
    public let sortIndex: Int = 20
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)

        let index = currentIndex()
        let nextIndex: Int
        switch keyInfo.key {
        case .left, .character("h"), .character("H"):
            nextIndex = index - 1
        default:
            nextIndex = index + 1
        }

        let wrapped = ((nextIndex % screens.count) + screens.count) % screens.count
        state.currentScreen = screens[wrapped]

        switch state.currentScreen {
        case .timingHistory:
            let latestLap = max(metrics.latestLapWithData - 1, 1)
            state.cursorOffset = max(0, latestLap)
        case .timingTower, .raceControl, .driverTracker, .teamRadio, .tyreStint, .sessionStats:
            state.cursorOffset = 0
        default:
            break
        }
    }

    private func currentIndex() -> Int {
        screens.firstIndex(of: state.currentScreen) ?? 0
    }
}

public final class CopyToClipboardInputHandler: InputHandler {
    private let clipboard: Clipboard
    private let snapshotProvider: ProcessorSnapshotProvider
    private let state: State

    public init(clipboard: Clipboard, snapshotProvider: ProcessorSnapshotProvider, state: State) {
        self.clipboard = clipboard
        self.snapshotProvider = snapshotProvider
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "c")] }
    public var description: String { "Copy To Clipboard" }
    public var applicableScreens: Set<Screen> { [.debug] }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 40

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        guard let text = await snapshotProvider.latestSnapshot(for: state.cursorOffset) else { return }
        try await clipboard.setText(text)
    }
}

public final class LogDisplayInputHandler: InputHandler {
    private let options: LogDisplayOptions

    public init(options: LogDisplayOptions) {
        self.options = options
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "m")] }
    public var description: String { "Log Level: \(options.minimumLogLevel)" }
    public var applicableScreens: Set<Screen> { [.logs] }
    public let sortIndex: Int = 20
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        options.minimumLogLevel = nextLevel(after: options.minimumLogLevel)
    }

    private func nextLevel(after level: LogEntry.Level) -> LogEntry.Level {
        switch level {
        case .debug:
            return .information
        case .information:
            return .warning
        case .warning:
            return .error
        default:
            return .debug
        }
    }
}
