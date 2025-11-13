import Foundation

public protocol TeamRadioDisplayDataSource {
    func makeTeamRadioContent(cursorOffset: Int) async throws -> RenderNode
}

public final class TeamRadioDisplay: Display {
    public let screen: Screen = .teamRadio

    private let state: State
    private let dataSource: TeamRadioDisplayDataSource

    public init(state: State, dataSource: TeamRadioDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeTeamRadioContent(cursorOffset: state.cursorOffset)
    }
}
