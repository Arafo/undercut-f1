import Vapor

public enum ControlOperation: String, Codable, Sendable {
    case pauseClock = "PauseClock"
    case resumeClock = "ResumeClock"
    case toggleClock = "ToggleClock"
}

public struct ControlRequest: Content {
    enum CodingKeys: String, CodingKey {
        case operation
    }

    public let operation: ControlOperation

    public init(operation: ControlOperation) {
        self.operation = operation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .operation)
        guard let operation = ControlOperation(rawValue: rawValue) else {
            throw ControlError(.unknownOperation)
        }
        self.operation = operation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(operation.rawValue, forKey: .operation)
    }
}

public struct ControlResponse: Content, Equatable {
    public let clockPaused: Bool
    public let sessionRunning: Bool
    public let sessionName: String?

    public init(clockPaused: Bool, sessionRunning: Bool, sessionName: String?) {
        self.clockPaused = clockPaused
        self.sessionRunning = sessionRunning
        self.sessionName = sessionName
    }
}

public enum ControlErrorCode: String, Codable, Sendable {
    case noRunningSession = "NoRunningSession"
    case unknownOperation = "UnknownOperation"

    var message: String {
        switch self {
        case .noRunningSession:
            return "No session is currently running"
        case .unknownOperation:
            return "Unknown operation requested"
        }
    }
}

public struct ControlError: AbortError, Content, Equatable {
    public let errorCode: ControlErrorCode

    public init(_ errorCode: ControlErrorCode) {
        self.errorCode = errorCode
    }

    public var status: HTTPResponseStatus { .badRequest }

    public var reason: String { errorCode.message }
}
