import Foundation

public protocol RaceControlDisplayDataSource {
    func makeRaceControlContent(cursorOffset: Int) async throws -> RenderNode
}

public final class RaceControlDisplay: Display {
    public let screen: Screen = .raceControl

    private let state: State
    private let dataSource: RaceControlDisplayDataSource

    public init(state: State, dataSource: RaceControlDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeRaceControlContent(cursorOffset: state.cursorOffset)
    }
}
