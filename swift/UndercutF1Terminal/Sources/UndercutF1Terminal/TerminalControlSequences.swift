import Foundation

public enum ScreenBuffer {
    case main
    case alternate
}

public enum ClearMode {
    case fromCursor
    case toCursor
    case full
    case scrollback

    fileprivate var eraseCode: Int {
        switch self {
        case .fromCursor:
            return 0
        case .toCursor:
            return 1
        case .full:
            return 2
        case .scrollback:
            return 3
        }
    }
}

public enum TerminalControlSequences {
    public static func setScreenBuffer(_ buffer: ScreenBuffer) -> String {
        switch buffer {
        case .alternate:
            return "\u{001B}[?1049h"
        case .main:
            return "\u{001B}[?1049l"
        }
    }

    public static func clearScreen(_ mode: ClearMode) -> String {
        "\u{001B}[\(mode.eraseCode)J"
    }

    public static func clearLine() -> String {
        "\u{001B}[2K"
    }

    public static func moveCursor(to position: CursorPosition) -> String {
        let row = max(0, position.row) + 1
        let column = max(0, position.column) + 1
        return "\u{001B}[\(row);\(column)H"
    }

    public static func moveCursor(row: Int, column: Int) -> String {
        moveCursor(to: CursorPosition(row: row, column: column))
    }

    public static func setCursorVisibility(_ visible: Bool) -> String {
        visible ? "\u{001B}[?25h" : "\u{001B}[?25l"
    }

    public static func saveCursorPosition() -> String {
        "\u{001B}7"
    }

    public static func restoreCursorPosition() -> String {
        "\u{001B}8"
    }

    public static func beginSynchronizedUpdate() -> String {
        "\u{001B}[?2026h"
    }

    public static func endSynchronizedUpdate() -> String {
        "\u{001B}[?2026l"
    }
}
