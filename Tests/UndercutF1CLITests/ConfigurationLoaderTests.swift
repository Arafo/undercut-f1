import XCTest
@testable import UndercutF1CLI

final class ConfigurationLoaderTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let dir = temporaryDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    func testMergedOptionsHonoursConfigEnvironmentAndCommandLine() throws {
        let configHome = temporaryDirectory.appendingPathComponent("config", isDirectory: true)
        let configDir = configHome.appendingPathComponent("undercut-f1", isDirectory: true)
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let configFile = configDir.appendingPathComponent("config.json", isDirectory: false)
        let configJSON = """
        {
            "dataDirectory": "/tmp/data-from-file",
            "notify": false,
            "formula1AccessToken": "from-file",
            "externalPlayerSync": {
                "enabled": true
            }
        }
        """.data(using: .utf8)!
        try configJSON.write(to: configFile)

        var env = ProcessInfo.processInfo.environment
        env["XDG_CONFIG_HOME"] = configHome.path
        env["UNDERCUTF1_NOTIFY"] = "true"
        env["UNDERCUTF1_VERBOSE"] = "true"
        env["UNDERCUTF1_FORMULA1ACCESSTOKEN"] = "from-env"

        let defaults = ConsoleDefaults(environment: env)
        let loader = ConfigurationLoader(fileManager: .default, defaults: defaults)

        var commandLine = ConsoleOptions()
        commandLine.notify = false
        commandLine.dataDirectory = "/tmp/cli"

        let resolved = loader.mergedOptions(commandLine: commandLine)
        XCTAssertEqual(resolved.dataDirectory.path, "/tmp/cli")
        XCTAssertTrue(resolved.verbose)
        XCTAssertFalse(resolved.notify)
        XCTAssertEqual(resolved.formula1AccessToken, "from-env")
        XCTAssertEqual(resolved.externalPlayerSync.enabled, true)
    }

    func testEnsureConfigFileCreatesSchemaTemplate() throws {
        let configHome = temporaryDirectory.appendingPathComponent("config", isDirectory: true)
        var env = ProcessInfo.processInfo.environment
        env["XDG_CONFIG_HOME"] = configHome.path
        let defaults = ConsoleDefaults(environment: env)
        let loader = ConfigurationLoader(fileManager: .default, defaults: defaults)

        let schema = URL(string: "https://example.com/config.schema.json")!
        try loader.ensureConfigFileExists(schemaURL: schema)

        let configFile = defaults.defaultConfigFile
        XCTAssertTrue(FileManager.default.fileExists(atPath: configFile.path))
        let data = try Data(contentsOf: configFile)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        XCTAssertEqual(json?["$schema"], schema.absoluteString)

        // Calling again should be a no-op
        try loader.ensureConfigFileExists(schemaURL: schema)
        let afterData = try Data(contentsOf: configFile)
        XCTAssertEqual(data, afterData)
    }
}
