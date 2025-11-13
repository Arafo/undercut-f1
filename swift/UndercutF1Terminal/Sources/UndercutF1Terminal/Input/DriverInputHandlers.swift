import Foundation

public final class SelectDriverInputHandler: InputHandler {
    private let state: State
    private let selectionProvider: DriverSelectionProvider

    public init(state: State, selectionProvider: DriverSelectionProvider) {
        self.state = state
        self.selectionProvider = selectionProvider
    }

    public var keyBindings: [KeyBinding] { [KeyBinding(key: .enter)] }
    public var description: String { "Toggle Select" }
    public var applicableScreens: Set<Screen> { Set([.driverTracker, .selectDriver]) }
    public let sortIndex: Int = 40
    public var isEnabled: Bool { true }

    public func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws {
        guard let driverNumber = selectionProvider.driverNumber(forLine: state.cursorOffset) else { return }
        selectionProvider.toggleSelection(for: driverNumber)
    }
}
