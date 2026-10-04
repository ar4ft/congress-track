import SwiftUI
import UniformTypeIdentifiers

struct LeaderboardView: View {
    @Environment(TradeStore.self) private var store
    @Environment(PriceStore.self) private var prices
    @State private var model = LeaderboardModel()
    @State private var importPrices = false
    @State private var showExcluded = false
    private var analysisKey: AnalysisRequest {
        AnalysisRequest(tradesRevision: store.revision, pricesRevision: prices.revision, window: model.window)
    }

    var body: some View {
        @Bindable var model = model
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                HStack {
                    Picker("Holding period", selection: $model.window) {
                        Text("30 days").tag(30); Text("90 days").tag(90); Text("180 days").tag(180)
                    }.frame(width: 210)
                    Picker("Minimum samples", selection: $model.minimumSamples) {
                        Text("1 purchase").tag(1); Text("3 purchases").tag(3); Text("5 purchases").tag(5)
                    }.frame(width: 210)
                    Toggle("Rank by excess return", isOn: $model.rankByExcess).toggleStyle(.checkbox)
                    Spacer()
                }
                HStack {
                    Button { Task { await prices.refresh(for: store.trades) } } label: {
                        Label(prices.loading ? prices.progress : "Load market prices", systemImage: "arrow.clockwise")
                    }.disabled(prices.loading || store.refreshing)
                    Button("Import price CSV") { importPrices = true }.disabled(prices.loading)
                    Spacer()
                    if model.calculating || prices.loading { ProgressView().controlSize(.small) }
                }
                Text("Most profitable · modeled returns")
                    .font(.title2.bold())
                Text("Equal-weight stock purchases after public disclosure. SPY is the S&P 500 ETF benchmark. Returns use adjusted closes over identical dates, without trading costs or taxes.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack(spacing: 18) {
                    Label("\(model.report.scoredCount)/\(model.report.candidateCount) purchases priced", systemImage: "checkmark.circle")
                    Button("\(model.report.skipped.count) excluded · view reasons") { showExcluded.toggle() }
                        .buttonStyle(.link)
                    Text("\(model.leaders.count) ranked politicians")
                }.font(.caption)
                if let error = prices.error {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).font(.caption)
                }
                if let updated = prices.archive.updatedAt {
                    Text("Price load: \(updated.formatted()) · latest available bar: \(prices.latestBar ?? "None")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let selected = model.selected {
                    ComparisonChart(leader: selected, window: model.window)
                    LeaderboardRanking(model: model)
                    ScoredPurchases(leader: selected)
                } else {
                    ContentUnavailableView("No ranked returns yet", systemImage: "chart.xyaxis.line",
                                           description: Text(prices.archive.series.isEmpty ?
                                            "Load market prices or import adjusted-close prices including SPY to calculate the leaderboard and graph." :
                                            "No purchases meet the holding-period, sample-count, and price-coverage requirements. Try another period or inspect excluded records."))
                        .frame(minHeight: 220)
                }
                if showExcluded { ExcludedPurchases(events: model.report.skipped) }
                DisclosureGroup("How the leaderboard and graph are calculated") {
                    Text("For each disclosed stock purchase (including spouse/dependent owners), enter at the first common stock/SPY close strictly after the filing date, within 7 calendar days. Exit at the first common close on or after the entry date plus the selected holding period, within 7 days. Only completed windows are scored; daily coverage gaps over 7 days are excluded. Options, bonds, exchanges, sales, missing tickers, and review-flagged records are not modeled. Each eligible purchase receives equal weight; amounts are never turned into position sizes. The leaderboard sorts the mean event return. Excess is model minus matched SPY return in percentage points. The graph averages price paths rebased to 100 and aligns each event by percentage of its holding period; its endpoint exactly matches the leaderboard. This is a hypothetical disclosure-following strategy, not actual realized profits or a reconstructed portfolio. Small samples and incomplete disclosure/price coverage can change rankings.")
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Text("Prices: Yahoo Finance unofficial adjusted-close endpoint or your imported CSV. Provider availability and adjustment accuracy are not guaranteed; imported CSV requires date,ticker,adjusted_close and SPY rows.")
                    .font(.caption).foregroundStyle(.secondary)
                if !prices.failures.isEmpty {
                    DisclosureGroup("Price download failures (\(prices.failures.count))") {
                        ForEach(prices.failures, id: \.self) { Text($0).font(.caption) }
                    }
                }
            }.padding(24)
        }
        .fileImporter(isPresented: $importPrices, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            switch result {
            case .success(let url): Task { await prices.importCSV(url) }
            case .failure(let error): prices.error = error.localizedDescription
            }
        }
        .task(id: analysisKey) { await model.calculate(trades: store.trades, prices: prices.archive) }
        .task(id: store.revision) {
            await prices.loadIfNeeded()
            if prices.archive.series.isEmpty && !store.trades.isEmpty { await prices.refresh(for: store.trades) }
        }
    }

}
