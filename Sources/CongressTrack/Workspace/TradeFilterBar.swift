import SwiftUI

struct TradeFilterBar: View {
    @Bindable var workspace: WorkspaceModel
    let saveSearch: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { chamber; activity; party }.fixedSize(horizontal: true, vertical: false)
                Menu("Filters", systemImage: "line.3.horizontal.decrease") { chamber; activity; party }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    datesToggle
                    if workspace.filters.useDates { dateRange }
                    Spacer()
                    actions
                }.fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 12) {
                    HStack { datesToggle; Spacer(); actions }
                    if workspace.filters.useDates { dateRange }
                }
            }
        }.padding(.horizontal, AppTheme.spacing).padding(.bottom, 16)
            .environment(\.timeZone, .gmt)
    }
    private var chamber: some View {
        Picker("Chamber", selection: $workspace.filters.chamber) {
            Text("Both chambers").tag("all"); Text("House").tag("house"); Text("Senate").tag("senate")
        }
    }
    private var activity: some View {
        Picker("Activity", selection: $workspace.filters.side) {
            Text("All types").tag("all"); Text("Buy").tag("buy"); Text("Sell").tag("sell"); Text("Exchange").tag("exchange")
        }
    }
    private var party: some View {
        Picker("Party", selection: $workspace.filters.party) {
            Text("All parties").tag("all"); Text("Democrat").tag("Democrat")
            Text("Republican").tag("Republican"); Text("Independent").tag("Independent")
        }
    }
    private var datesToggle: some View { Toggle("Filing dates", isOn: $workspace.filters.useDates).toggleStyle(.checkbox) }
    private var dateRange: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { since; until }.fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 8) { since; until }
        }
    }
    private var since: some View {
        DatePicker("From", selection: $workspace.filters.since, in: ...workspace.filters.until, displayedComponents: .date)
    }
    private var until: some View {
        DatePicker("To", selection: $workspace.filters.until, in: workspace.filters.since..., displayedComponents: .date)
    }
    private var actions: some View {
        HStack(spacing: 8) {
            if let ticker = workspace.filters.ticker { Text(ticker).font(.callout.bold()) }
            if workspace.filters.isActive { Button("Clear filters") { workspace.clearFilters() } }
            Button("Save search", systemImage: "bookmark", action: saveSearch)
        }
    }
}
