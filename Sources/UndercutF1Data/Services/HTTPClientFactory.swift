import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class HTTPClientFactory: @unchecked Sendable {
    public enum ClientType {
        case `default`
        case proxy
    }

    private let defaultSession: URLSession
    private let proxySession: URLSession
    private let proxyBaseURL: URL?

    public init(userAgent: String, proxyBaseURL: URL?) {
        let defaultConfig = URLSessionConfiguration.default
        defaultConfig.httpAdditionalHeaders = ["User-Agent": userAgent]
        defaultConfig.timeoutIntervalForRequest = 30
        defaultSession = URLSession(configuration: defaultConfig)

        let proxyConfig = URLSessionConfiguration.default
        proxyConfig.httpAdditionalHeaders = [
            "User-Agent": userAgent,
            "Connection": "close"
        ]
        proxyConfig.timeoutIntervalForRequest = 30
        proxySession = URLSession(configuration: proxyConfig)
        self.proxyBaseURL = proxyBaseURL
    }

    public func url(for path: String, client: ClientType) -> URL? {
        switch client {
        case .default:
            return URL(string: path)
        case .proxy:
            if let absolute = URL(string: path), absolute.scheme != nil {
                return absolute
            }
            guard let base = proxyBaseURL else { return URL(string: path) }
            var trimmed = path
            if trimmed.hasPrefix("/") {
                trimmed.removeFirst()
            }
            return base.appendingPathComponent(trimmed)
        }
    }

    public func data(for url: URL, client: ClientType) async throws -> (Data, URLResponse) {
        switch client {
        case .default:
            return try await defaultSession.data(from: url)
        case .proxy:
            return try await proxySession.data(from: url)
        }
    }

    public func data(for path: String, client: ClientType) async throws -> (Data, URLResponse) {
        guard let url = url(for: path, client: client) else {
            throw URLError(.badURL)
        }
        return try await data(for: url, client: client)
    }
}
