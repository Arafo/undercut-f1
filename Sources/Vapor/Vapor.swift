import Foundation

public struct Environment: Sendable, Equatable {
    public let name: String

    public init(name: String) {
        self.name = name
    }

    public static let development = Environment(name: "development")
    public static let testing = Environment(name: "testing")
}

public struct HTTPResponseStatus: Equatable, Sendable {
    public let code: Int
    public let reasonPhrase: String

    public init(statusCode: Int, reasonPhrase: String) {
        self.code = statusCode
        self.reasonPhrase = reasonPhrase
    }

    public static let ok = HTTPResponseStatus(statusCode: 200, reasonPhrase: "OK")
    public static let badRequest = HTTPResponseStatus(statusCode: 400, reasonPhrase: "Bad Request")
    public static let notFound = HTTPResponseStatus(statusCode: 404, reasonPhrase: "Not Found")
}

public struct HTTPHeaders: Sendable, Equatable {
    private var storage: [String: String] = [:]

    public init() {}

    public mutating func add(name: Name, value: String) {
        storage[name.rawValue] = value
    }

    public struct Name: RawRepresentable, Sendable, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let contentType = Name(rawValue: "Content-Type")
    }
}

public struct Response: Sendable, Equatable {
    public struct Body: Equatable, Sendable {
        public var data: Data

        public init(data: Data) {
            self.data = data
        }
    }

    public var status: HTTPResponseStatus
    public var headers: HTTPHeaders
    public var body: Body

    public init(
        status: HTTPResponseStatus = .ok,
        headers: HTTPHeaders = HTTPHeaders(),
        body: Body = Body(data: Data())
    ) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

extension Response: ResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        self
    }
}

public protocol AbortError: Error {
    var status: HTTPResponseStatus { get }
    var reason: String { get }
}

public struct Abort: AbortError {
    public let status: HTTPResponseStatus
    public let reason: String

    public init(_ status: HTTPResponseStatus, reason: String? = nil) {
        self.status = status
        self.reason = reason ?? status.reasonPhrase
    }
}

public protocol ResponseEncodable {
    func encodeResponse(for request: Request) async throws -> Response
}

public protocol Content: ResponseEncodable, Codable {}

public extension Content {
    func encodeResponse(for request: Request) async throws -> Response {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return Response(status: .ok, headers: HTTPHeaders(), body: .init(data: data))
    }
}

public struct ContentConfiguration {
    public enum MediaType {
        case json
    }

    public var encoders: [MediaType: JSONEncoder]
    public var decoders: [MediaType: JSONDecoder]

    public init(encoders: [MediaType: JSONEncoder] = [:], decoders: [MediaType: JSONDecoder] = [:]) {
        self.encoders = encoders
        self.decoders = decoders
    }

    public mutating func use(encoder: JSONEncoder, for mediaType: MediaType) {
        encoders[mediaType] = encoder
    }

    public mutating func use(decoder: JSONDecoder, for mediaType: MediaType) {
        decoders[mediaType] = decoder
    }
}

public final class Request: @unchecked Sendable {
    public struct Parameters: Sendable {
        private var values: [String: String]

        public init(values: [String: String] = [:]) {
            self.values = values
        }

        public func get<T>(_ name: String, as type: T.Type = T.self) -> T? where T: LosslessStringConvertible {
            guard let value = values[name] else { return nil }
            return T(value)
        }

        public mutating func set(_ name: String, value: String) {
            values[name] = value
        }
    }

    public final class ContentContainer: @unchecked Sendable {
        private var data: Data?
        private let decoderProvider: () -> JSONDecoder

        public init(data: Data? = nil, decoderProvider: @escaping () -> JSONDecoder = { JSONDecoder() }) {
            self.data = data
            self.decoderProvider = decoderProvider
        }

        public func decode<T: Decodable>(_ type: T.Type) throws -> T {
            guard let data else {
                throw Abort(.badRequest, reason: "Request body is missing")
            }
            return try decoderProvider().decode(T.self, from: data)
        }

        public func store<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws {
            data = try encoder.encode(value)
        }
    }

    public var parameters: Parameters
    public let content: ContentContainer

    public init(parameters: Parameters = Parameters(), body: Data? = nil) {
        self.parameters = parameters
        self.content = ContentContainer(data: body)
    }
}

public final class Application: @unchecked Sendable {
    public struct Route: Sendable, Equatable {
        public enum Method: Sendable, Equatable {
            case get
            case post
        }

        public let method: Method
        public let path: [String]
    }

    public final class HTTP: @unchecked Sendable {
        public final class Server: @unchecked Sendable {
            public struct Configuration: Sendable, Equatable {
                public var hostname: String
                public var port: Int

                public init(hostname: String = "127.0.0.1", port: Int = 8080) {
                    self.hostname = hostname
                    self.port = port
                }
            }

            public var configuration: Configuration

            public init(configuration: Configuration = Configuration()) {
                self.configuration = configuration
            }
        }

        public let server: Server

        public init(server: Server = Server()) {
            self.server = server
        }
    }

    public let environment: Environment
    public let http: HTTP
    public var contentConfiguration: ContentConfiguration

    private(set) public var registeredRoutes: [Route]
    private var running = false

    public init(_ environment: Environment) {
        self.environment = environment
        self.http = HTTP()
        self.contentConfiguration = ContentConfiguration()
        self.registeredRoutes = []
    }

    @discardableResult
    public func get<T: ResponseEncodable>(
        _ path: String...,
        use handler: @escaping (Request) async throws -> T
    ) -> Route {
        let route = Route(method: .get, path: path)
        registeredRoutes.append(route)
        return route
    }

    @discardableResult
    public func post<T: ResponseEncodable>(
        _ path: String...,
        use handler: @escaping (Request) async throws -> T
    ) -> Route {
        let route = Route(method: .post, path: path)
        registeredRoutes.append(route)
        return route
    }

    public func start() throws {
        running = true
    }

    public func shutdown() {
        running = false
    }

    deinit {
        shutdown()
    }
}
