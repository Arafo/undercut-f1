import Foundation
import UndercutF1Terminal

/// Describes the placeholder resources that should accompany the Swift distribution artifacts.
struct ThirdPartyAssetEntry {
    let name: String
    let description: String
    let url: URL
}

enum CLIBundledAsset: CaseIterable {
    case swiftTermReadme
    case whisperManifest
    case czlibNotes

    var resourceName: String {
        switch self {
        case .swiftTermReadme:
            return "LICENSE_PLACEHOLDER"
        case .whisperManifest:
            return "manifest"
        case .czlibNotes:
            return "NOTICE_PLACEHOLDER"
        }
    }

    var fileExtension: String? {
        switch self {
        case .swiftTermReadme, .czlibNotes:
            return "md"
        case .whisperManifest:
            return "json"
        }
    }

    var subdirectory: String {
        switch self {
        case .swiftTermReadme:
            return "ThirdParty/SwiftTerm"
        case .whisperManifest:
            return "ThirdParty/Whisper"
        case .czlibNotes:
            return "ThirdParty/CZlibShim"
        }
    }

    var description: String {
        switch self {
        case .swiftTermReadme:
            return "Placeholder location for the SwiftTerm license."
        case .whisperManifest:
            return "Manifest describing Whisper models to stage beside the binary."
        case .czlibNotes:
            return "Reminder to ship the zlib license with the CZlib shim."
        }
    }

    func makeEntry() -> ThirdPartyAssetEntry? {
        let bundle = Bundle.module
        let url = bundle.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: subdirectory
        )

        guard let url else {
            return nil
        }

        return ThirdPartyAssetEntry(
            name: subdirectory,
            description: description,
            url: url
        )
    }
}

/// Aggregates resources from the CLI bundle as well as assets declared by the terminal package.
struct ThirdPartyAssetManifest {
    func allAssets() -> [ThirdPartyAssetEntry] {
        let cliEntries = CLIBundledAsset.allCases.compactMap { $0.makeEntry() }
        let terminalEntries = TerminalThirdPartyAsset.allCases.compactMap { asset in
            asset.makeEntry().map { descriptor in
                ThirdPartyAssetEntry(
                    name: descriptor.name,
                    description: descriptor.description,
                    url: descriptor.url
                )
            }
        }
        return cliEntries + terminalEntries
    }

    func summary() -> String {
        let entries = allAssets()
        guard !entries.isEmpty else {
            return "No third-party asset markers were bundled with this build."
        }

        let lines = entries.map { entry in
            "• \(entry.name): \(entry.description) (\(entry.url.lastPathComponent))"
        }
        return (["Third-party asset markers bundled with this build:"] + lines).joined(separator: "\n")
    }
}
