import Foundation

enum PriceCSV {
    // A deliberate, strict CSV contract; no silent coercion of malformed rows.
    static func parse(_ text: String) throws -> [String: [PriceBar]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let header = lines.first,
              header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "date,ticker,adjusted_close" else {
            throw PriceError.message("Expected CSV header: date,ticker,adjusted_close. Include SPY and use adjusted closes for every ticker.")
        }
        var result: [String: [PriceBar]] = [:]
        var keys = Set<String>()
        for (index, line) in lines.dropFirst().enumerated() {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count == 3, Day.parse(fields[0]) != nil, !fields[1].isEmpty,
                  let value = Double(fields[2]), value.isFinite, value > 0 else {
                throw PriceError.message("Invalid price row \(index + 2). Expected a valid date, ticker, and positive adjusted close.")
            }
            let ticker = fields[1].uppercased()
            guard keys.insert(ticker + ":" + fields[0]).inserted else { throw PriceError.message("Duplicate ticker/date on row \(index + 2).") }
            result[ticker, default: []].append(PriceBar(date: fields[0], close: value))
        }
        guard !(result["SPY"] ?? []).isEmpty else { throw PriceError.message("The price file must include SPY benchmark prices.") }
        return result.mapValues { $0.sorted { $0.date < $1.date } }
    }
}
