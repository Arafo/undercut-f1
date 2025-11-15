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

        let importer = SessionImporter(services: services)

        do {
            let response = try await importer.meetingIndex(for: year)
            if let meetingKey {
                if let sessionKey {
                    try await importer.importSession(year: year, meetingKey: meetingKey, sessionKey: sessionKey, response: response)
                    services.logger.info("Session import complete. Data saved under \(services.options.dataDirectory.path)")
                } else {
                    renderSessions(for: meetingKey, response: response)
                }
            } else {
                renderMeetings(response)
            }
        } catch {
            services.logger.error("Import failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func renderMeetings(_ response: MeetingIndexResponse) {
        let rows = response.meetings.map { meeting in
            ["#\(meeting.key)", meeting.name, meeting.location]
        }
        let table = TableRenderer(headers: ["Key", "Meeting", "Location"])
        print(table.render(rows: rows))
    }

    private func renderSessions(for key: Int, response: MeetingIndexResponse) {
        guard let meeting = response.meetings.first(where: { $0.key == key }) else {
            print("No meeting found with key \(key). Use `undercutf1 import \(year)` to view available options.")
            return
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let rows = meeting.sessions.sorted(by: { $0.startDate < $1.startDate }).map { session in
            let utcStart = session.startDate.addingTimeInterval(-session.gmtOffset)
            return [
                "#\(session.key)",
                session.name,
                session.type,
                formatter.string(from: utcStart)
            ]
        }
        let table = TableRenderer(headers: ["Key", "Session", "Type", "Start (UTC)"])
        print("Meeting #\(meeting.key) - \(meeting.name) \(meeting.location)\n")
        print(table.render(rows: rows))
    }
}

private struct TableRenderer {
    let headers: [String]

    func render(rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }
        var columnWidths = headers.map { $0.count }
        for row in rows {
            for (index, value) in row.enumerated() {
                if index < columnWidths.count {
                    columnWidths[index] = max(columnWidths[index], value.count)
                }
            }
        }

        func padded(_ text: String, width: Int) -> String {
            let padding = max(0, width - text.count)
            return text + String(repeating: " ", count: padding)
        }

        var output = String()
        var headerLine = ""
        for (index, header) in headers.enumerated() {
            headerLine += padded(header, width: columnWidths[index] + 2)
        }
        output.append(headerLine)
        output.append("\n")
        output.append(String(repeating: "-", count: headerLine.count))
        output.append("\n")

        for row in rows {
            var line = ""
            for (index, value) in row.enumerated() {
                if index < columnWidths.count {
                    line += padded(value, width: columnWidths[index] + 2)
                }
            }
            output.append(line)
            output.append("\n")
        }

        return output
    }
}
