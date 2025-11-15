import ArgumentParser
import Foundation

struct InfoCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Print diagnostics about undercutf1"
    )

    @OptionGroup()
    var global: GlobalOptions

    func run() async throws {
        let builder = ServiceContainerBuilder()
        let services = builder.bootstrap(commandLine: global.asConsoleOptions())
        services.logger.info("Collecting terminal diagnostics")

        let reporter = TerminalInfoReporter()
        let report = reporter.collect(using: services)

        var lines: [String] = []
        lines.append("UndercutF1 Diagnostics\n======================")
        lines.append("Data Directory : \(services.options.dataDirectory.path)")
        lines.append("Log Directory  : \(services.options.logDirectory.path)")
        lines.append("API Enabled    : \(report.apiEnabled ? "Yes" : "No")")
        lines.append("Notifications  : \(report.notifyEnabled ? "Enabled" : "Muted")")
        lines.append("Prefer FFmpeg  : \(report.preferFfmpeg ? "Yes" : "No")")
        if let term = report.term {
            lines.append("TERM           : \(term)")
        }
        if let program = report.termProgram {
            lines.append("TERM_PROGRAM   : \(program)")
        }
        if let shell = report.shell {
            lines.append("Shell         : \(shell)")
        }
        if let cols = report.columns, let rows = report.rows {
            lines.append("Size          : \(cols)x\(rows) cells")
        }
        if let forced = report.forcedProtocol {
            lines.append("Graphics Mode  : Forced \(forced.rawValue)")
        }
        lines.append("Graphics Support:")
        for protocolType in GraphicsProtocol.allCases {
            let supported = report.graphicsSupport[protocolType] ?? false
            let indicator = supported ? "✅" : "❌"
            lines.append("  \(indicator) \(protocolType.rawValue)")
        }

        print(lines.joined(separator: "\n"))
    }
}
