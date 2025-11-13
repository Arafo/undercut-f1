import Vapor
import UndercutF1Host

extension Response {
    static func json(
        _ encodable: AnyEncodable,
        status: HTTPResponseStatus = .ok
    ) throws -> Response {
        let data = try JSONCoders.encoder.encode(encodable)
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json; charset=utf-8")
        return Response(status: status, headers: headers, body: .init(data: data))
    }
}
