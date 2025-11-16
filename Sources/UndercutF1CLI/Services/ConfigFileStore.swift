import Foundation

struct ConfigFileStore {
    private let defaults: ConsoleDefaults
    private let fileManager: FileManager

    init(defaults: ConsoleDefaults = ConsoleDefaults(), fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

    var pathDescription: String {
        defaults.defaultConfigFile.path
    }

    func load() throws -> [String: Any] {
        let url = defaults.defaultConfigFile
        guard fileManager.fileExists(atPath: url.path) else {
            return [:]
        }

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return [:] }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = json as? [String: Any] {
            return dictionary
        }
        throw ConfigFileError.invalidFormat
    }

    func save(_ dictionary: [String: Any]) throws {
        let data = try JSONSerialization.data(
            withJSONObject: dictionary,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: defaults.defaultConfigFile, options: [.atomic])
    }

    enum ConfigFileError: Error {
        case invalidFormat
    }
}
