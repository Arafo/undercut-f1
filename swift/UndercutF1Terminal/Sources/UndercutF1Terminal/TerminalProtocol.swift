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
    func clearScreen(mode: ClearMode) async
    func clearLine(mode: LineClearMode) async
    func setCursorVisible(_ isVisible: Bool) async
    func saveCursorPosition() async
    func restoreCursorPosition() async
    func setScreenBuffer(_ buffer: ScreenBuffer) async
    func enableRawMode() async
    func disableRawMode() async
    func beginSynchronizedUpdate() async
    func endSynchronizedUpdate() async
    func readInput(maxBytes: Int) async throws -> [UInt8]
}

public extension TerminalProtocol {
    func clearScreen() async {
        await clearScreen(mode: .full)
    }

    func clearLine() async {
        await clearLine(mode: .entire)
    }

    func moveCursor(row: Int, column: Int) async {
        await moveCursor(to: CursorPosition(row: row, column: column))
    }

    func moveCursor(up rows: Int = 1) async {
        await write(TerminalControlSequences.moveCursor(up: rows))
    }

    func moveCursor(down rows: Int = 1) async {
        await write(TerminalControlSequences.moveCursor(down: rows))
    }

    func moveCursor(forward columns: Int = 1) async {
        await write(TerminalControlSequences.moveCursor(forward: columns))
    }

    func moveCursor(backward columns: Int = 1) async {
        await write(TerminalControlSequences.moveCursor(backward: columns))
    }

    func moveCursorToNextLine(_ count: Int = 1) async {
        await write(TerminalControlSequences.moveCursorToNextLine(count))
    }

    func moveCursorToPreviousLine(_ count: Int = 1) async {
        await write(TerminalControlSequences.moveCursorToPreviousLine(count))
    }

    func moveCursorToColumn(_ column: Int) async {
        await write(TerminalControlSequences.moveCursorToColumn(column))
    }

    func scrollUp(_ count: Int = 1) async {
        await write(TerminalControlSequences.scrollUp(count))
    }

    func scrollDown(_ count: Int = 1) async {
        await write(TerminalControlSequences.scrollDown(count))
    }

    func setWindowTitle(_ title: String) async {
        await write(TerminalControlSequences.setWindowTitle(title))
    }

    func ringBell() async {
        await write(TerminalControlSequences.bell())
    }
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
        terminal.write(text: TerminalControlSequences.moveCursor(to: position))
    }

    public func clearScreen(mode: ClearMode) async {
        terminal.write(text: TerminalControlSequences.clearScreen(mode))
    }

    public func clearLine(mode: LineClearMode) async {
        terminal.write(text: TerminalControlSequences.clearLine(mode))
    }

    public func setCursorVisible(_ isVisible: Bool) async {
        terminal.write(text: TerminalControlSequences.setCursorVisibility(isVisible))
    }

    public func saveCursorPosition() async {
        terminal.write(text: TerminalControlSequences.saveCursorPosition())
    }

    public func restoreCursorPosition() async {
        terminal.write(text: TerminalControlSequences.restoreCursorPosition())
    }

    public func setScreenBuffer(_ buffer: ScreenBuffer) async {
        switch buffer {
        case .alternate:
            terminal.useAlternateBuffer()
        case .main:
            terminal.useMainBuffer()
        }
        terminal.write(text: TerminalControlSequences.setScreenBuffer(buffer))
    }

    public func enableRawMode() async {
        terminal.setRawMode()
    }

    public func disableRawMode() async {
        terminal.unsetRawMode()
    }

    public func beginSynchronizedUpdate() async {
        terminal.beginSynchronizedUpdate()
        terminal.write(text: TerminalControlSequences.beginSynchronizedUpdate())
    }

    public func endSynchronizedUpdate() async {
        terminal.endSynchronizedUpdate()
        terminal.write(text: TerminalControlSequences.endSynchronizedUpdate())
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
