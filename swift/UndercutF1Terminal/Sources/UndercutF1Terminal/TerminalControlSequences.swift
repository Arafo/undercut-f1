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

public enum LineClearMode {
    case fromCursor
    case toCursor
    case entire

    fileprivate var eraseCode: Int {
        switch self {
        case .fromCursor:
            return 0
        case .toCursor:
            return 1
        case .entire:
            return 2
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

    public static func clearLine(_ mode: LineClearMode = .entire) -> String {
        "\u{001B}[\(mode.eraseCode)K"
    }

    public static func moveCursor(to position: CursorPosition) -> String {
        let row = max(0, position.row) + 1
        let column = max(0, position.column) + 1
        return "\u{001B}[\(row);\(column)H"
    }

    public static func moveCursor(row: Int, column: Int) -> String {
        moveCursor(to: CursorPosition(row: row, column: column))
    }

    public static func moveCursor(up rows: Int = 1) -> String {
        "\u{001B}[\(max(1, rows))A"
    }

    public static func moveCursor(down rows: Int = 1) -> String {
        "\u{001B}[\(max(1, rows))B"
    }

    public static func moveCursor(forward columns: Int = 1) -> String {
        "\u{001B}[\(max(1, columns))C"
    }

    public static func moveCursor(backward columns: Int = 1) -> String {
        "\u{001B}[\(max(1, columns))D"
    }

    public static func moveCursorToNextLine(_ count: Int = 1) -> String {
        "\u{001B}[\(max(1, count))E"
    }

    public static func moveCursorToPreviousLine(_ count: Int = 1) -> String {
        "\u{001B}[\(max(1, count))F"
    }

    public static func moveCursorToColumn(_ column: Int) -> String {
        "\u{001B}[\(max(1, column + 1))G"
    }

    public static func scrollUp(_ count: Int = 1) -> String {
        "\u{001B}[\(max(1, count))S"
    }

    public static func scrollDown(_ count: Int = 1) -> String {
        "\u{001B}[\(max(1, count))T"
    }

    public static func setWindowTitle(_ title: String) -> String {
        "\u{001B}]0;\(title)\u{0007}"
    }

    public static func bell() -> String {
        "\u{0007}"
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
