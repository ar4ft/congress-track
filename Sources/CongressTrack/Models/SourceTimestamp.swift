import Foundation

enum SourceTimestamp {
    static func display(_ value: String) -> String {
        let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        guard let date = (try? Date(value, strategy: fractional)) ?? (try? Date(value, strategy: .iso8601)) else {
            return value
        }
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: .gmt)) + " UTC"
    }
}
