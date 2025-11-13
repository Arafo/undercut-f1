import ArgumentParser
import Foundation

/// Swift representation of the console graphics protocols supported by the .NET client.
public enum GraphicsProtocol: String, CaseIterable, Codable, Sendable {
    case iTerm = "iTerm"
    case kitty = "Kitty"
    case sixel = "Sixel"
}

extension GraphicsProtocol: ExpressibleByArgument {
    public init?(argument: String) {
        let normalised = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = GraphicsProtocol.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(normalised) == .orderedSame }) {
            self = match
        } else {
            return nil
        }
    }
}
