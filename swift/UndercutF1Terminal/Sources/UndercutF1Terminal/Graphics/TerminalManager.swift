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
        await adapter.useAlternateBuffer()
        await adapter.enableRawMode()
        await adapter.setCursorVisible(false)
        await adapter.moveCursor(to: .zero)
        await adapter.clearScreen()
        isConfigured = true
    }

    public func restore() async {
        guard isConfigured else { return }
        await adapter.setCursorVisible(true)
        await adapter.disableRawMode()
        await adapter.clearScreen()
        await adapter.useMainBuffer()
        isConfigured = false
    }
}
