import ArgumentParser
import Foundation

struct RootOptions: ParsableArguments {
    @Option(name: .customLong("with-api"), help: "Whether the API endpoint should be exposed at http://localhost:61937")
    var isApiEnabled: Bool?

    @Option(name: .customLong("data-directory"), help: "The directory to which timing data will be read from and written to")
    var dataDirectory: String?

    @Option(name: .customLong("log-directory"), help: "The directory to which logs will be written to")
    var logDirectory: String?

    @Option(name: [.customLong("verbose"), .short], help: "Whether verbose logging should be enabled")
    var isVerbose: Bool?

    @Option(name: .customLong("notify"), help: "Whether audible BELs are sent to your terminal when new race control messages are received")
    var notify: Bool?

    @Option(name: .customLong("prefer-ffmpeg"), help: "Prefer ffplay for playing Team Radio on Mac/Linux, instead of afplay/mpg123")
    var preferFfmpeg: Bool?

    @Option(name: .customLong("force-graphics-protocol"), help: "Forces the usage of a particular graphics protocol.")
    var forcedGraphicsProtocol: GraphicsProtocol?
}

struct DirectoryOptions: ParsableArguments {
    @Option(name: .customLong("data-directory"), help: "The directory to which timing data will be read from and written to")
    var dataDirectory: String?

    @Option(name: .customLong("log-directory"), help: "The directory to which logs will be written to")
    var logDirectory: String?
}

struct VerboseOption: ParsableArguments {
    @Option(name: [.customLong("verbose"), .short], help: "Whether verbose logging should be enabled")
    var isVerbose: Bool?
}

struct GraphicsPreferences: ParsableArguments {
    @Option(name: .customLong("notify"), help: "Whether audible BELs are sent to your terminal when new race control messages are received")
    var notify: Bool?

    @Option(name: .customLong("prefer-ffmpeg"), help: "Prefer ffplay for playing Team Radio on Mac/Linux, instead of afplay/mpg123")
    var preferFfmpeg: Bool?

    @Option(name: .customLong("force-graphics-protocol"), help: "Forces the usage of a particular graphics protocol.")
    var forcedGraphicsProtocol: GraphicsProtocol?
}
