import Foundation

public struct Formula1Account: Sendable {
    public enum AuthenticationResult: Sendable {
        case success
        case noToken
        case invalidToken
        case invalidSubscriptionStatus
        case expiredToken
    }

    public struct TokenPayload: Sendable {
        public let subscriptionStatus: String
        public let subscribedProduct: String?
        public let exp: Int
        public let iat: Int

        public var expiry: Date { Date(timeIntervalSince1970: TimeInterval(exp)) }
        public var issuedAt: Date { Date(timeIntervalSince1970: TimeInterval(iat)) }

        init?(jsonObject: [String: Any]) {
            func string(for keys: [String]) -> String? {
                for key in keys {
                    if let value = jsonObject[key] as? String {
                        return value
                    }
                }
                return nil
            }

            func intValue(for keys: [String]) -> Int? {
                for key in keys {
                    if let value = jsonObject[key] as? Int {
                        return value
                    }
                    if let value = jsonObject[key] as? Double {
                        return Int(value)
                    }
                    if let value = jsonObject[key] as? String, let parsed = Int(value) {
                        return parsed
                    }
                }
                return nil
            }

            guard let subscriptionStatus = string(for: ["subscriptionStatus", "SubscriptionStatus"]),
                  let exp = intValue(for: ["exp", "Exp"]),
                  let iat = intValue(for: ["iat", "Iat"]) else {
                return nil
            }

            self.subscriptionStatus = subscriptionStatus
            self.subscribedProduct = string(for: ["subscribedProduct", "SubscribedProduct"])
            self.exp = exp
            self.iat = iat
        }
    }

    public struct ValidationResult: Sendable {
        public let result: AuthenticationResult
        public let payload: TokenPayload?
        public let accessToken: String?
    }

    public let accessToken: String
    public let payload: TokenPayload

    public init?(token: String) {
        let validation = Formula1Account.validate(token: token)
        guard validation.result == .success,
              let payload = validation.payload,
              let accessToken = validation.accessToken else {
            return nil
        }

        self.accessToken = accessToken
        self.payload = payload
    }

    public static func validate(token: String?) -> ValidationResult {
        guard let token = token?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            return ValidationResult(result: .noToken, payload: nil, accessToken: nil)
        }

        guard let payload = tokenPayload(from: token) else {
            return ValidationResult(result: .invalidToken, payload: nil, accessToken: nil)
        }

        guard payload.subscriptionStatus.lowercased() == "active" else {
            return ValidationResult(result: .invalidSubscriptionStatus, payload: payload, accessToken: nil)
        }

        guard payload.expiry > Date() else {
            return ValidationResult(result: .expiredToken, payload: payload, accessToken: nil)
        }

        guard let subscriptionToken = subscriptionToken(from: token) else {
            return ValidationResult(result: .invalidToken, payload: payload, accessToken: nil)
        }

        return ValidationResult(result: .success, payload: payload, accessToken: subscriptionToken)
    }

    private static func subscriptionToken(from token: String) -> String? {
        let decoded = token.removingPercentEncoding ?? token
        guard let data = decoded.data(using: .utf8) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let dataNode = json["data"] as? [String: Any],
              let subscriptionToken = dataNode["subscriptionToken"] as? String else {
            return nil
        }
        return subscriptionToken
    }

    private static func tokenPayload(from token: String) -> TokenPayload? {
        guard let subscriptionToken = subscriptionToken(from: token) else { return nil }
        let segments = subscriptionToken.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var payloadSegment = String(segments[1])
        let padding = payloadSegment.count % 4
        if padding > 0 {
            payloadSegment.append(String(repeating: "=", count: 4 - padding))
        }

        guard let data = Data(base64Encoded: payloadSegment, options: [.ignoreUnknownCharacters]) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return TokenPayload(jsonObject: json)
    }
}
