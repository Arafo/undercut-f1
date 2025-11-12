import Foundation

public struct LogEntry {
    public enum Level: Int, Comparable, CustomStringConvertible {
        case trace = 0
        case debug
        case information
        case warning
        case error
        case critical

        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public var description: String {
            switch self {
            case .trace: return "Trace"
            case .debug: return "Debug"
            case .information: return "Information"
            case .warning: return "Warning"
            case .error: return "Error"
            case .critical: return "Critical"
            }
        }
    }

    public let timestamp: Date
    public let level: Level
    public let message: String
    public let metadata: String?

    public init(timestamp: Date, level: Level, message: String, metadata: String? = nil) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}

public protocol LogStore {
    func recentLogs() -> [LogEntry]
}

public struct LogDisplayOptions {
    public var minimumLogLevel: LogEntry.Level

    public init(minimumLogLevel: LogEntry.Level = .information) {
        self.minimumLogLevel = minimumLogLevel
    }
}

public final class LogDisplay: Display {
    public let screen: Screen = .logs

    private let state: State
    private let store: LogStore
    private let options: LogDisplayOptions

    public init(state: State, store: LogStore, options: LogDisplayOptions = LogDisplayOptions()) {
        self.state = state
        self.store = store
        self.options = options
    }

    public func render() async throws -> RenderNode {
        let logLines = store
            .recentLogs()
            .filter { $0.level >= options.minimumLogLevel }
            .reversed()

        let skipped = max(0, state.cursorOffset)
        let slice = Array(logLines.dropFirst(skipped).prefix(20))

        var rows: [RenderNode] = []
        if skipped > 0 {
            rows.append(SimpleTextNode(text: "Skipping \(skipped) messages"))
        } else {
            rows.append(SimpleTextNode(text: "Minimum Log Level: \(options.minimumLogLevel)"))
        }

        for entry in slice {
            let line = "\(badge(for: entry.level)) \(entry.message) \(entry.metadata ?? "")"
            rows.append(SimpleTextNode(text: line))
        }

        return PanelNode(body: RowsNode(rows: rows))
    }

    private func badge(for level: LogEntry.Level) -> String {
        switch level {
        case .critical: return "CRT"
        case .error: return "ERR"
        case .warning: return "WRN"
        case .information: return "INF"
        case .debug: return "DBG"
        case .trace: return "TRC"
        }
    }
}
