import SwiftUI

struct ExcessReturnView: View {
    let value: Double
    @ScaledMetric(relativeTo: .largeTitle) private var size = 48.0
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always(includingZero: false))))
                .font(.system(size: size, weight: .bold).width(.condensed)).tracking(-1.2).monospacedDigit()
                .foregroundStyle(AppTheme.ink)
            Text("percentage points against SPY").font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel("Excess return, \(ReturnFormat.points(value)), compared with matched SPY returns")
    }
}
