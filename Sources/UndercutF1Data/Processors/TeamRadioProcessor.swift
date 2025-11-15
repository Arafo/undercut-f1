import Foundation

public final class TeamRadioProcessor: ProcessorBase<TeamRadioDataPoint> {
    private let sessionInfoProcessor: SessionInfoProcessor
    private let transcriptionProvider: TranscriptionProviding
    private let httpClientFactory: HTTPClientFactory
    private let notifyService: NotifyService
    private var newCaptureKeys: Set<String> = []

    public init(
        sessionInfoProcessor: SessionInfoProcessor,
        transcriptionProvider: TranscriptionProviding,
        httpClientFactory: HTTPClientFactory,
        notifyService: NotifyService
    ) {
        self.sessionInfoProcessor = sessionInfoProcessor
        self.transcriptionProvider = transcriptionProvider
        self.httpClientFactory = httpClientFactory
        self.notifyService = notifyService
        super.init()
    }

    public var ordered: [String: TeamRadioDataPoint.Capture] {
        latest.ordered
    }

    public override func willMerge(update: inout TeamRadioDataPoint, timestamp: Date) async {
        newCaptureKeys = Set(update.captures.keys.filter { latest.captures[$0] == nil })
    }

    public override func didMerge(update: TeamRadioDataPoint, timestamp: Date) async {
        guard !newCaptureKeys.isEmpty else { return }
        notifyService.sendNotification()
        newCaptureKeys.removeAll()
    }

    public func downloadTeamRadioToFile(key: String) async throws -> URL {
        guard var capture = latest.captures[key] else {
            throw NSError(domain: "TeamRadioProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown capture key \(key)"])
        }

        if let path = capture.downloadedFilePath, FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        guard let sessionPath = sessionInfoProcessor.latest.path, let radioPath = capture.path else {
            throw NSError(domain: "TeamRadioProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing session path or capture path"])
        }

        let downloadPath = "https://livetiming.formula1.com/static/\(sessionPath)\(radioPath)"
        guard let url = httpClientFactory.url(for: downloadPath, client: .default) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await httpClientFactory.data(for: url, client: .default)
        let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(radioPath.replacingOccurrences(of: "TeamRadio/", with: ""))
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)

        capture.downloadedFilePath = destination.path
        mutateLatest { latest in
            latest.captures[key] = capture
        }

        return destination
    }

    public func transcribe(key: String) async throws -> String {
        let fileURL = try await downloadTeamRadioToFile(key: key)
        try await transcriptionProvider.ensureModelDownloaded()
        let text = try await transcriptionProvider.transcribe(from: fileURL)
        mutateLatest { latest in
            if var capture = latest.captures[key] {
                capture.transcription = text
                latest.captures[key] = capture
            }
        }
        return text
    }
}
