import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
    case transcriptionFailed(String)
    case commandNotFound(String)
}

public final class WhisperTranscriptionProvider: TranscriptionProviding, @unchecked Sendable {
    private let options: LiveTimingOptions
    private let expectedModelFileSize = 574_041_195
    private var downloadedBytes: Int64 = 0
    private let ffmpegCommand: String
    private let whisperCommand: String
    private let downloadURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin")!

    public init(
        options: LiveTimingOptions,
        ffmpegCommand: String? = nil,
        whisperCommand: String? = nil
    ) {
        self.options = options
        self.ffmpegCommand = ffmpegCommand ?? ProcessInfo.processInfo.environment["UNDERCUTF1_FFMPEG"] ?? "ffmpeg"
        self.whisperCommand = whisperCommand ?? ProcessInfo.processInfo.environment["UNDERCUTF1_WHISPER"] ?? "whisper"
    }

    public var modelPath: URL {
        options.dataDirectory
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("ggml-large-v3-turbo-q5.bin")
    }

    public var isModelDownloaded: Bool {
        FileManager.default.fileExists(atPath: modelPath.path)
    }

    public var downloadProgress: Double {
        if isModelDownloaded { return 1.0 }
        guard expectedModelFileSize > 0 else { return 0.0 }
        return Double(downloadedBytes) / Double(expectedModelFileSize)
    }

    public func ensureModelDownloaded() async throws {
        if isModelDownloaded { return }

        let directory = modelPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let tempURL = directory.appendingPathComponent(UUID().uuidString)
        guard FileManager.default.createFile(atPath: tempURL.path, contents: nil) else {
            throw TranscriptionError.downloadFailed
        }

        let handle = try FileHandle(forWritingTo: tempURL)
        downloadedBytes = 0
        do {
            let (bytes, _) = try await URLSession.shared.bytes(from: downloadURL)
            for try await chunk in bytes {
                downloadedBytes += Int64(chunk.count)
                try handle.write(contentsOf: chunk)
            }
            try handle.close()
            if FileManager.default.fileExists(atPath: modelPath.path) {
                try FileManager.default.removeItem(at: modelPath)
            }
            try FileManager.default.moveItem(at: tempURL, to: modelPath)
            downloadedBytes = 0
        } catch {
            downloadedBytes = 0
            try? handle.close()
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }

    public func transcribe(from file: URL) async throws -> String {
        try await ensureModelDownloaded()

        let cacheURL = try cachedTranscriptURL(for: file)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return try String(contentsOf: cacheURL)
        }

        let wavURL = file.appendingPathExtension("wav")
        if !FileManager.default.fileExists(atPath: wavURL.path) {
            try runCommand(ffmpegCommand, arguments: ["-y", "-i", file.path, "-ar", "16000", wavURL.path])
        }

        let outputBase = wavURL.deletingPathExtension().path
        try runCommand(
            whisperCommand,
            arguments: [
                "-m",
                modelPath.path,
                "-f",
                wavURL.path,
                "-otxt",
                "-of",
                outputBase,
                "--language",
                "auto"
            ]
        )

        let transcriptURL = URL(fileURLWithPath: outputBase + ".txt")
        guard FileManager.default.fileExists(atPath: transcriptURL.path) else {
            throw TranscriptionError.transcriptionFailed("No transcript produced")
        }
        let text = try String(contentsOf: transcriptURL)
        try persistTranscript(text, to: cacheURL)
        return text
    }

    private func runCommand(_ command: String, arguments: [String]) throws {
        #if os(Windows)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        #else
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        #endif
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            throw TranscriptionError.commandNotFound(command)
        }
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw TranscriptionError.transcriptionFailed(output)
        }
    }

    private func cachedTranscriptURL(for file: URL) throws -> URL {
        let cacheDirectory = options.dataDirectory.appendingPathComponent("transcripts", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let identifier = Data(file.path.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return cacheDirectory.appendingPathComponent(identifier).appendingPathExtension("txt")
    }

    private func persistTranscript(_ text: String, to url: URL) throws {
        let data = text.data(using: .utf8) ?? Data()
        try data.write(to: url, options: [.atomic])
    }
}
