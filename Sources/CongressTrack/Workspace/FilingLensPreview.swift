import SwiftUI

/// An instruction, with no invented trade data in an empty watchlist.
struct FilingLensPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Rectangle().fill(AppTheme.accent).frame(width: 3, height: 32)
                Text("Choose a filing to inspect").font(.callout.weight(.semibold)).foregroundStyle(AppTheme.ink)
            }
            HStack(spacing: 0) {
                Circle().strokeBorder(AppTheme.accent, lineWidth: 2).frame(width: 8, height: 8)
                Rectangle().fill(AppTheme.accent.opacity(0.6)).frame(height: 1)
                Circle().fill(AppTheme.accent).frame(width: 8, height: 8)
            }.accessibilityHidden(true)
            HStack {
                Text("Transaction")
                Spacer()
                Text("Public filing")
            }.font(.caption).foregroundStyle(AppTheme.secondaryInk)
        }.padding(16).frame(maxWidth: 320)
            .background(AppTheme.selection)
    }
}
