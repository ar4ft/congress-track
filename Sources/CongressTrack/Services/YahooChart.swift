import Foundation
import Observation

struct YahooChart: Decodable, Sendable {
    struct Chart: Decodable, Sendable {
        struct Result: Decodable, Sendable {
            struct Indicators: Decodable, Sendable {
                struct Adjusted: Decodable, Sendable { let adjclose: [Double?] }
                let adjclose: [Adjusted]?
            }
            let timestamp: [Int]?
            let indicators: Indicators
        }
        let result: [Result]?
    }
    let chart: Chart

    func bars() throws -> [PriceBar] {
        guard let result = chart.result?.first, let times = result.timestamp,
              let closes = result.indicators.adjclose?.first?.adjclose, times.count == closes.count else {
            throw PriceError.message("Provider did not return adjusted daily prices.")
        }
        let rows = zip(times, closes).compactMap { timestamp, value -> PriceBar? in
            guard let value, value.isFinite, value > 0 else { return nil }
            return PriceBar(date: Day.string(Date(timeIntervalSince1970: Double(timestamp))), close: value)
        }
        guard !rows.isEmpty else { throw PriceError.message("Provider returned no usable prices.") }
        // Today's quote can still be an intraday close; use completed UTC dates only.
        return rows.filter { $0.date < Day.string(Date()) }.sorted { $0.date < $1.date }
    }
}
