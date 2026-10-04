import SwiftUI

struct DisclosureTimeline: View {
    let trade: Trade
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction → public filing").font(.caption).foregroundStyle(AppTheme.secondaryInk)
            if let delay = trade.delay, delay >= 0 {
                HStack(spacing: 0) {
                    Circle().strokeBorder(AppTheme.accent, lineWidth: 2).frame(width: 8, height: 8)
                    Rectangle().fill(AppTheme.accent.opacity(0.6)).frame(height: 1)
                    Circle().fill(AppTheme.accent).frame(width: 8, height: 8)
                }.accessibilityHidden(true)
            }
            HStack(alignment: .top) {
                DisclosureField(title: "Traded", value: Day.display(trade.transactedAt))
                Spacer(minLength: 8)
                DisclosureField(title: "Filed", value: Day.display(trade.filedAt), alignment: .trailing)
            }
            if let delay = trade.delay, delay >= 0 {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(delay.formatted()).font(AppTheme.screenTitle).monospacedDigit()
                        .contentTransition(.numericText())
                    Text(delay == 1 ? "day until disclosure" : "days until disclosure")
                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
            } else {
                Text(trade.delay.map { "Source dates need review: \($0) days between trade and filing." } ?? "Disclosure delay is unknown.")
                    .font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
        .animation(reduceMotion ? nil : .spring(duration: 0.22, bounce: 0), value: trade.id)
        .sensoryFeedback(.selection, trigger: trade.id)
        .accessibilityElement(children: .combine)
    }
}
