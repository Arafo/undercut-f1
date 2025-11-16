import XCTest
@testable import UndercutF1Terminal

final class FrameSnapshotTests: XCTestCase {
    func testRootLayoutSnapshotMatchesFixture() throws {
        let content = RowsNode(rows: [
            SimpleTextNode(text: "Timing Tower"),
            SimpleTextNode(text: " 1 VER   +0.000")
        ])
        let footer = ColumnsNode(columns: [
            SimpleTextNode(text: "[Q] Quit"),
            SimpleTextNode(text: "[L] Logs")
        ])

        var buffer = ""
        let layout = RootLayout(content: content, footer: footer)
        layout.render(into: &buffer)

        let expected = try TerminalFixtures.string(named: "basic_frame", withExtension: "snapshot")
        XCTAssertEqual(buffer, expected)
    }
}
