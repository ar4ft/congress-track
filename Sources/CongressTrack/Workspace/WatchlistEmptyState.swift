import SwiftUI

struct WatchlistEmptyState: View {
    let hasFollowing: Bool
    let browse: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FilingLensPreview()
            Text("No watched disclosures yet").font(AppTheme.sectionTitle).foregroundStyle(AppTheme.ink)
            Text(hasFollowing ? "Your filters currently match no watched filings. Browse all disclosures to continue researching." :
                 "Choose a disclosure, then follow its politician or watch its ticker.")
                .font(.callout).foregroundStyle(AppTheme.secondaryInk)
            Button("Browse disclosures", action: browse).buttonStyle(.borderedProminent).foregroundStyle(AppTheme.onAccent)
        }.frame(maxWidth: 440, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(AppTheme.spacing).background(AppTheme.canvas)
    }
}
