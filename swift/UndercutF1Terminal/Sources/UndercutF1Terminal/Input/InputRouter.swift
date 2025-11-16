import Foundation

public final class InputRouter {
    private let handlers: [InputHandler]
    private let state: State
    private let parser = KeyParser()

    public init(handlers: [InputHandler], state: State) {
        self.handlers = handlers
        self.state = state
    }

    public func pollInput(terminal: TerminalProtocol, cancellation: CancellationToken) async {
        guard !cancellation.isCancelled else { return }
        do {
            let bytes = try await terminal.readInput(maxBytes: 8)
            guard !bytes.isEmpty else { return }
            let parsed = parser.parse(bytes: bytes)
            let applicable = handlers.filter { handler in
                handler.isEnabled && handler.applicableScreens.contains(state.currentScreen)
            }

            await withTaskGroup(of: Void.self) { group in
                for handler in applicable {
                    guard handler.keyBindings.contains(where: { $0.matches(parsed) }) else { continue }
                    group.addTask {
                        for _ in 0..<parsed.repeatCount {
                            try? await handler.handle(keyInfo: parsed, terminal: terminal)
                        }
                    }
                }
            }
        } catch {
            // swallow errors to keep the loop responsive
        }
}

struct KeyParser {
    private static let esc: UInt8 = 27
    private static let csi: UInt8 = 91
    private static let feStart: UInt8 = 79
    private static let argSep: UInt8 = 59
    private static let tilde: UInt8 = 126

    func parse(bytes: [UInt8]) -> KeyInfo {
        let trimmed = trim(bytes: bytes)
        guard !trimmed.isEmpty else {
            return KeyInfo(character: nil, key: .unknown(0), modifiers: [], repeatCount: 1)
        }

        if trimmed == [Self.esc] {
            return KeyInfo(character: nil, key: .escape, modifiers: [], repeatCount: 1)
        }

        if trimmed.count >= 2, trimmed[0] == Self.esc, trimmed[1] == 0 {
            return KeyInfo(character: nil, key: .escape, modifiers: [], repeatCount: 1)
        }

        if trimmed.count >= 3, trimmed[0] == Self.esc, trimmed[1] == Self.csi {
            let body = Array(trimmed.dropFirst(2))

            if let parsed = parseModifiedArrowSequence(body) {
                return parsed
            }

            if let parsed = parseFunctionSequence(body) {
                return parsed
            }

            if let first = body.first, let arrow = arrowKey(for: first) {
                return KeyInfo(character: nil, key: arrow, modifiers: [], repeatCount: 1)
            }
        }

        if trimmed.count >= 3, trimmed[0] == Self.esc, trimmed[1] == Self.feStart,
           let code = trimmed.last, let arrow = arrowKey(for: code) {
            return KeyInfo(character: nil, key: arrow, modifiers: [], repeatCount: 1)
        }

        if let first = trimmed.first {
            switch first {
            case 3:
                return KeyInfo(character: nil, key: .controlC, modifiers: [.control], repeatCount: 1)
            case 8, 127:
                return KeyInfo(character: nil, key: .backspace, modifiers: [], repeatCount: 1)
            case 10, 13:
                return KeyInfo(character: nil, key: .enter, modifiers: [], repeatCount: 1)
            default:
                if (1...26).contains(Int(first)) {
                    let scalarValue = Int(first) + 96
                    if let scalar = UnicodeScalar(scalarValue) {
                        let character = Character(scalar)
                        return KeyInfo(
                            character: character,
                            key: .character(character),
                            modifiers: [.control],
                            repeatCount: 1
                        )
                    }
                }

                if let scalar = UnicodeScalar(first) {
                    let character = Character(scalar)
                    var modifiers: KeyInfo.Modifier = []
                    if CharacterSet.uppercaseLetters.contains(scalar) {
                        modifiers.insert(.shift)
                    }

                    let repeats = 1 + trimmed.dropFirst().filter { $0 == first }.count
                    return KeyInfo(
                        character: character,
                        key: .character(character),
                        modifiers: modifiers,
                        repeatCount: repeats
                    )
                }
            }
        }

        let value = trimmed.first ?? 0
        return KeyInfo(character: nil, key: .unknown(value), modifiers: [], repeatCount: 1)
    }

    private func parseModifiedArrowSequence(_ body: [UInt8]) -> KeyInfo? {
        guard body.count >= 4, body[0] == 49, body[1] == Self.argSep,
              let modifierValue = Int(String(UnicodeScalar(body[2]))),
              let arrow = arrowKey(for: body[3]) else {
            return nil
        }

        let modifiers = modifiers(for: modifierValue)
        return KeyInfo(character: nil, key: arrow, modifiers: modifiers, repeatCount: 1)
    }

    private func parseFunctionSequence(_ body: [UInt8]) -> KeyInfo? {
        guard let last = body.last, last == Self.tilde else { return nil }
        let payload = body.dropLast()
        guard payload.allSatisfy({ ($0 >= 48 && $0 <= 57) || $0 == Self.argSep }),
              let string = String(bytes: payload, encoding: .ascii) else {
            return nil
        }

        let components = string.split(separator: ";").compactMap { Int($0) }
        guard let asciiValue = components.last, asciiValue >= 32,
              let scalar = UnicodeScalar(asciiValue) else {
            return nil
        }

        let modifierCode = components.dropLast().last ?? 1
        let modifiers = modifiers(for: modifierCode)
        let character = Character(scalar)

        return KeyInfo(
            character: character,
            key: .character(character),
            modifiers: modifiers,
            repeatCount: 1
        )
    }

    private func modifiers(for code: Int) -> KeyInfo.Modifier {
        var modifiers: KeyInfo.Modifier = []

        switch code {
        case 2, 4, 6, 8:
            modifiers.insert(.shift)
        default:
            break
        }

        switch code {
        case 5, 6, 7, 8:
            modifiers.insert(.control)
        default:
            break
        }

        return modifiers
    }

    private func arrowKey(for code: UInt8) -> ConsoleKey? {
        switch code {
        case 68: return .left
        case 65: return .up
        case 66: return .down
        case 67: return .right
        default: return nil
        }
    }

    private func trim(bytes: [UInt8]) -> [UInt8] {
        guard let lastIndex = bytes.lastIndex(where: { $0 != 0 }) else {
            return bytes
        }

        var firstIndex = 0
        while firstIndex < lastIndex, bytes[firstIndex] == 0 {
            firstIndex += 1
        }

        return Array(bytes[firstIndex...lastIndex])
    }
}
