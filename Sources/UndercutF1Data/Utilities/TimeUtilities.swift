import Foundation

enum TimeUtilities {
    static func parseTimeSpan(_ string: String) -> TimeInterval? {
        let formats = ["HH:mm:ss", "m:ss.SSS", "ss.SSS", "m:ss", "ss"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                let components = Calendar(identifier: .gregorian)
                    .dateComponents([.hour, .minute, .second, .nanosecond], from: date)
                let hours = Double(components.hour ?? 0)
                let minutes = Double(components.minute ?? 0)
                let seconds = Double(components.second ?? 0)
                let nanoseconds = Double(components.nanosecond ?? 0)
                return hours * 3600 + minutes * 60 + seconds + nanoseconds / 1_000_000_000
            }
        }

        if string.contains(":") {
            let parts = string.split(separator: ":")
            if parts.count == 2,
               let minutes = Double(parts[0]),
               let seconds = Double(parts[1]) {
                return minutes * 60 + seconds
            }
        }

        return Double(string)
    }
}
