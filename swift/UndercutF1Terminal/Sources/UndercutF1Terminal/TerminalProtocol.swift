import Foundation
import SwiftTerm

public struct TerminalCapabilities {
    public let supportsSynchronizedUpdates: Bool
    public let supportsImages: Bool

    public init(supportsSynchronizedUpdates: Bool, supportsImages: Bool) {
        self.supportsSynchronizedUpdates = supportsSynchronizedUpdates
        self.supportsImages = supportsImages
    }
}

public protocol TerminalProtocol: AnyObject {
    var capabilities: TerminalCapabilities { get }

    func write(_ string: String) async
    func write(data: Data) async
    func moveCursor(to position: CursorPosition) async
    func clearScreen() async
    func setCursorVisible(_ isVisible: Bool) async
    func useAlternateBuffer() async
    func useMainBuffer() async
    func enableRawMode() async
    func disableRawMode() async
    func beginSynchronizedUpdate() async
    func endSynchronizedUpdate() async
    func readInput(maxBytes: Int) async throws -> [UInt8]
}

public struct CursorPosition: Equatable {
    public let row: Int
    public let column: Int

    public static let zero = CursorPosition(row: 0, column: 0)

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public final class SwiftTermAdapter: TerminalProtocol {
    private let terminal: Terminal

    public init(terminal: Terminal) {
        self.terminal = terminal
    }

    public var capabilities: TerminalCapabilities {
        TerminalCapabilities(
            supportsSynchronizedUpdates: terminal.supportsSynchronizedUpdate,
            supportsImages: terminal.supportsDeviceControlImages
        )
    }

    public func write(_ string: String) async {
        terminal.write(text: string)
    }

    public func write(data: Data) async {
        data.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress, ptr.count > 0 {
                terminal.write(buffer: base, size: ptr.count)
            }
        }
    }

    public func moveCursor(to position: CursorPosition) async {
        terminal.cursorPosition = Position(row: position.row, col: position.column)
    }

    public func clearScreen() async {
        terminal.clearScreen()
    }

    public func setCursorVisible(_ isVisible: Bool) async {
        terminal.setCursorVisible(isVisible)
    }

    public func useAlternateBuffer() async {
        terminal.useAlternateBuffer()
    }

    public func useMainBuffer() async {
        terminal.useMainBuffer()
    }

    public func enableRawMode() async {
        terminal.setRawMode()
    }

    public func disableRawMode() async {
        terminal.unsetRawMode()
    }

    public func beginSynchronizedUpdate() async {
        terminal.beginSynchronizedUpdate()
    }

    public func endSynchronizedUpdate() async {
        terminal.endSynchronizedUpdate()
    }

    public func readInput(maxBytes: Int) async throws -> [UInt8] {
        try await withCheckedThrowingContinuation { continuation in
            terminal.read(size: maxBytes) { data, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: Array(data)) }
            }
        }
    }
}
