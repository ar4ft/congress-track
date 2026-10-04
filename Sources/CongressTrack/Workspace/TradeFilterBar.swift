import SwiftUI

struct TradeFilterBar: View {
    @Bindable var workspace: WorkspaceModel
    let saveSearch: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Picker("Chamber", selection: $workspace.filters.chamber) {
                    Text("Both chambers").tag("all"); Text("House").tag("house"); Text("Senate").tag("senate")
                }
                Picker("Activity", selection: $workspace.filters.side) {
                    Text("All types").tag("all"); Text("Buy").tag("buy"); Text("Sell").tag("sell"); Text("Exchange").tag("exchange")
                }
                Picker("Party", selection: $workspace.filters.party) {
                    Text("All parties").tag("all"); Text("Democrat").tag("Democrat")
                    Text("Republican").tag("Republican"); Text("Independent").tag("Independent")
                }
            }
            HStack(spacing: 12) {
                Toggle("Filing dates", isOn: $workspace.filters.useDates).toggleStyle(.checkbox)
                if workspace.filters.useDates {
                    DatePicker("From", selection: $workspace.filters.since, in: ...workspace.filters.until, displayedComponents: .date)
                    DatePicker("To", selection: $workspace.filters.until, in: workspace.filters.since..., displayedComponents: .date)
                }
                if let ticker = workspace.filters.ticker { Text(ticker).font(.callout.bold()) }
                Spacer()
                if workspace.filters.isActive { Button("Clear filters") { workspace.clearFilters() } }
                Button("Save search", systemImage: "bookmark", action: saveSearch)
            }
        }.padding(.horizontal, AppTheme.spacing).padding(.bottom, 16)
            .environment(\.timeZone, .gmt)
    }
}
