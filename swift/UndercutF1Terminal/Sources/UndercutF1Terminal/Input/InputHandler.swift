import Foundation

public protocol InputHandler {
    var keys: [ConsoleKey] { get }
    var displayKeys: DisplayKey { get }
    var description: String { get }
    var applicableScreens: Set<Screen> { get }
    var isEnabled: Bool { get }
    var sortIndex: Int { get }

    func handle(keyInfo: KeyInfo) async throws
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
    }
}

public enum ConsoleKey: String {
    case escape
    case enter
    case left
    case right
    case up
    case down
    case character
}

public struct DisplayKey {
    public let displayCharacters: String

    public init(displayCharacters: String) {
        self.displayCharacters = displayCharacters
    }
}
