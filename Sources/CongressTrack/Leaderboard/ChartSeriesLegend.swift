import SwiftUI

struct ChartSeriesLegend: View {
    let title: String
    let value: Double
    let color: Color
    var dashed = false
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(color).frame(width: 24, height: dashed ? 2 : 3)
                .mask {
                    if dashed {
                        HStack(spacing: 3) { ForEach(0..<3, id: \.self) { _ in Rectangle() } }
                    } else { Rectangle() }
                }.accessibilityHidden(true)
            Text("\(title) \(ReturnFormat.percent(value))").font(.callout).monospacedDigit()
                .foregroundStyle(AppTheme.ink)
        }.accessibilityElement(children: .combine)
    }
}
