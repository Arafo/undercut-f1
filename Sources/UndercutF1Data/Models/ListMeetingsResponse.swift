import Foundation

public struct ListMeetingsApiResponse: Codable, Sendable {
    public var year: Int
    public var meetings: [Meeting]

    public struct Meeting: Codable, Sendable {
        public var key: Int
        public var name: String
        public var location: String
        public var sessions: [Session]

        public struct Session: Codable, Sendable {
            public var key: Int
            public var name: String
            public var type: String
            public var startDate: Date
            public var endDate: Date
            public var gmtOffset: String
            public var path: String?
        }
    }
}
