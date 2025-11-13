import Foundation

public protocol SessionStatsDisplayDataSource {
    func makeSessionStatsContent() async throws -> RenderNode
}

public final class SessionStatsDisplay: Display {
    public let screen: Screen = .sessionStats

    private let dataSource: SessionStatsDisplayDataSource

    public init(dataSource: SessionStatsDisplayDataSource) {
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeSessionStatsContent()
    }
}
