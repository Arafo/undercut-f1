import Foundation

public struct WebServiceConfiguration: Sendable, Equatable {
    public var isEnabled: Bool
    public var hostname: String
    public var port: Int

    public init(isEnabled: Bool = false, hostname: String = "127.0.0.1", port: Int = 0xF1F1) {
        self.isEnabled = isEnabled
        self.hostname = hostname
        self.port = port
    }
}
