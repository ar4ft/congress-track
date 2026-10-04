# CongressTrack for Mac

A native SwiftUI app for browsing congressional stock disclosures, following politicians and tickers, and comparing a modeled disclosure-following strategy with the S&P 500. Uses [LuxAlgo's public datasets](https://github.com/LuxAlgo/market-trackers-data), with links to original government filings. Requires macOS 14+ and Xcode 26.2+ (Swift 6.2+).

## Run and install

Open `Package.swift` in Xcode, select CongressTrack and My Mac, and Run, or:

```bash
swift run CongressTrack
```

For the packaged app, icon, and installer:

```bash
bash scripts/build-app.sh
open dist/CongressTrack.app
```

The default script and normal CI produce development artifacts without certificate signing or notarization. For a Developer ID signed, notarized release with automatic updates, follow [RELEASE_SETUP.md](RELEASE_SETUP.md) and manually run **Mac build or signed release** with the production-release checkbox enabled. Pushing a branch or tag never signs or publishes a release.

Version and build numbers come from `Release.json`. Production builds embed Sparkle 2.10.0 and check a signed GitHub release feed; development builds leave updates disabled.

No signing credentials are included. Notification permissions require launching the packaged `.app`; `swift run` still supports the in-app alert feed.

## Features

- Graphite research sidebar, amber focus, compact disclosure summaries, and a resizable source-verification inspector; designed light/dark appearance.
- Searchable and sortable native disclosure table; chamber, party, activity, ticker, and filing-date filters.
- Politician summaries, persistent politician/ticker watchlists, and named saved searches.
- Disclosure details with amount ranges, owner, trade/filing dates, disclosure delay, parser review flags, and original filing links.
- Full year-shard history synchronization, validated against the manifest's record count; authoritative snapshots reconcile corrections and removals. The latest delta updates between snapshots.
- Offline caches, source health, ingestion timestamps, last full sync, and failure handling. History refreshes when the manifest changes, daily, or on demand.
- Polling every 15 minutes while the app runs; in-app alerts for new watched filings and optional macOS notifications. The first successful sync establishes a baseline and suppresses historical notification floods. Monitoring stops when the app quits.
- A menu bar for opening the app, seeing recent alerts, and refreshing. Cmd-R refreshes disclosures.
- An accessible leaderboard and interactive Swift Charts graph with solid modeled-return and dashed benchmark lines, with 30/90/180 calendar-day windows, minimum sample counts, optional excess-return ranking, purchase-level filing links, and excluded-record reasons.

## Leaderboard methodology

This ranks **modeled returns**, not politicians' actual realized profits. Public disclosures omit exact quantities and full holdings, so a reliable actual-profit leaderboard cannot be reconstructed from these records alone.

1. Consider disclosed **stock purchases**, including spouse/dependent ownership. Exclude sales, exchanges, options, bonds, unmapped tickers, and review-flagged records.
2. Enter at the first shared stock/SPY close **strictly after the filing date**, within 7 calendar days. This avoids trading on information before it became public.
3. Exit at the first shared close on or after the entry date plus the selected calendar-day window, within 7 days. Exclude incomplete windows and coverage gaps over 7 days.
4. Compute stock and SPY returns from adjusted closes on **identical dates**. Every eligible purchase gets equal weight. Disclosed ranges never become estimated position sizes. No costs or taxes are modeled.
5. Rank each politician's arithmetic mean event return. Excess return is that mean minus the matched SPY mean, in **percentage points**. Minimum sample counts can reduce small-sample rankings.
6. Rebase each event's stock and benchmark price path to 100, align by **percentage of holding period**, and average the paths. The plot subtracts the 100 baseline to display percentage returns starting at 0%. The graph is a time-aligned event comparison, not a calendar-time portfolio equity curve. Its endpoint equals the leaderboard return.

SPY is an S&P 500 ETF proxy, not the index itself. Adjusted-close changes account for the provider's split/dividend adjustments and are not identical to the official S&P 500 total-return index. Small samples, excluded assets, missing prices, and incomplete disclosure coverage can materially affect rankings.

## Market prices

LuxAlgo does **not** include market prices. The Leaderboard loads Yahoo Finance adjusted daily closes when first opened; the **Load market prices** button refreshes them. This is an unofficial, keyless endpoint, which may throttle, change, or fail. Failed symbols retain their cached series and are listed in the UI. Today's potentially incomplete quote is excluded. Market-price data is cached locally and is not redistributed in this repository.

You can also import a strict CSV containing consistent, split/dividend-adjusted closes for stocks and **SPY**:

```text
date,ticker,adjusted_close
```

Each subsequent row contains a valid ISO date, ticker, and positive finite adjusted close. Missing SPY, duplicate ticker/date pairs, and malformed rows are rejected. Import replaces the archive rather than silently mixing sources. Imported-file adjustment accuracy is the user's responsibility; the app cannot verify it.

## Source coverage and health

The bundled snapshot has 175 records downloaded September 30, 2026. Its manifest reports congress ingestion at `2026-09-07T15:11:27.497Z`. That dataset is **partial** and does not represent all congressional trading. Full history sync means all records published in the source snapshots, not every government disclosure.

Data health shows House/Senate sync and canary states, plus a local 72-hour staleness threshold independent of the manifest's flag. A new app check does not make old ingestion fresh. A snapshot row-count mismatch fails the sync and preserves previously loaded history. Snapshots replace history; incoming rows older than an existing record's retrieval timestamp do not overwrite corrections.

Disclosures are delayed; amounts remain ranges. Following or watching an entity currently monitors new filings, not market-price movements. No brokerage or trade execution is included.

Follow lists, searches, and alerts are in UserDefaults. Trade/manifest/price caches are in `~/Library/Application Support/CongressTrack`.

## Verification

```bash
swift test
bash scripts/build-app.sh
```

The macOS CI workflow runs unit tests, builds a universal development installer for Intel and Apple silicon, smoke-tests the packaged app, and verifies Sparkle signatures while rejecting modified archives and feeds. The separate, manually started release action requires Developer ID signing and Apple notarization before publishing. Its default mode produces a development build without signing; only the explicit production checkbox enables signing. Signing/notarization require the credential setup described above. Tests cover disclosure decoding, no-look-ahead entry, identical benchmark dates, equal weighting, curve endpoints, ordering, missing prices, incomplete periods, price gaps, CSV validation, archive planning, corrupted gzip, and watchlist alert matching. Manual interaction and notification delivery should still be checked on a Mac.

The references were [CongressStock](https://www.congressstock.com/trades), [Pelosi Tracker](https://pelositracker.app), and [LuxAlgo Market Trackers](https://github.com/LuxAlgo/market-trackers). The two websites returned HTTP 403 during research, so their layouts were not inspected or copied. Bundled disclosures are CC0 per LuxAlgo's [data license](https://github.com/LuxAlgo/market-trackers/blob/main/data-licenses/DATA-LICENSE). LuxAlgo ingestion code has not been copied into this app.

## SwiftUI review

The app uses Swift Observation, structured background analysis, atomic caches, and feature-oriented view components. See [Docs/SwiftUI-Review.md](Docs/SwiftUI-Review.md) for the applied swiftui-pro findings and reproducible skill installation.

## Design review

Applied [app-designer](https://github.com/fortvna/app-designer) to the user-selected **precise financial research desk** direction. Three concepts, a checked feature inventory, before/after studies, full-resolution Mac window previews, and independent critique history are in [Docs/Design](Docs/Design/README.md). The filing lens connects transaction dates, disclosure delay, provenance and the original filing; the graph emphasizes excess return against matched SPY. Layout-study prices are expressly illustrative and never enter the app’s market data.
