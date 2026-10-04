# SwiftUI Pro review

Applied [Paul Hudson's swiftui-pro skill](https://github.com/twostraws/swiftui-agent-skill/tree/main/swiftui-pro) to the existing macOS 14 app. The review covers API usage, view composition, data flow, navigation, design, accessibility, performance, Swift concurrency, and hygiene. No new runtime dependency was added.

Install the same skill locally:

```sh
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro --agent codex --yes
```

`skills-lock.json` records the upstream source/hash; `.agents/` is local tooling, excluded from Git. Development now requires Xcode 26.2 / Swift 6.2 or later. Deployment remains macOS 14. Both CI workflows explicitly select Xcode 26.2 on macos-15; production signing remains manual-only.

## ContentView.swift → Workspace/

**Original lines 32–51, 170–175, 299: keep repeated filtering and aggregation out of view bodies.** The table, summary counts, and per-politician cards repeatedly scanned records as unrelated state changed.

```swift
// Before: recomputed by body evaluation
private var rows: [Trade] { store.trades.filter { /* filters */ }.sorted(using: sortOrder) }
// After: cancellation-aware background query; explicit filter/revision invalidation
.task(id: query) { await workspace.refresh(store.trades, query: query) }
```

`WorkspaceModel` retains the filtered table and summary counts. `TradeStore` indexes member counts once when records change. Native table sorting is preserved. Separate sidebar/header/filter/table/card/detail/footer types replace the large composite view.

**Original lines 72–108, 143, 307–309: use selection-driven navigation rather than deferred DispatchQueue mutations.** Route changes reset filters before applying a member, ticker, or saved search; no next-run-loop race is necessary.

```swift
// Before
section = .all
DispatchQueue.main.async { memberKey = member.key }
// After
workspace.route = .member(member.key)
// onChange calls applyRoute(searches:), restoring related filters together
```

Followed members now appear in Following rather than Saved Searches. Clearing member, ticker, or saved-search filters resets their route; clearing ordinary watchlist filters preserves watchlist scope. Detail selection opens a native, resizable, closable inspector. Semantic typography, adaptive system surfaces, shared spacing, and a narrower minimum window improve readability in both appearance modes.

**Original lines 286–290; SettingsView.swift line 75: give icon-only controls readable labels.**

```swift
// Before
Button { /* follow */ } label: { Image(systemName: "star") }
// After
Button("Follow \(member.name)", systemImage: "star") { /* follow */ }
    .labelStyle(.iconOnly)
```

## TradeStore.swift / PriceStore.swift / UpdateController.swift → Services/

**Original declarations: prefer Observation for SwiftUI-owned state.**

```swift
// Before
final class TradeStore: ObservableObject { @Published var error: String? }
// After
@MainActor @Observable final class TradeStore { var error: String? }
```

The app owns models with `@State`, injects them through typed environments, and binds through `@Bindable`. Combine remains only at the Sparkle KVO integration boundary; retained subscriptions forward changes onto the main actor. Settings binds updater preferences directly.

**Original PriceStore.swift lines 61–79: cancellation must not save a partial refresh as fresh.**

```swift
// Before
if Task.isCancelled { break }
// ... archive = updated; save()
// After
try Task.checkCancellation()
// Atomic persistence precedes publishing the completed refresh.
```

`LocalStorage` serializes disk reads, CSV parsing, and atomic writes off the UI actor. Canceled refreshes preserve the previous price archive and revision. Trade records and their manifest now share one atomic snapshot; older separate caches remain readable. Concurrent initial loads share one task, including CSV import. Initial price loading reacts to disclosure revisions so opening the leaderboard before the first cache load does not leave it unpriced. Authorization requests and settings tasks use identities to prevent an old notification prompt overwriting a newer preference; foreground notifications have a presentation delegate.

## LeaderboardView.swift / Performance.swift → Leaderboard/

**Original LeaderboardView.swift lines 20–28, 100–110: avoid full-array hashing and detached tasks for structured calculations.**

```swift
// Before
"\(window)-\(store.trades.hashValue)-..."
await Task.detached { PerformanceEngine.evaluate(/* ... */) }.value
// After
AnalysisRequest(tradesRevision: store.revision, pricesRevision: prices.revision, window: model.window)
try await PerformanceEngine.evaluateAsync(/* ... */) // @concurrent, cancellation-aware
```

The model retains ranked results and numbered rows (direct ForEach over enumerated() requires macOS 26, so the compatible array is built once per ranking update); changing the sample threshold or ordering updates those results. Entry averages and chart curves are computed once. Price freshness summaries use a cached latest-bar value. Lazy ranking/exclusion containers avoid eagerly laying out the entire archive.

**Original chart lines 140–166: do not rely on color to identify series.** The benchmark uses a dashed line, explicit solid/dashed legend text, optional differing symbols under Differentiate Without Color, and an accessible summary. There are no added animations, so Reduce Motion needs no special animation branch. Native Charts retains its accessible data representation. Locale-aware FormatStyle replaces C-style percent formatting. Returns, benchmark alignment, and equal weighting are unchanged.

## Trade.swift → Models/Day.swift

**Original lines 39–48, 90–107: avoid constructing a DateFormatter for every date operation.**

```swift
// Before
let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
// After
static let format = Date.ISO8601FormatStyle().year().month().day().dateSeparator(.dash)
```

A strict parse/round-trip rejects invalid dates. Filing dates, date filters, and display formatting use UTC calendar days, preventing local-time-zone shifts. Search uses `localizedStandardContains` to match case and diacritics.

## Priorities and verification

1. **Correctness:** canceled refresh preservation, coherent snapshots, predictable route/filter restoration, strict calendar dates.
2. **Accessibility and design:** readable control names, distinct benchmark lines, semantic surfaces/fonts, closable inspector, correct sidebar grouping.
3. **Performance and maintainability:** fine-grained Observation, retained derived results, background storage/analytics, feature-oriented files, Swift 6 concurrency checking.

Regression tests exercise route transitions and saved dates, combined filters/watchlists, diacritic search, UTC dates, cancellation of analysis/storage/price refresh, and existing performance/benchmark calculations. CI also builds Intel and Apple silicon development packages, checks Sparkle tampering rejection, and launches the packaged app. These checks do not replace manual VoiceOver, keyboard navigation, and notification delivery testing on a Mac.
