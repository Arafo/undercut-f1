import Foundation

public protocol InfoDisplayDataSource {
    func makeInfoContent() async throws -> RenderNode
}

public final class InfoDisplay: Display {
    public let screen: Screen = .info

    private let dataSource: InfoDisplayDataSource

    public init(dataSource: InfoDisplayDataSource) {
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeInfoContent()
    }
}
