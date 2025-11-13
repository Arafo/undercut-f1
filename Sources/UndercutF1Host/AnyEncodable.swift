import Foundation

public struct AnyEncodable: Encodable {
    private let encoder: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        encoder = value.encode
    }

    public func encode(to encoder: Encoder) throws {
        try self.encoder(encoder)
    }
}
