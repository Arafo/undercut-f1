import Foundation

struct Formula1TokenValidator {
    enum AuthenticationResult {
        case success
        case noToken
        case invalidToken
        case invalidSubscriptionStatus
        case expiredToken
    }

    struct TokenPayload: Codable, Sendable {
        let subscriptionStatus: String
        let subscribedProduct: String?
        let exp: Int
        let iat: Int

        var expiryDate: Date { Date(timeIntervalSince1970: TimeInterval(exp)) }
        var issuedDate: Date { Date(timeIntervalSince1970: TimeInterval(iat)) }
    }

    struct ValidationResult {
        let status: AuthenticationResult
        let payload: TokenPayload?
        let subscriptionToken: String?
    }

    func validate(token: String?) -> ValidationResult {
        guard let token, !token.isEmpty else {
            return ValidationResult(status: .noToken, payload: nil, subscriptionToken: nil)
        }

        guard let subscriptionToken = subscriptionToken(from: token),
              let payload = payload(from: subscriptionToken) else {
            return ValidationResult(status: .invalidToken, payload: nil, subscriptionToken: nil)
        }

        guard payload.subscriptionStatus.lowercased() == "active" else {
            return ValidationResult(status: .invalidSubscriptionStatus, payload: payload, subscriptionToken: subscriptionToken)
        }

        guard payload.expiryDate > Date() else {
            return ValidationResult(status: .expiredToken, payload: payload, subscriptionToken: subscriptionToken)
        }

        return ValidationResult(status: .success, payload: payload, subscriptionToken: subscriptionToken)
    }

    private func subscriptionToken(from token: String) -> String? {
        guard let decoded = token.removingPercentEncoding,
              let data = decoded.data(using: .utf8) else { return nil }

        guard
            let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let dataObject = object["data"] as? [String: Any],
            let subscriptionToken = dataObject["subscriptionToken"] as? String
        else {
            return nil
        }

        return subscriptionToken
    }

    private func payload(from subscriptionToken: String) -> TokenPayload? {
        let segments = subscriptionToken.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var payloadSegment = String(segments[1])
        payloadSegment = payloadSegment.replacingOccurrences(of: "-", with: "+")
        payloadSegment = payloadSegment.replacingOccurrences(of: "_", with: "/")
        let missingPadding = payloadSegment.count % 4
        if missingPadding > 0 {
            payloadSegment += String(repeating: "=", count: 4 - missingPadding)
        }

        guard let data = Data(base64Encoded: payloadSegment) else { return nil }
        return try? JSONDecoder().decode(TokenPayload.self, from: data)
    }
}
