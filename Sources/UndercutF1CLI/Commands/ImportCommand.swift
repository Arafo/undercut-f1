import ArgumentParser
import Foundation
import UndercutF1Data

struct ImportCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import data from the F1 Live Timing API"
    )

    @OptionGroup()
    var global: GlobalOptions

    @Argument(help: "The year the meeting took place")
    var year: Int

    @Option(name: .customLong("meeting-key"), help: "Meeting key to inspect")
    var meetingKey: Int?

    @Option(name: .customLong("session-key"), help: "Session key to import")
    var sessionKey: Int?

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.info("Preparing import pipeline for year=\(year) meeting=\(meetingKey?.description ?? "*") session=\(sessionKey?.description ?? "*")")

        let importer = SessionArchiveImporter(httpClient: services.httpClient, logger: services.logger)
        let index = try await importer.fetchMeetings(for: year)

        guard let meetingKey else {
            renderMeetings(index)
            return
        }

        guard let meeting = index.meetings.first(where: { $0.key == meetingKey }) else {
            services.logger.error("Failed to find a meeting with key \(meetingKey)")
            renderMeetings(index)
            return
        }

        guard let sessionKey else {
            services.logger.info("Found \(meeting.sessions.count) sessions inside meeting \(meeting.key) \(meeting.name)")
            renderSessions(meeting)
            return
        }

        guard let session = meeting.sessions.first(where: { $0.key == sessionKey }) else {
            services.logger.error("Failed to find a session with key \(sessionKey) inside meeting \(meeting.key)")
            renderSessions(meeting)
            return
        }

        do {
            try await importer.importSession(
                year: year,
                meeting: meeting,
                session: session,
                dataDirectory: services.options.dataDirectory
            )
        } catch {
            services.logger.error("Import failed: \(error.localizedDescription)")
            throw error
        }
    }
}

private extension ImportCommand {
    func renderMeetings(_ index: MeetingIndex) {
        print("Available meetings for \(index.year)")
        let header = padded("Key", width: 8) + padded("Meeting", width: 40) + "Location"
        print(header)
        print(String(repeating: "-", count: header.count))
        for meeting in index.meetings {
            let line = padded(String(meeting.key), width: 8)
                + padded(meeting.name, width: 40)
                + meeting.location
            print(line)
        }
        print("")
    }

    func renderSessions(_ meeting: MeetingIndex.Meeting) {
        print("Available sessions for \(meeting.key) \(meeting.name)")
        let header = padded("Key", width: 8)
            + padded("Session", width: 28)
            + padded("Type", width: 12)
            + "Start (UTC)"
        print(header)
        print(String(repeating: "-", count: header.count))
        for session in meeting.sessions {
            let start = session.startDateUTCText ?? session.startDateText ?? "Unknown"
            let line = padded(String(session.key), width: 8)
                + padded(session.name, width: 28)
                + padded(session.type, width: 12)
                + start
            print(line)
        }
        print("")
    }

    func padded(_ value: String, width: Int) -> String {
        if value.count >= width { return value }
        return value + String(repeating: " ", count: width - value.count)
    }
}
