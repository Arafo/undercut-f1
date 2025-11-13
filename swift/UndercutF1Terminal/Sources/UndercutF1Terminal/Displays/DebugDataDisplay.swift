import Foundation

public protocol DebugDataDisplayDataSource {
    func makeDebugContent(cursorOffset: Int) async throws -> RenderNode
}

public final class DebugDataDisplay: Display {
    public let screen: Screen = .debug

    private let state: State
    private let dataSource: DebugDataDisplayDataSource

    public init(state: State, dataSource: DebugDataDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeDebugContent(cursorOffset: state.cursorOffset)
    }
}
