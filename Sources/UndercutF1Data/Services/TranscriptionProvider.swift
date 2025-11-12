import Foundation

public protocol TranscriptionProviding: Sendable {
    var isModelDownloaded: Bool { get }
    var modelPath: URL { get }
    var downloadProgress: Double { get }
    func transcribe(from file: URL) async throws -> String
    func ensureModelDownloaded() async throws
}

public enum TranscriptionError: Error {
    case unsupportedPlatform
    case downloadFailed
}

public struct StubTranscriptionProvider: TranscriptionProviding {
    public let modelPath: URL
    public var isModelDownloaded: Bool { FileManager.default.fileExists(atPath: modelPath.path) }
    public var downloadProgress: Double { isModelDownloaded ? 1.0 : 0.0 }

    public init(options: LiveTimingOptions) {
        self.modelPath = options.dataDirectory.appendingPathComponent("models/ggml-large-v3-turbo-q5.bin")
    }

    public func transcribe(from file: URL) async throws -> String {
        throw TranscriptionError.unsupportedPlatform
    }

    public func ensureModelDownloaded() async throws {
        guard isModelDownloaded else {
            throw TranscriptionError.downloadFailed
        }
    }
}
