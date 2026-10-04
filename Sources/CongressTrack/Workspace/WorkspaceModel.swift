import Foundation
import Observation

@MainActor
@Observable
final class WorkspaceModel {
    var route: WorkspaceRoute? = .all
    var filters = TradeFilters()
    var selectedID: Trade.ID?
    var showInspector = false
    var sortOrder = [KeyPathComparator(\Trade.filedAt, order: .reverse)]
    private(set) var rows: [Trade] = []
    private(set) var politicianCount = 0
    private(set) var purchases = 0
    private(set) var sales = 0
    private(set) var filtering = false
    var selected: Trade? { rows.first { $0.id == selectedID } }

    func applyRoute(searches: [SavedSearch]) {
        selectedID = nil; showInspector = false
        filters.memberKey = nil; filters.ticker = nil
        switch route {
        case .member(let key): filters = TradeFilters(); filters.memberKey = key
        case .ticker(let ticker): filters = TradeFilters(); filters.ticker = ticker
        case .savedSearch(let id):
            if let saved = searches.first(where: { $0.id == id }) { filters = TradeFilters(saved: saved) }
        default: break
        }
    }

    func refresh(_ trades: [Trade], query: TradeQuery) async {
        filtering = true
        do {
            let filtered = try await query.evaluate(trades)
            try Task.checkCancellation()
            rows = filtered.sorted(using: sortOrder)
            politicianCount = Set(filtered.map { $0.member.key }).count
            purchases = filtered.count { $0.side == "buy" }
            sales = filtered.count { $0.side == "sell" }
            if selected == nil { selectedID = nil; showInspector = false }
            filtering = false
        } catch { /* A newer structured task owns the next result. */ }
    }

    func clearFilters() {
        filters = TradeFilters()
        switch route {
        case .member, .ticker, .savedSearch: route = .all
        default: break
        }
    }

    func sort() { rows.sort(using: sortOrder) }
}
