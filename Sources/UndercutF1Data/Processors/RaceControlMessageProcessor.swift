import Foundation

public final class RaceControlMessageProcessor: ProcessorBase<RaceControlMessageDataPoint> {
    private let notifyService: NotifyService
    private var newMessageKeys: Set<String> = []

    public init(notifyService: NotifyService) {
        self.notifyService = notifyService
        super.init()
    }

    public override func willMerge(update: inout RaceControlMessageDataPoint, timestamp: Date) async {
        newMessageKeys = Set(update.messages.keys.filter { latest.messages[$0] == nil })
    }

    public override func didMerge(update: RaceControlMessageDataPoint, timestamp: Date) async {
        for key in newMessageKeys {
            guard let message = latest.messages[key] else { continue }
            if !message.message.uppercased().hasPrefix("WAVED BLUE FLAG") {
                notifyService.sendNotification()
            }
        }
        newMessageKeys.removeAll()
    }
}
