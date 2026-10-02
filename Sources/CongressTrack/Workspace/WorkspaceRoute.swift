import Foundation

enum WorkspaceRoute: Hashable, Identifiable, CaseIterable {
    case all, leaderboard, watchlist, members, alerts
    case member(String), ticker(String), savedSearch(UUID)
    static let allCases: [WorkspaceRoute] = [.all, .leaderboard, .watchlist, .members, .alerts]
    var id: Self { self }
    var title: String {
        switch self {
        case .all: "Disclosures"
        case .leaderboard: "Leaderboard"
        case .watchlist: "Watchlist"
        case .members: "Politicians"
        case .alerts: "Alerts"
        case .member: "Politician disclosures"
        case .ticker: "Stock disclosures"
        case .savedSearch: "Saved search"
        }
    }
    var icon: String {
        switch self {
        case .all: "doc.text.magnifyingglass"
        case .leaderboard: "trophy"
        case .watchlist: "star"
        case .members: "person.2"
        case .alerts: "bell"
        case .member: "person.crop.circle"
        case .ticker: "chart.line.uptrend.xyaxis"
        case .savedSearch: "line.3.horizontal.decrease.circle"
        }
    }
}
