import Foundation

public protocol SelectDriverDisplayDataSource {
    func makeSelectDriverContent(cursorOffset: Int) async throws -> RenderNode
}

public final class SelectDriverDisplay: Display {
    public let screen: Screen = .selectDriver

    private let state: State
    private let dataSource: SelectDriverDisplayDataSource

    public init(state: State, dataSource: SelectDriverDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeSelectDriverContent(cursorOffset: state.cursorOffset)
    }
}
