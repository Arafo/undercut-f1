import XCTest
@testable import UndercutF1Terminal

final class LayoutTests: XCTestCase {
    func testTablePadding() {
        var table = TableNode(columns: [
            .init(title: "Col1", width: 5, alignment: .left),
            .init(title: "Col2", width: 5, alignment: .right)
        ])
        table.addRow(["Hi", "42"])
        var buffer = ""
        table.render(into: &buffer)
        XCTAssertTrue(buffer.contains("Hi   42"))
    }
}
