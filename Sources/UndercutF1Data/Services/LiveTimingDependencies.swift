import Foundation

public struct LiveTimingDependencies: @unchecked Sendable {
    public let options: LiveTimingOptions
    public let notifyService: NotifyService
    public let httpClientFactory: HTTPClientFactory
    public let transcriptionProvider: TranscriptionProviding
    public let dateTimeProvider: DateTimeProviding
    public let processors: LiveTimingProcessorCatalog
    public let timingService: TimingService
    public let liveTimingClient: LiveTimingClient
    public let formula1Account: Formula1Account?

    public init(
        options: LiveTimingOptions = LiveTimingOptions(),
        formula1Account: Formula1Account? = nil,
        notificationHandlers: [NotificationHandling]? = nil,
        userAgent: String? = nil,
        dateTimeProvider: DateTimeProviding = DateTimeProvider(),
        transcriptionProviderFactory: ((LiveTimingOptions) -> TranscriptionProviding)? = nil
    ) {
        self.options = options
        self.formula1Account = formula1Account

        let handlers = notificationHandlers ?? [BellNotificationHandler()]
        notifyService = NotifyService(handlers: handlers, options: options)

        let agent = userAgent ?? "undercut-f1-swift"
        httpClientFactory = HTTPClientFactory(
            userAgent: agent,
            proxyBaseURL: URL(string: "https://undercutf1.amandhoot.com")
        )

        let transcriptionProvider = transcriptionProviderFactory?(options) ?? WhisperTranscriptionProvider(options: options)
        self.transcriptionProvider = transcriptionProvider
        self.dateTimeProvider = dateTimeProvider

        processors = LiveTimingProcessorCatalog(
            dateTimeProvider: dateTimeProvider,
            notifyService: notifyService,
            httpClientFactory: httpClientFactory,
            transcriptionProvider: transcriptionProvider
        )

        timingService = TimingService(dateTimeProvider: dateTimeProvider, processors: processors.all)
        liveTimingClient = LiveTimingClient(
            timingService: timingService,
            options: options,
            formula1Account: formula1Account
        )
    }
}
