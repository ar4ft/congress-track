import SwiftUI

struct ReturnMetric: View {
    let title: String
    let value: Double
    var color: Color = .primary
    var points = false
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            Text(points ? ReturnFormat.points(value) : ReturnFormat.percent(value))
                .font(.title3.bold()).monospacedDigit().foregroundStyle(color)
        }.accessibilityElement(children: .combine)
    }
}
