import Foundation

enum Day {
    static let format = Date.ISO8601FormatStyle().year().month().day().dateSeparator(.dash)
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = .gmt
        return value
    }
    static func parse(_ value: String) -> Date? {
        guard let date = try? Date(value, strategy: format), string(date) == value else { return nil }
        return date
    }
    static func string(_ date: Date) -> String { date.formatted(format) }
    static func display(_ value: String) -> String {
        guard let date = parse(value) else { return value }
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))
    }
    static func adding(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}
