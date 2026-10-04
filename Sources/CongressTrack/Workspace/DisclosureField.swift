import SwiftUI

struct DisclosureField: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(value).font(.callout).foregroundStyle(AppTheme.ink).textSelection(.enabled)
        }.accessibilityElement(children: .combine)
    }
}
