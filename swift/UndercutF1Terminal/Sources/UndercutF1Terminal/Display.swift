import Foundation

public protocol Display {
    var screen: Screen { get }
    func render() async throws -> RenderNode
    func postRender(force: Bool, terminal: TerminalProtocol) async throws
}

public extension Display {
    func postRender(force: Bool, terminal: TerminalProtocol) async throws {
        // default no-op
    }
}

public enum Screen: CaseIterable {
    case main
    case timingTower
    case timingHistory
    case driverTracker
    case info
    case logs
    case sessionStats
    case tyreStint
    case raceControl
    case teamRadio
    case debug
    case selectDriver
    case startSimulatedSession
    case manageSession
    case downloadTranscription
    case shutdown
}

public final class DisplayRegistry {
    private var displays: [Screen: Display]
    private var state: State

    public init(displays: [Display], state: State) {
        self.displays = Dictionary(uniqueKeysWithValues: displays.map { ($0.screen, $0) })
        self.state = state
    }

    public func activeDisplay() -> Display {
        displays[state.currentScreen] ?? FallbackDisplay(screen: state.currentScreen)
    }
}

public final class State {
    public var currentScreen: Screen
    public var cursorOffset: Int

    public init(currentScreen: Screen = .main, cursorOffset: Int = 0) {
        self.currentScreen = currentScreen
        self.cursorOffset = cursorOffset
    }
}

private struct FallbackDisplay: Display {
    let screen: Screen

    func render() async throws -> RenderNode {
        SimpleTextNode(text: "Unknown Display Selected: \(screen)")
    }
}
