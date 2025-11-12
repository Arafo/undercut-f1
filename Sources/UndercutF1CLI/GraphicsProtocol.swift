import ArgumentParser

enum GraphicsProtocol: String, CaseIterable, Codable, ExpressibleByArgument {
    case iTerm
    case kitty
    case sixel
}
