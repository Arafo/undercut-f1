import XCTest
@testable import UndercutF1Terminal

final class MainDisplayTests: XCTestCase {
    func testRenderIncludesInstructionsAndFooter() async throws {
        let metadata = MainDisplayMetadata(
            accountStatus: .loggedIn(expiry: Date(timeIntervalSince1970: 0)),
            currentVersion: "v1.0.0",
            latestVersion: "v1.2.0"
        )
        let dataSource = StubMainDisplayDataSource(metadata: metadata)
        let display = MainDisplay(dataSource: dataSource)

        var buffer = ""
        let node = try await display.render()
        node.render(into: &buffer)

        XCTAssertTrue(buffer.contains("Welcome to Undercut F1"))
        XCTAssertTrue(buffer.contains("Version: v1.0.0"))
        XCTAssertTrue(buffer.contains("A newer version is available: v1.2.0"))
    }
}

private struct StubMainDisplayDataSource: MainDisplayDataSource {
    let metadata: MainDisplayMetadata

    func loadMetadata() async throws -> MainDisplayMetadata {
        metadata
    }
}
