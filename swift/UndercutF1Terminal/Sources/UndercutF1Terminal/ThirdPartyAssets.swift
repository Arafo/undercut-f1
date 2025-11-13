import Foundation

public struct TerminalThirdPartyAssetDescriptor {
    public let name: String
    public let description: String
    public let url: URL
}

public enum TerminalThirdPartyAsset: CaseIterable {
    case swiftTermPlaceholder
    case whisperPlaceholder
    case czlibPlaceholder

    private var subdirectory: String {
        switch self {
        case .swiftTermPlaceholder:
            return "ThirdParty/SwiftTerm"
        case .whisperPlaceholder:
            return "ThirdParty/Whisper"
        case .czlibPlaceholder:
            return "ThirdParty/CZlibShim"
        }
    }

    private var description: String {
        switch self {
        case .swiftTermPlaceholder:
            return "Reserved location for the SwiftTerm LICENSE file."
        case .whisperPlaceholder:
            return "Directory for pre-fetched Whisper model binaries."
        case .czlibPlaceholder:
            return "Reserved location for the zlib license acknowledgment."
        }
    }

    public func makeEntry() -> TerminalThirdPartyAssetDescriptor? {
        guard let url = Bundle.module.url(
            forResource: "placeholder",
            withExtension: "txt",
            subdirectory: subdirectory
        ) else {
            return nil
        }

        return TerminalThirdPartyAssetDescriptor(
            name: subdirectory,
            description: description,
            url: url
        )
    }
}
