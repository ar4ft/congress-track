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
                    ExcessReturnView(value: leader.excessPct)
                }
                VStack(alignment: .leading, spacing: 14) {
                    chartHeading
                    ExcessReturnView(value: leader.excessPct)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { modelLegend; benchmarkLegend }
                VStack(alignment: .leading, spacing: 10) { modelLegend; benchmarkLegend }
            }
            Chart {
                RuleMark(y: .value("Zero return", 0)).foregroundStyle(AppTheme.secondaryInk.opacity(0.45))
                ForEach(leader.curve) { point in
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Return (%)", point.model - 100))
                        .foregroundStyle(by: .value("Series", "Modeled purchases"))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .symbol(by: .value("Series", "Modeled purchases"))
                        .symbolSize(differentiate ? 20 : 0)
                    LineMark(x: .value("Holding-period progress (%)", point.progress), y: .value("Return (%)", point.benchmark - 100))
                        .foregroundStyle(by: .value("Series", "S&P 500 · SPY"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .symbol(by: .value("Series", "S&P 500 · SPY"))
                        .symbolSize(differentiate ? 20 : 0)
                }
                if let hover { RuleMark(x: .value("Selected progress", hover)).foregroundStyle(AppTheme.secondaryInk.opacity(0.4)) }
            }
            .chartForegroundStyleScale(["Modeled purchases": AppTheme.accent, "S&P 500 · SPY": AppTheme.benchmark])
            .chartSymbolScale(["Modeled purchases": BasicChartSymbolShape.circle, "S&P 500 · SPY": BasicChartSymbolShape.square])
            .chartLegend(.hidden)
            .chartXScale(domain: 0...100)
            .chartYScale(domain: .automatic(includesZero: true))
            .chartXAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(AppTheme.rule)
                    AxisTick()
                    AxisValueLabel {
                        if let progress = value.as(Int.self) { Text("\(progress)%") }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(AppTheme.rule)
                    AxisTick()
                    AxisValueLabel {
                        if let returns = value.as(Double.self) {
                            Text((returns / 100).formatted(.percent.precision(.fractionLength(0...1))))
                        }
                    }
                }
            }
            .chartXAxisLabel("Holding-period progress (%)")
            .chartYAxisLabel("Return (%)")
            .chartXSelection(value: $hover)
            .frame(height: 260)
            .accessibilityLabel("\(leader.member.name), modeled purchases compared with the S&P 500. Both series start at zero percent return.")
            .accessibilityValue("Model \(ReturnFormat.percent(leader.returnPct)); SPY \(ReturnFormat.percent(leader.benchmarkPct)); excess \(ReturnFormat.points(leader.excessPct)).")
            if let hover, let point = leader.curve.min(by: { abs(Double($0.progress) - hover) < abs(Double($1.progress) - hover) }) {
                Text("\(point.progress)% of period · Model \(ReturnFormat.percent(point.model - 100)) · SPY \(ReturnFormat.percent(point.benchmark - 100))")
                    .font(.callout).monospacedDigit().foregroundStyle(AppTheme.ink)
            }
        }
        .padding(.vertical, 24)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
        .onChange(of: leader.id) { _, _ in hover = nil }
        .onChange(of: window) { _, _ in hover = nil }
    }
    private var chartHeading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(leader.member.name).font(AppTheme.sectionTitle).foregroundStyle(AppTheme.ink)
            Text("\(leader.events.count) modeled purchases · \(window)-day period").font(.callout).foregroundStyle(AppTheme.secondaryInk)
        }
    }
    private var modelLegend: some View { ChartSeriesLegend(title: "Model", value: leader.returnPct, color: AppTheme.accent) }
    private var benchmarkLegend: some View { ChartSeriesLegend(title: "S&P 500 · SPY", value: leader.benchmarkPct, color: AppTheme.benchmark, dashed: true) }
}
