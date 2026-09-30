import SwiftUI

private enum Section: String, CaseIterable, Identifiable {
    case all = "All disclosures", watchlist = "Watchlist", members = "Politicians"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all: return "chart.bar.xaxis"
        case .watchlist: return "star"
        case .members: return "person.2"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: TradeStore
    @State private var section: Section? = .all
    @State private var search = ""
    @State private var chamber = "all"
    @State private var side = "all"
    @State private var party = "all"
    @State private var memberKey: String?
    @State private var selectedID: Trade.ID?
    @State private var sortOrder = [KeyPathComparator(\Trade.filedAt, order: .reverse)]

    private var rows: [Trade] {
        store.trades.filter {
            $0.matches(search.trimmingCharacters(in: .whitespacesAndNewlines)) &&
            (chamber == "all" || $0.chamber == chamber) &&
            (side == "all" || $0.side == side) &&
            (party == "all" || $0.member.party == party) &&
            (memberKey == nil || $0.member.key == memberKey) &&
            (section != .watchlist || store.followed.contains($0.member.key))
        }.sorted(using: sortOrder)
    }
    private var selected: Trade? { rows.first { $0.id == selectedID } }
    private var members: [Trade.Member] {
        Dictionary(store.trades.map { ($0.member.key, $0.member) }, uniquingKeysWith: { first, _ in first })
            .values.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 24) {
                Label("CongressTrack", systemImage: "building.columns.fill")
                    .font(.title3.bold()).padding(.horizontal, 16).padding(.top, 24)
                List(selection: $section) {
                    SwiftUI.Section("WORKSPACE") {
                        ForEach(Section.allCases) { destination in
                            Label(destination.rawValue, systemImage: destination.icon).tag(destination)
                        }
                    }
                    SwiftUI.Section("FOLLOWING") {
                        if store.followed.isEmpty {
                            Text("Follow a politician from a disclosure.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(members.filter { store.followed.contains($0.key) }, id: \.key) { member in
                            Button {
                                section = .all
                                DispatchQueue.main.async { memberKey = member.key }
                            } label: { Label(member.name, systemImage: "person.crop.circle") }
                            .buttonStyle(.plain)
                        }
                    }
                }.listStyle(.sidebar)
                VStack(alignment: .leading, spacing: 6) {
                    Label("PUBLIC RECORDS", systemImage: "checkmark.seal")
                        .font(.caption.bold())
                    Text("House & Senate disclosures\nData by LuxAlgo Market Trackers")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(16)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 235)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let error = store.error {
                    HStack {
                        Label(error, systemImage: "exclamationmark.triangle")
                        Spacer()
                        Button("Dismiss") { store.error = nil }
                    }.font(.caption).padding(12).background(.orange.opacity(0.1))
                }
                if section == .members { memberGrid }
                else {
                    filters
                    HStack(spacing: 0) {
                        tradeTable
                        if let trade = selected {
                            Divider()
                            TradeDetail(trade: trade).frame(width: 290)
                        }
                    }
                }
                footer
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .searchable(text: $search, prompt: "Search politician, ticker, or asset")
        .toolbar {
            ToolbarItem {
                Button { Task { await store.refresh() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }.disabled(store.refreshing).help("Fetch the latest published disclosure batch (⌘R)")
            }
        }
        .task { await store.refresh() }
        .onChange(of: section) { _, _ in memberKey = nil; selectedID = nil }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(section?.rawValue ?? "All disclosures").font(.largeTitle.bold())
                    Text("Follow the filings. See the full disclosure.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if store.refreshing { ProgressView().controlSize(.small) }
                Text("HOUSE + SENATE").font(.caption.bold())
                    .padding(8).background(.teal.opacity(0.1), in: Capsule())
            }
            HStack(spacing: 12) {
                metric("Disclosures", value: rows.count.formatted(), symbol: "doc.text")
                metric("Politicians", value: Set(rows.map { $0.member.key }).count.formatted(), symbol: "person.2")
                metric("Purchases", value: rows.filter { $0.side == "buy" }.count.formatted(), symbol: "arrow.down.left")
                metric("Sales", value: rows.filter { $0.side == "sell" }.count.formatted(), symbol: "arrow.up.right")
            }
        }.padding(24)
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private var filters: some View {
        HStack(spacing: 16) {
            Picker("Chamber", selection: $chamber) {
                Text("Both chambers").tag("all")
                Text("House").tag("house")
                Text("Senate").tag("senate")
            }.frame(width: 200)
            Picker("Activity", selection: $side) {
                Text("All types").tag("all")
                Text("Buy").tag("buy")
                Text("Sell").tag("sell")
                Text("Exchange").tag("exchange")
            }.frame(width: 165)
            Picker("Party", selection: $party) {
                Text("All parties").tag("all")
                Text("Democrat").tag("Democrat")
                Text("Republican").tag("Republican")
                Text("Independent").tag("Independent")
            }.frame(width: 200)
            Spacer()
            if memberKey != nil || chamber != "all" || side != "all" || party != "all" || !search.isEmpty {
                Button("Clear filters") {
                    memberKey = nil; chamber = "all"; side = "all"; party = "all"; search = ""
                }.font(.caption)
            }
        }.padding(.horizontal, 24).padding(.bottom, 18)
    }

    private var tradeTable: some View {
        Table(rows, selection: $selectedID, sortOrder: $sortOrder) {
            TableColumn("Politician", value: \.member.name) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.member.name).fontWeight(.medium)
                    Text([trade.member.party, trade.member.state, trade.chamber.capitalized]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 6)
            }.width(min: 155, ideal: 200)
            TableColumn("Asset", value: \.assetDescription) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.ticker ?? trade.assetType.capitalized).fontWeight(.semibold)
                    Text(trade.assetDescription).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }.help(trade.assetDescription)
            }.width(min: 120, ideal: 190)
            TableColumn("Type", value: \.side) { trade in
                Text(trade.side.capitalized).font(.caption.bold())
                    .foregroundStyle(trade.side == "buy" ? .teal : trade.side == "sell" ? .orange : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }.width(75)
            TableColumn("Disclosed range") { trade in
                Text(trade.amountRange.text).font(.caption).monospacedDigit()
            }.width(min: 140, ideal: 165)
            TableColumn("Filed", value: \.filedAt).width(95)
        }
        .overlay {
            if rows.isEmpty {
                ContentUnavailableView(
                    section == .watchlist && store.followed.isEmpty ? "Your watchlist is empty" : "No matching disclosures",
                    systemImage: section == .watchlist ? "star" : "magnifyingglass",
                    description: Text(section == .watchlist && store.followed.isEmpty ?
                        "Select a disclosure and follow its politician to get started." : "Try another search or clear your filters."))
            }
        }
    }

    private var memberGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                ForEach(members.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }, id: \.key) { member in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(.teal)
                            Spacer()
                            Button { store.toggleFollow(member) } label: {
                                Image(systemName: store.followed.contains(member.key) ? "star.fill" : "star")
                            }.buttonStyle(.borderless).help("Follow or unfollow politician")
                        }
                        Text(member.name).font(.headline)
                        Text([member.party, member.state].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(store.trades.filter { $0.member.key == member.key }.count) loaded disclosures")
                            .font(.caption)
                        Button("View disclosures") {
                            section = .all
                            // The section change resets filters; apply this selection on the next run loop.
                            DispatchQueue.main.async { memberKey = member.key; search = "" }
                        }
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                }
            }.padding(24)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(store.trades.count) loaded records · latest batch refresh")
                Spacer()
                if let checked = store.checkedAt { Text("Checked \(checked.formatted(date: .omitted, time: .shortened))") }
            }
            Text("Source ingestion: \(store.manifest?.datasets["congress-trades"]?.lastIngestedAt ?? "Unknown")")
            Text("Disclosures are delayed and amounts are ranges. Loaded data is not a complete market history.")
        }.font(.caption).foregroundStyle(.secondary).padding(14)
            .background(.bar)
    }
}

