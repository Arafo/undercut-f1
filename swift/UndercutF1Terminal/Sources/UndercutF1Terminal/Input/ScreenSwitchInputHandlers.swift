import Foundation

public final class SwitchToTimingTowerInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "t")] }
    public var description: String { "Timing Tower" }
    public var applicableScreens: Set<Screen> { Set([.main, .manageSession]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 61

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .timingTower
        state.cursorOffset = 0
    }
}

public final class SwitchToInfoInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "i")] }
    public var description: String { "Info" }
    public var applicableScreens: Set<Screen> { Set([.main]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 63

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .info
        state.cursorOffset = 0
    }
}

public final class SwitchToLogsInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "l")] }
    public var description: String { "Logs" }
    public var applicableScreens: Set<Screen> { Set([.main]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 62

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .logs
        state.cursorOffset = 0
    }
}

public final class SwitchToSessionInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "s")] }
    public var description: String { "Manage Session" }
    public var applicableScreens: Set<Screen> { Set([.main]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 64

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .manageSession
        state.cursorOffset = 0
    }
}

public final class SwitchToDriverSelectInputHandler: InputHandler {
    private let state: State

    public init(state: State) {
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "d")] }
    public var description: String { "Select Drivers" }
    public var applicableScreens: Set<Screen> { Set([.driverTracker, .timingHistory]) }
    public var isEnabled: Bool { true }
    public let sortIndex: Int = 69

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .selectDriver
        state.cursorOffset = 1
    }
}

public final class SwitchToStartSimulatedSessionInputHandler: InputHandler {
    private let sessionInfo: SessionInfoProvider
    private let jsonClient: JsonTimingClient
    private let displayOptions: StartSimulatedSessionOptions
    private let state: State

    public init(
        sessionInfo: SessionInfoProvider,
        jsonClient: JsonTimingClient,
        displayOptions: StartSimulatedSessionOptions,
        state: State
    ) {
        self.sessionInfo = sessionInfo
        self.jsonClient = jsonClient
        self.displayOptions = displayOptions
        self.state = state
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "f")] }
    public var description: String { "Start Simulated Session" }
    public var applicableScreens: Set<Screen> { Set([.manageSession]) }
    public let sortIndex: Int = 65
    public var isEnabled: Bool { !sessionInfo.hasActiveSession }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        displayOptions.sessions = try await jsonClient.fetchDirectories()
        state.currentScreen = .startSimulatedSession
        state.cursorOffset = 0
    }
}

public final class SwitchToDebugInputHandler: InputHandler {
    private let state: State
    private let isVerbose: () -> Bool

    public init(state: State, isVerbose: @escaping () -> Bool) {
        self.state = state
        self.isVerbose = isVerbose
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(character: "d")] }
    public var description: String { "Debug View" }
    public var applicableScreens: Set<Screen> { [.main] }
    public let sortIndex: Int = 68
    public var isEnabled: Bool { isVerbose() }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        await terminal.clearScreen(mode: .full)
        state.currentScreen = .debug
        state.cursorOffset = 0
    }
}
