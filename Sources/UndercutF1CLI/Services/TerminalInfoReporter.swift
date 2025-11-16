import Foundation

struct TerminalInfoReport {
    let termProgram: String?
    let term: String?
    let shell: String?
    let columns: Int?
    let rows: Int?
    let graphicsSupport: [GraphicsProtocol: Bool]
    let forcedProtocol: GraphicsProtocol?
    let notifyEnabled: Bool
    let preferFfmpeg: Bool
    let apiEnabled: Bool
}

struct TerminalInfoReporter {
    private let environment: [String: String]

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    func collect(using services: ServiceContainer) -> TerminalInfoReport {
        let forced = services.options.forceGraphicsProtocol
        var support: [GraphicsProtocol: Bool] = [:]
        for protocolType in GraphicsProtocol.allCases {
            support[protocolType] = forced.map { $0 == protocolType } ?? detectSupport(for: protocolType)
        }

        return TerminalInfoReport(
            termProgram: environment["TERM_PROGRAM"],
            term: environment["TERM"],
            shell: environment["SHELL"],
            columns: intEnv("COLUMNS"),
            rows: intEnv("LINES"),
            graphicsSupport: support,
            forcedProtocol: forced,
            notifyEnabled: services.options.notify,
            preferFfmpeg: services.options.preferFfmpegPlayback,
            apiEnabled: services.options.apiEnabled
        )
    }

    private func detectSupport(for protocolType: GraphicsProtocol) -> Bool {
        switch protocolType {
        case .iTerm:
            guard let program = environment["TERM_PROGRAM"]?.lowercased() else { return false }
            return program.contains("iterm") || program.contains("wezterm")
        case .kitty:
            guard let term = environment["TERM"]?.lowercased() else { return false }
            return term.contains("kitty") || term.contains("wezterm")
        case .sixel:
            guard let term = environment["TERM"]?.lowercased() else { return false }
            return term.contains("xterm") || term.contains("mlterm") || term.contains("contour")
        }
    }

    private func intEnv(_ key: String) -> Int? {
        if let value = environment[key], let number = Int(value) {
            return number
        }
        return nil
    }
}