private struct TradeDetail: View {
    @EnvironmentObject private var store: TradeStore
    let trade: Trade

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DISCLOSURE DETAILS").font(.caption.bold()).foregroundStyle(.secondary)
                Text(trade.ticker ?? trade.assetType.capitalized).font(.largeTitle.bold())
                Text(trade.assetDescription).font(.headline)
                Divider()
                Text(trade.member.name).font(.title3.bold())
                Text([trade.member.party, trade.member.state].compactMap { $0 }.joined(separator: " · "))
                    .foregroundStyle(.secondary)
                Button {
                    store.toggleFollow(trade.member)
                } label: {
                    Label(store.followed.contains(trade.member.key) ? "Following" : "Follow politician",
                          systemImage: store.followed.contains(trade.member.key) ? "star.fill" : "star")
                }.buttonStyle(.bordered)
                Divider()
                field("Transaction", trade.side.capitalized)
                field("Disclosed amount", trade.amountRange.text)
                field("Owner", trade.owner.capitalized)
                field("Traded", trade.transactedAt)
                field("Filed", trade.filedAt)
                field("Disclosure delay", trade.delay.map { "\($0) days" } ?? "Unknown")
                if trade.provenance.needsReview == true {
                    Label("Source parser flagged this record for review.", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
                Divider()
                if let url = trade.filingURL {
                    Link(destination: url) { Label("Open original filing", systemImage: "arrow.up.right.square") }
                }
                field("Source", trade.provenance.source)
                field("Retrieved", trade.provenance.retrievedAt)
            }.padding(22)
        }
    }

    private func field(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}
