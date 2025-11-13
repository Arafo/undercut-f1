import Foundation
import UndercutF1Terminal

@main
struct UndercutF1TerminalPreview {
    static func main() {
        let assets = TerminalThirdPartyAsset.allCases.compactMap { $0.makeEntry() }
        print("UndercutF1Terminal preview target ready for integration tests.")
        if assets.isEmpty {
            print("No terminal assets were bundled.")
        } else {
            print("Bundled terminal placeholders:")
            for asset in assets {
                print("- \(asset.name): \(asset.description)")
            }
        }
    }
}
