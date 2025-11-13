import Foundation

public protocol ManageSessionDisplayDataSource {
    func makeManageSessionContent() async throws -> RenderNode
}

public final class ManageSessionDisplay: Display {
    public let screen: Screen = .manageSession

    private let dataSource: ManageSessionDisplayDataSource

    public init(dataSource: ManageSessionDisplayDataSource) {
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeManageSessionContent()
    }
}
