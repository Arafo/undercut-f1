import Foundation

public protocol StartSimulatedSessionDisplayDataSource {
    func makeStartSimulatedSessionContent(
        options: StartSimulatedSessionOptions,
        cursorOffset: Int
    ) async throws -> RenderNode
}

public final class StartSimulatedSessionDisplay: Display {
    public let screen: Screen = .startSimulatedSession

    private let state: State
    private let options: StartSimulatedSessionOptions
    private let dataSource: StartSimulatedSessionDisplayDataSource

    public init(
        state: State,
        options: StartSimulatedSessionOptions,
        dataSource: StartSimulatedSessionDisplayDataSource
    ) {
        self.state = state
        self.options = options
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeStartSimulatedSessionContent(
            options: options,
            cursorOffset: state.cursorOffset
        )
    }
}
