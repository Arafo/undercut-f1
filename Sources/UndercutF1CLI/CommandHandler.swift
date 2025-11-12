import Foundation

enum CommandHandler {
    static func root(options: RootOptions) {
        let configuration = RootConfiguration(
            isApiEnabled: options.isApiEnabled,
            dataDirectory: options.dataDirectory,
            logDirectory: options.logDirectory,
            isVerbose: options.isVerbose,
            notify: options.notify,
            preferFfmpeg: options.preferFfmpeg,
            forcedGraphicsProtocol: options.forcedGraphicsProtocol
        )
        SwiftServices.shared.handleRoot(configuration: configuration)
    }

    static func importSession(
        year: Int,
        meetingKey: Int?,
        sessionKey: Int?,
        dataDirectory: String?,
        logDirectory: String?,
        isVerbose: Bool?
    ) {
        let request = ImportRequest(
            year: year,
            meetingKey: meetingKey,
            sessionKey: sessionKey,
            dataDirectory: dataDirectory,
            logDirectory: logDirectory,
            isVerbose: isVerbose
        )
        SwiftServices.shared.importSession(request: request)
    }

    static func getInfo(
        dataDirectory: String?,
        logDirectory: String?,
        isVerbose: Bool?,
        notify: Bool?,
        preferFfmpeg: Bool?,
        forcedGraphicsProtocol: GraphicsProtocol?
    ) {
        let request = InfoRequest(
            dataDirectory: dataDirectory,
            logDirectory: logDirectory,
            isVerbose: isVerbose,
            notify: notify,
            preferFfmpeg: preferFfmpeg,
            forcedGraphicsProtocol: forcedGraphicsProtocol
        )
        SwiftServices.shared.printInfo(request: request)
    }

    static func outputImage(
        filePath: String,
        graphicsProtocol: GraphicsProtocol,
        isVerbose: Bool?
    ) {
        let request = ImageRequest(
            filePath: filePath,
            graphicsProtocol: graphicsProtocol,
            isVerbose: isVerbose
        )
        SwiftServices.shared.renderImage(request: request)
    }

    static func login(isVerbose: Bool?) {
        let request = LoginRequest(isVerbose: isVerbose)
        SwiftServices.shared.login(request: request)
    }

    static func logout() {
        SwiftServices.shared.logout()
    }
}

struct RootConfiguration: Codable {
    var isApiEnabled: Bool?
    var dataDirectory: String?
    var logDirectory: String?
    var isVerbose: Bool?
    var notify: Bool?
    var preferFfmpeg: Bool?
    var forcedGraphicsProtocol: GraphicsProtocol?
}

struct ImportRequest: Codable {
    var year: Int
    var meetingKey: Int?
    var sessionKey: Int?
    var dataDirectory: String?
    var logDirectory: String?
    var isVerbose: Bool?
}

struct InfoRequest: Codable {
    var dataDirectory: String?
    var logDirectory: String?
    var isVerbose: Bool?
    var notify: Bool?
    var preferFfmpeg: Bool?
    var forcedGraphicsProtocol: GraphicsProtocol?
}

struct ImageRequest: Codable {
    var filePath: String
    var graphicsProtocol: GraphicsProtocol
    var isVerbose: Bool?
}

struct LoginRequest: Codable {
    var isVerbose: Bool?
}

final class SwiftServices {
    static let shared = SwiftServices()

    func handleRoot(configuration: RootConfiguration) {
        logInvocation("root", payload: configuration)
    }

    func importSession(request: ImportRequest) {
        logInvocation("import", payload: request)
    }

    func printInfo(request: InfoRequest) {
        logInvocation("info", payload: request)
    }

    func renderImage(request: ImageRequest) {
        logInvocation("image", payload: request)
    }

    func login(request: LoginRequest) {
        logInvocation("login", payload: request)
    }

    func logout() {
        print("[logout] invoked")
    }

    private func logInvocation<T: Encodable>(_ command: String, payload: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        if let data = try? encoder.encode(payload),
           let json = String(data: data, encoding: .utf8) {
            print("[\(command)]")
            print(json)
        } else {
            print("[\(command)]")
            dump(payload)
        }
    }
}
