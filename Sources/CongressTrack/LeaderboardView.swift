import SwiftUI
import Charts
import UniformTypeIdentifiers

struct LeaderboardView: View {
    @EnvironmentObject private var store: TradeStore
    @EnvironmentObject private var prices: PriceStore
    @State private var window = 30
    @State private var minimumSamples = 1
    @State private var rankByExcess = false
    @State private var selectedID: String?
    @State private var importPrices = false
    @State private var report = PerformanceReport(leaders: [], skipped: [], scoredCount: 0, candidateCount: 0)
    @State private var calculating = false
    @State private var graphHover: Double?
    @State private var showExcluded = false

    private var analysisKey: String {
        "\(window)-\(store.trades.hashValue)-\(prices.archive.updatedAt?.timeIntervalSince1970 ?? 0)"
    }
    private var leaders: [LeaderboardEntry] {
        let eligible = report.leaders.filter { $0.events.count >= minimumSamples }
        return rankByExcess ? eligible.sorted { $0.excessPct > $1.excessPct } : eligible
    }
    private var selected: LeaderboardEntry? { leaders.first { $0.id == selectedID } ?? leaders.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Picker("Holding period", selection: $window) {
                        Text("30 days").tag(30); Text("90 days").tag(90); Text("180 days").tag(180)
                    }.frame(width: 210)
                    Picker("Minimum samples", selection: $minimumSamples) {
                        Text("1 purchase").tag(1); Text("3 purchases").tag(3); Text("5 purchases").tag(5)
                    }.frame(width: 210)
                    Toggle("Rank by excess return", isOn: $rankByExcess).toggleStyle(.checkbox)
                    Spacer()
                }
                HStack {
                    Button { Task { await prices.refresh(for: store.trades) } } label: {
                        Label(prices.loading ? prices.progress : "Load market prices", systemImage: "arrow.clockwise")
                    }.disabled(prices.loading || store.refreshing)
                    Button("Import price CSV") { importPrices = true }.disabled(prices.loading)
                    Spacer()
                    if calculating || prices.loading { ProgressView().controlSize(.small) }
                }
                Text("Most profitable · modeled returns")
                    .font(.title2.bold())
                Text("Equal-weight stock purchases after public disclosure. SPY is the S&P 500 ETF benchmark. Returns use adjusted closes over identical dates, without trading costs or taxes.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack(spacing: 18) {
                    Label("\(report.scoredCount)/\(report.candidateCount) purchases priced", systemImage: "checkmark.circle")
                    Button("\(report.skipped.count) excluded · view reasons") { showExcluded.toggle() }
                        .buttonStyle(.link)
                    Text("\(leaders.count) ranked politicians")
                }.font(.caption)
                if let error = prices.error {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).font(.caption)
                }
                if let updated = prices.archive.updatedAt {
                    Text("Price load: \(updated.formatted()) · latest available bar: \(prices.archive.series.values.flatMap { $0 }.map(\.date).max() ?? "None")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let selected {
                    comparisonChart(selected)
                    ranking
                    eventDetails(selected)
                } else {
                    ContentUnavailableView("No ranked returns yet", systemImage: "chart.xyaxis.line",
                                           description: Text(prices.archive.series.isEmpty ?
                                            "Load market prices or import adjusted-close prices including SPY to calculate the leaderboard and graph." :
                                            "No purchases meet the holding-period, sample-count, and price-coverage requirements. Try another period or inspect excluded records."))
                        .frame(minHeight: 220)
                }
                if showExcluded { excludedList }
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
            case .success(let url): prices.importCSV(url)
            case .failure(let error): prices.error = error.localizedDescription
            }
        }
        .task(id: analysisKey) {
            calculating = true
            let trades = store.trades, archive = prices.archive, days = window
            let updated = await Task.detached(priority: .userInitiated) {
                PerformanceEngine.evaluate(trades: trades, prices: archive, window: days)
            }.value
            guard !Task.isCancelled else { return }
            report = updated; calculating = false
        }
        .task {
            if prices.archive.series.isEmpty { await prices.refresh(for: store.trades) }
        }
    }

    private func comparisonChart(_ leader: LeaderboardEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(leader.member.name).font(.title3.bold())
                    Text("\(leader.events.count) modeled purchases · \(window)-day holding period")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                score("Model", leader.returnPct, color: .teal)
                score("S&P 500 · SPY", leader.benchmarkPct, color: .blue)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Excess").font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%+.2f pp", leader.excessPct)).font(.title3.bold()).monospacedDigit()
                }
            }
            Chart {
                RuleMark(y: .value("Baseline", 100)).foregroundStyle(.gray.opacity(0.4))
                ForEach(leader.curve) { point in
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Rebased value", point.model))
                        .foregroundStyle(by: .value("Series", "Modeled purchases"))
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Rebased value", point.benchmark))
                        .foregroundStyle(by: .value("Series", "S&P 500 · SPY"))
                }
                if let graphHover {
                    RuleMark(x: .value("Selected progress", graphHover)).foregroundStyle(.gray.opacity(0.5))
                }
            }
            .chartForegroundStyleScale(["Modeled purchases": Color.teal, "S&P 500 · SPY": Color.blue])
            .chartXScale(domain: 0...100)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxisLabel("Holding-period progress (%)")
            .chartYAxisLabel("Adjusted-price growth · start = 100")
            .chartXSelection(value: $graphHover)
            .frame(height: 260)
            if let graphHover, let point = leader.curve.min(by: { abs(Double($0.progress) - graphHover) < abs(Double($1.progress) - graphHover) }) {
                Text(String(format: "%d%% of period · Model %.2f · SPY %.2f", point.progress, point.model, point.benchmark))
                    .font(.caption).monospacedDigit()
            }
        }.padding(20).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
    }

    private func score(_ label: String, _ value: Double, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%+.2f%%", value)).font(.title3.bold()).monospacedDigit().foregroundStyle(color)
        }
    }

    private var ranking: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rank / politician").frame(maxWidth: .infinity, alignment: .leading)
                Text("Model").frame(width: 95, alignment: .trailing)
                Text("SPY").frame(width: 95, alignment: .trailing)
                Text("Excess").frame(width: 95, alignment: .trailing)
                Text("Scored / skipped").frame(width: 115, alignment: .trailing)
            }.font(.caption.bold()).foregroundStyle(.secondary).padding(12)
            ForEach(Array(leaders.enumerated()), id: \.element.id) { index, leader in
                Button { selectedID = leader.id; graphHover = nil } label: {
                    HStack {
                        Text("\(index + 1)").font(.headline).monospacedDigit().frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(leader.member.name).fontWeight(.medium)
                            Text([leader.member.party, leader.member.state].compactMap { $0 }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%+.2f%%", leader.returnPct)).frame(width: 95, alignment: .trailing)
                        Text(String(format: "%+.2f%%", leader.benchmarkPct)).frame(width: 95, alignment: .trailing)
                        Text(String(format: "%+.2f pp", leader.excessPct)).frame(width: 95, alignment: .trailing)
                        Text("\(leader.events.count) / \(leader.skipped.count)").frame(width: 115, alignment: .trailing)
                    }.monospacedDigit().padding(12).contentShape(Rectangle())
                        .background(selected?.id == leader.id ? .teal.opacity(0.1) : .clear)
                }.buttonStyle(.plain)
                Divider()
            }
        }.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private func eventDetails(_ leader: LeaderboardEntry) -> some View {
        DisclosureGroup("View \(leader.member.name)'s scored purchases") {
            ForEach(leader.events) { event in
                HStack {
                    Text(event.trade.ticker ?? "—").fontWeight(.semibold).frame(width: 65, alignment: .leading)
                    Text("\(event.entry) → \(event.exit)").font(.caption)
                    Spacer()
                    Text(String(format: "Model %+.2f%% · SPY %+.2f%%", event.returnPct, event.benchmarkPct)).font(.caption).monospacedDigit()
                    if let url = event.trade.filingURL { Link("Filing", destination: url) }
                }.padding(.vertical, 5)
            }
        }
    }

    private var excludedList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excluded purchases").font(.headline)
            ForEach(report.skipped) { event in
                HStack(alignment: .top) {
                    Text("\(event.trade.member.name) · \(event.trade.ticker ?? event.trade.assetType)")
                        .frame(width: 240, alignment: .leading)
                    Text(event.reason).foregroundStyle(.secondary)
                    Spacer()
                    if let url = event.trade.filingURL { Link("Filing", destination: url) }
                }.font(.caption).padding(.vertical, 4)
            }
        }
    }
}
