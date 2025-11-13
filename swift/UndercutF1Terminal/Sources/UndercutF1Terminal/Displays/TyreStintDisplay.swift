import Foundation

public protocol TyreStintDisplayDataSource {
    func makeTyreStintContent(cursorOffset: Int) async throws -> RenderNode
}

public final class TyreStintDisplay: Display {
    public let screen: Screen = .tyreStint

    private let state: State
    private let dataSource: TyreStintDisplayDataSource

    public init(state: State, dataSource: TyreStintDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeTyreStintContent(cursorOffset: state.cursorOffset)
    }
}
