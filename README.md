# CongressTrack for Mac

A native SwiftUI prototype for browsing congressional trade disclosures, inspired by the references CongressStock, Pelosi Tracker, and [LuxAlgo Market Trackers](https://github.com/LuxAlgo/market-trackers). Requires macOS 14+ and Xcode 15+. No account or API key required.

## Run on your Mac

Open `Package.swift` in Xcode, select the CongressTrack scheme and My Mac, then Run. Alternatively, from this directory:

```bash
swift run CongressTrack
```

To build a local `.app`:

```bash
bash scripts/build-app.sh
open dist/CongressTrack.app
```

The script creates an ad hoc signed local build. Developer ID signing and notarization are still needed for public distribution. This workspace is Linux; the Mac build and UI have not been run here.

## Included

- Native sidebar, searchable and sortable disclosure table, chamber/party/activity filters.
- Politician cards and persistent follow lists.
- Disclosure details showing reported ranges, ownership, transaction date, filing date, and disclosure delay.
- Original government filing links and parser review flags.
- Bundled public snapshot, latest-batch refresh with ID-based replacement, local caching, and refresh error handling.
- Separate timestamps for source ingestion and checking for updates. Cmd-R refreshes.

## Data and scope

The bundled snapshot contains 175 records downloaded on September 30, 2026 from [LuxAlgo's public data repository](https://github.com/LuxAlgo/market-trackers-data). The accompanying manifest reports congress ingestion at `2026-09-07T15:11:27.497Z`. The dataset is partial; it is not all congressional trades. The two website references returned HTTP 403 during research, so their layouts were not inspected or copied.

Launch and refresh download `congress/trades/latest.json` and `manifest.json` over HTTPS. The latest file is a delta: repeated refresh merges into the bundled and cached history, but does not recover every batch missed while the app was closed. A production version should ingest full year snapshots, reconcile corrections/deletions, and show source health. Prices and portfolio performance are not provided by this source. No returns, holdings, or exact transaction sizes are inferred from disclosures. Records with no ticker retain their original asset descriptions.

Follow lists and cached records live locally (UserDefaults and `~/Library/Application Support/CongressTrack`). Following currently filters the watchlist; background monitoring and notification alerts are not implemented. No brokerage integration is included.

## Verification

```bash
swift test
bash scripts/build-app.sh
```

The macOS GitHub Actions workflow runs these checks when this folder is used as a repository root. Unit tests cover missing tickers, disclosure delay, searching, and merging refreshed records. Mac compilation and interface verification remain to be performed on macOS.

Bundled data is CC0 per LuxAlgo's [data license](https://github.com/LuxAlgo/market-trackers/blob/main/data-licenses/DATA-LICENSE). LuxAlgo ingestion code has not been copied into this app.
