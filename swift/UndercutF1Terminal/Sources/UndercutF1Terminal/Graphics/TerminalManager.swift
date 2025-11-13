import Foundation
import SwiftTerm

public final class TerminalManager {
    private let adapter: TerminalProtocol
    private var isConfigured = false

    public init(adapter: TerminalProtocol) {
        self.adapter = adapter
    }

    public func configure() async {
        guard !isConfigured else { return }
        await adapter.setScreenBuffer(.alternate)
        await adapter.enableRawMode()
        await adapter.setCursorVisible(false)
        await adapter.moveCursor(to: .zero)
        await adapter.clearScreen(mode: .full)
        isConfigured = true
    }

    public func prepareForNextFrame() async {
        guard isConfigured else { return }
        await adapter.moveCursor(to: .zero)
    }

    public func restore() async {
        guard isConfigured else { return }
        await adapter.setCursorVisible(true)
        await adapter.disableRawMode()
        await adapter.clearScreen(mode: .full)
        await adapter.setScreenBuffer(.main)
        isConfigured = false
    }
}
