import Foundation

public protocol InputHandler {
    var keyBindings: [KeyBinding] { get }
    var displayBindings: [KeyBinding] { get }
    var description: String { get }
    var applicableScreens: Set<Screen> { get }
    var isEnabled: Bool { get }
    var sortIndex: Int { get }

    func handle(keyInfo: KeyInfo, terminal: TerminalProtocol) async throws
}

public extension InputHandler {
    var displayBindings: [KeyBinding] { keyBindings }
}

public struct KeyInfo {
    public let character: Character?
    public let key: ConsoleKey
    public let modifiers: Modifier
    public let repeatCount: Int

    public struct Modifier: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let shift = Modifier(rawValue: 1 << 0)
        public static let control = Modifier(rawValue: 1 << 1)

        public func containsAll(_ other: Modifier) -> Bool {
            other.isSubset(of: self)
        }
    }
}

public enum ConsoleKey: Hashable {
    case escape
    case enter
    case left
    case right
    case up
    case down
    case backspace
    case controlC
    case character(Character)
    case unknown(UInt8)
}

public struct KeyBinding: Hashable {
    public let key: ConsoleKey
    public let modifiers: KeyInfo.Modifier

    public init(key: ConsoleKey, modifiers: KeyInfo.Modifier = []) {
        self.key = key
        self.modifiers = modifiers
    }

    public init(character: Character, modifiers: KeyInfo.Modifier = []) {
        self.init(key: .character(character), modifiers: modifiers)
    }

    public func matches(_ info: KeyInfo) -> Bool {
        guard key.matches(info) else { return false }
        return info.modifiers.containsAll(modifiers)
    }

    public var displayLabel: String {
        key.displayLabel
    }
}

private extension ConsoleKey {
    func matches(_ info: KeyInfo) -> Bool {
        switch (self, info.key) {
        case (.character(let expected), .character(let actual)):
            return String(expected).lowercased() == String(actual).lowercased()
        case (.escape, .escape), (.enter, .enter), (.left, .left), (.right, .right),
            (.up, .up), (.down, .down), (.backspace, .backspace), (.controlC, .controlC):
            return true
        case (.unknown(let value), .unknown(let other)):
            return value == other
        default:
            return false
        }
    }

    var displayLabel: String {
        switch self {
        case .escape:
            return "Esc"
        case .enter:
            return "Enter"
        case .left:
            return "←"
        case .right:
            return "→"
        case .up:
            return "↑"
        case .down:
            return "↓"
        case .backspace:
            return "Backspace"
        case .controlC:
            return "Ctrl+C"
        case .character(let character):
            return String(character).uppercased()
        case .unknown:
            return "?"
        }
    }
}
