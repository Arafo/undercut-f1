import Foundation

public protocol DownloadTranscriptionModelDisplayDataSource {
    func makeDownloadContent() async throws -> RenderNode
}

public final class DownloadTranscriptionModelDisplay: Display {
    public let screen: Screen = .downloadTranscription

    private let dataSource: DownloadTranscriptionModelDisplayDataSource

    public init(dataSource: DownloadTranscriptionModelDisplayDataSource) {
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        try await dataSource.makeDownloadContent()
    }
}
