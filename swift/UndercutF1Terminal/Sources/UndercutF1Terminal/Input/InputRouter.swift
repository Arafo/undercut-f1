import Foundation

public final class InputRouter {
    private let handlers: [InputHandler]
    private let state: State

    private static let esc: UInt8 = 27
    private static let csi: UInt8 = 91
    private static let feStart: UInt8 = 79
    private static let argSep: UInt8 = 59

    public init(handlers: [InputHandler], state: State) {
        self.handlers = handlers
        self.state = state
    }

    public func pollInput(terminal: TerminalProtocol, cancellation: CancellationToken) async {
        guard !cancellation.isCancelled else { return }
        do {
            let bytes = try await terminal.readInput(maxBytes: 8)
            guard !bytes.isEmpty else { return }
            let parsed = parse(bytes: bytes)
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

    private func parse(bytes: [UInt8]) -> KeyInfo {
        if bytes == [Self.esc] {
            return KeyInfo(character: nil, key: .escape, modifiers: [], repeatCount: 1)
        }

        if bytes.count >= 3 && bytes[0] == Self.esc && bytes[1] == Self.csi {
            let body = Array(bytes.dropFirst(2))
            if body.first == 49, body.dropFirst().first == Self.argSep, let code = body.last {
                switch code {
                case 68: return KeyInfo(character: nil, key: .left, modifiers: [.shift], repeatCount: 1)
                case 65: return KeyInfo(character: nil, key: .up, modifiers: [.shift], repeatCount: 1)
                case 66: return KeyInfo(character: nil, key: .down, modifiers: [.shift], repeatCount: 1)
                case 67: return KeyInfo(character: nil, key: .right, modifiers: [.shift], repeatCount: 1)
                default: break
                }
            }
            if let code = body.first {
                switch code {
                case 68: return KeyInfo(character: nil, key: .left, modifiers: [], repeatCount: 1)
                case 65: return KeyInfo(character: nil, key: .up, modifiers: [], repeatCount: 1)
                case 66: return KeyInfo(character: nil, key: .down, modifiers: [], repeatCount: 1)
                case 67: return KeyInfo(character: nil, key: .right, modifiers: [], repeatCount: 1)
                default: break
                }
            }
        }

        if bytes.count >= 3 && bytes[0] == Self.esc && bytes[1] == Self.feStart {
            if let code = bytes.last {
                switch code {
                case 68: return KeyInfo(character: nil, key: .left, modifiers: [], repeatCount: 1)
                case 65: return KeyInfo(character: nil, key: .up, modifiers: [], repeatCount: 1)
                case 66: return KeyInfo(character: nil, key: .down, modifiers: [], repeatCount: 1)
                case 67: return KeyInfo(character: nil, key: .right, modifiers: [], repeatCount: 1)
                default: break
                }
            }
        }

        if let first = bytes.first {
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
                    let repeats = bytes.filter { $0 == first }.count
                    return KeyInfo(
                        character: character,
                        key: .character(character),
                        modifiers: [],
                        repeatCount: repeats
                    )
                }
            }
        }

        let value = bytes.first ?? 0
        return KeyInfo(character: nil, key: .unknown(value), modifiers: [], repeatCount: 1)
    }
}
