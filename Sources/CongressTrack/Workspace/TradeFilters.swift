import Foundation

struct TradeFilters: Hashable, Sendable {
    var search = ""
    var chamber = "all"
    var side = "all"
    var party = "all"
    var memberKey: String?
    var ticker: String?
    var useDates = false
    var since = Day.adding(-365, to: Date())
    var until = Date()
    var isActive: Bool {
        !search.isEmpty || chamber != "all" || side != "all" || party != "all" || memberKey != nil || ticker != nil || useDates
    }
    func matches(_ trade: Trade) -> Bool {
        trade.matches(search.trimmingCharacters(in: .whitespacesAndNewlines)) &&
        (chamber == "all" || trade.chamber == chamber) &&
        (side == "all" || trade.side == side) &&
        (party == "all" || trade.member.party == party) &&
        (memberKey == nil || trade.member.key == memberKey) &&
        (ticker == nil || trade.ticker?.uppercased() == ticker) &&
        (!useDates || (trade.filedAt >= Day.string(since) && trade.filedAt <= Day.string(until)))
    }
    init() {}
    init(saved: SavedSearch) {
        search = saved.query; chamber = saved.chamber; side = saved.side; party = saved.party
        memberKey = saved.memberKey; ticker = saved.ticker; useDates = saved.since != nil
        since = saved.since.flatMap(Day.parse) ?? since
        until = saved.until.flatMap(Day.parse) ?? until
    }
    func saved(name: String) -> SavedSearch {
        SavedSearch(name: name, query: search, chamber: chamber, side: side, party: party,
                    memberKey: memberKey, since: useDates ? Day.string(since) : nil,
                    until: useDates ? Day.string(until) : nil, ticker: ticker)
    }
}
