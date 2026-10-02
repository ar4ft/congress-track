import SwiftUI
import Charts

struct ComparisonChart: View {
    let leader: LeaderboardEntry
    let window: Int
    @State private var hover: Double?
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    chartHeading
                    Spacer(minLength: 12)
                    metrics
                }
                VStack(alignment: .leading, spacing: 14) { chartHeading; metrics }
            }
            Chart {
                RuleMark(y: .value("Starting value", 100)).foregroundStyle(.secondary.opacity(0.3))
                ForEach(leader.curve) { point in
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Rebased value", point.model))
                        .foregroundStyle(by: .value("Series", "Modeled purchases"))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .symbol(by: .value("Series", "Modeled purchases"))
                        .symbolSize(differentiate ? 20 : 0)
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Rebased value", point.benchmark))
                        .foregroundStyle(by: .value("Series", "S&P 500 · SPY"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .symbol(by: .value("Series", "S&P 500 · SPY"))
                        .symbolSize(differentiate ? 20 : 0)
                }
                if let hover { RuleMark(x: .value("Selected progress", hover)).foregroundStyle(.secondary.opacity(0.4)) }
            }
            .chartForegroundStyleScale(["Modeled purchases": AppTheme.accent, "S&P 500 · SPY": AppTheme.benchmark])
            .chartSymbolScale(["Modeled purchases": BasicChartSymbolShape.circle, "S&P 500 · SPY": BasicChartSymbolShape.square])
            .chartXScale(domain: 0...100)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxisLabel("Holding-period progress (%)")
            .chartYAxisLabel("Adjusted-price growth · start = 100")
            .chartXSelection(value: $hover)
            .frame(height: 280)
            .accessibilityLabel("\(leader.member.name), modeled purchases compared with the S&P 500. Both series start at 100.")
            .accessibilityValue("Model \(ReturnFormat.percent(leader.returnPct)); SPY \(ReturnFormat.percent(leader.benchmarkPct)); excess \(ReturnFormat.points(leader.excessPct)).")
            if let hover, let point = leader.curve.min(by: { abs(Double($0.progress) - hover) < abs(Double($1.progress) - hover) }) {
                Text("\(point.progress)% of period · Model \(point.model.formatted(.number.precision(.fractionLength(2)))) · SPY \(point.benchmark.formatted(.number.precision(.fractionLength(2))))")
                    .font(.callout).monospacedDigit()
            }
            Text("Solid: modeled purchases · Dashed: S&P 500 (SPY)").font(.caption).foregroundStyle(.secondary)
        }.padding(20).background(AppTheme.surface, in: .rect(cornerRadius: AppTheme.cornerRadius))
            .overlay { RoundedRectangle(cornerRadius: AppTheme.cornerRadius).strokeBorder(.quaternary) }
            .onChange(of: leader.id) { _, _ in hover = nil }
            .onChange(of: window) { _, _ in hover = nil }
    }
    private var chartHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(leader.member.name).font(.title2.bold())
            Text("\(leader.events.count) modeled purchases · \(window)-day period").font(.callout).foregroundStyle(.secondary)
        }
    }
    private var metrics: some View {
        HStack(spacing: 20) {
            ReturnMetric(title: "Model", value: leader.returnPct, color: AppTheme.accent)
            ReturnMetric(title: "S&P 500 · SPY", value: leader.benchmarkPct, color: AppTheme.benchmark)
            ReturnMetric(title: "Excess", value: leader.excessPct, points: true)
        }
    }
}
