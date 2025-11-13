import ArgumentParser
import Foundation

public enum ExternalSyncServiceType: String, CaseIterable, Codable, Sendable {
    case kodi = "Kodi"
}

extension ExternalSyncServiceType: ExpressibleByArgument {
    public init?(argument: String) {
        let normalised = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = ExternalSyncServiceType.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(normalised) == .orderedSame }) {
            self = match
        } else {
            return nil
        }
    }
}

public struct ExternalPlayerSyncOptions: Codable, Sendable, Equatable {
    public var enabled: Bool?
    public var serviceType: ExternalSyncServiceType?
    public var url: URL?
    public var webSocketConnectInterval: Int?

    public init(
        enabled: Bool? = nil,
        serviceType: ExternalSyncServiceType? = nil,
        url: URL? = nil,
        webSocketConnectInterval: Int? = nil
    ) {
        self.enabled = enabled
        self.serviceType = serviceType
        self.url = url
        self.webSocketConnectInterval = webSocketConnectInterval
    }

    func merging(overrides: ExternalPlayerSyncOptions?) -> ExternalPlayerSyncOptions {
        guard let overrides else { return self }
        return ExternalPlayerSyncOptions(
            enabled: overrides.enabled ?? enabled,
            serviceType: overrides.serviceType ?? serviceType,
            url: overrides.url ?? url,
            webSocketConnectInterval: overrides.webSocketConnectInterval ?? webSocketConnectInterval
        )
    }
}
