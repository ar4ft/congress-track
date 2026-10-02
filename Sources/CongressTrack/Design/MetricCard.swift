import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.callout).foregroundStyle(.secondary)
            Text(value).font(.title.bold()).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(AppTheme.surface, in: .rect(cornerRadius: AppTheme.cornerRadius))
        .overlay { RoundedRectangle(cornerRadius: AppTheme.cornerRadius).strokeBorder(.quaternary) }
        .accessibilityElement(children: .combine)
    }
}
