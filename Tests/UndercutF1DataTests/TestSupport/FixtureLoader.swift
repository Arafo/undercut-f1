import Foundation

enum DataFixtures {
    static func string(named name: String, withExtension ext: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            throw NSError(domain: "Fixtures", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name).\(ext)"])
        }
        return try String(contentsOf: url)
    }
}
