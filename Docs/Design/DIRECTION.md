# CongressTrack design direction

## Brief

Existing native macOS congressional disclosure tracker for people researching publicly reported trades. The daily action is to scan filings, narrow by member or asset, and open a record's original source. The user selected **a precise financial research desk**. Supporting feel: exact, composed, accountable (designer-authored interpretation). Deliverables: implemented SwiftUI redesign, three rendered directions, before/after, inspected screen set, and critique history. Existing product name, icon, features, data, and navigation destinations remain. No generated imagery or paid image credits are needed.

The app-designer process is adapted from iPhone to Mac: window chrome replaces the device frame; pointer/keyboard controls replace thumb-zone rules; minimum-size checks use 1060 × 680. macOS 14 support stays. The initial mockups are HTML reconstructions from source, not screenshots of a running native app. System fonts on this Linux renderer are substitutes; the Mac implementation uses SF families.

## Current app

Before is reconstructed in `before.html` from the committed SwiftUI screens and bundled dataset. It has a generic teal native sidebar, four equal-sized metric cards, rounded chart and member containers, and repeated headings. Its useful native table and source-health controls should stay.

History row: place / light / grotesque / teal / shape. The redesign must differ on at least three columns. Initial mechanical scan results are stored with the before render; the four equal cards and repeated accent roles are visual audit findings even if the scanner doesn't reject them.

## Keep / lose / unknown

Keep:
- [x] Disclosures, Leaderboard, Watchlist, Politicians, Alerts; saved searches and followed members/tickers.
- [x] Search, chamber/party/activity/ticker/date filters, sorting, counts, empty/error/loading states.
- [x] Original filing links, owner, trade/file dates, delay, amount ranges, provenance and review flags.
- [x] Source health, stale data warning, snapshot coverage, sync checks, offline caches.
- [x] Leaderboard sample/window/order controls, modeled stock and matched SPY returns, interactive graph, exclusions, event details, CSV import, price refresh and provenance.
- [x] Notifications, settings, menu bar, automatic updates and manual-only production signing.

Lose: four dashboard cards, decorative glyphs on summary counts, redundant taglines, boxed chart treatment, color competition between modeled returns and benchmark.

Unknown / unavailable: real market-price coverage until downloaded or imported; interactive VoiceOver and trackpad feel on a physical Mac. No simulated returns will be bundled as production data.

User decisions: none required to preserve scope. The product name, icon, destinations, and methodology stay. Graph emphasis changes from three equal metrics to excess return over matched SPY as the primary number, reflecting the requested S&P 500 comparison. Model and SPY totals remain visible in the legend and ranking. Any numerical chart fixtures used for layout review are explicitly labeled **illustrative**, and are absent from the application.

## Exploration

Three fully rendered alternatives use the same actual source records:
1. **Reading room** — CongressTrack is a public-records reading room. Place / light / serif / blue / illustration. Quiet architectural lines and serif headings.
2. **Research console** — CongressTrack is a calibrated research console. Object / dark / condensed / orange / colour-material. Graphite rail, amber selection, instrument typography, source-to-filing chronology.
3. **Public bulletin** — CongressTrack is a public-records bulletin. Printed / colour-field / expanded / pink / shape. Saturated masthead, broad display, stamp-like filing labels. Custom Bricolage Grotesque is tested in this exploration only.

Chosen after rendering: **Research console**. Its stable rail, clear tables, and amber focus match the user's research-desk brief. Reading room lost because its architectural decoration adds little to comparing records; Public bulletin lost because its saturated ground competes with financial data. The implementation uses SF condensed display and ordinary SF text, rather than turning every heading into a terminal label.

History comparison: object / dark / condensed / orange / colour-material differs from the existing place / light / grotesque / teal / shape on all five columns. No prior entries existed in this machine's design history.

## Category default refused

The audited existing app shows the category’s familiar teal summary-card dashboard. The new direction prioritizes filing records, measured chronology, and source verification; amber denotes research focus, while returns carry explicit signs and a neutral dashed benchmark. It avoids green-as-money styling, greeting headers, and a grid of hero statistics.

CongressStock and Pelosi Tracker were supplied as product references, but their pages returned HTTP 403 during the earlier research. No claim is made to have visually inspected those sites or a third competitor. The source repository/data and the current native code establish the available features; the verified visual audit is of CongressTrack itself.

## Tokens

| Role | Light | Dark |
| --- | --- | --- |
| ground | #F7F8FA | #181C21 |
| raised | #FFFFFF | #21262D |
| ink | #22272E | #EDF0F5 |
| ink-2 | #596370 | #B4BDC9 |
| rule | #DBE0E6 | #3B424C |
| accent | #A35A16 | #EDAD58 |
| on-accent | #FFFAF6 | #241A0E |
| selection | #FFF1DF | #3A3022 |

Rail: graphite #22272E (light) / #13171C (dark); labels #EEF1F5 and #B3BECA. Amber owns selection/action, the modeled series, and the selected filing chronology. The benchmark is neutral and dashed; gain/loss always has explicit signs rather than competing green/red hues. System controls retain native behavior. Toolbar tint follows the same accent role.

Type: SF Pro text for control/content roles, condensed SF display for titles, tabular SF numerals for money, dates, ranks and returns. Five to seven steps: 12 metadata, 13 body, 16 member headings, 22 section headings, 34 screen title, 40 ticker, 48 selected excess-return display. Display tracking -0.8 to -1.2. These are study size targets. Native SwiftUI uses semantic Mac text styles for title, section, body and caption, with scaled 40/48-point exceptions for the ticker and excess display; Mac semantic sizes need not equal browser pixels. No custom font added to the app. Bricolage Grotesque is a licensed exploration-only asset.

Spacing: 4 / 8 / 12 within groups; 20 / 28 / 32 between groups. Content margin 28; native table retains its own column alignment. Radius 6 for controls, 10 for native inset groups, 12 for previews of window corners. No decorative shadow or nested card system.

Richness source: the dark rail acts like a calibrated instrument housing. Warm amber marks the research focus on cold graphite; chronology turns a disclosed interval into a visible two-stop measurement. Data retains visual priority over imagery. No stock photos, portraits, artificial market curves, gradients, or glowing surfaces in the application.

## Signature: filing lens

Trigger: pointer or keyboard selects a disclosure. Frame 1: selected native row stays in place. Frame 2: the native inspector opens; transaction and filing dates sit at opposite ends of one line. Frame 3: the interval is expressed as days, with the original-source link below. Optional selection feedback on compatible hardware is not required; Mac keyboards and ordinary mice receive the same visual feedback.

Timing: a 220 ms spring updates the chronology when the selected filing changes. No whole-screen entrance animation. Reduce Motion shows the same state immediately. Reduce Transparency uses opaque rail/material surfaces. Original dates and ranges remain selectable text. Unknown/negative intervals retain explicit text, without inventing a timeline value.

## Content

The disclosure screen shows the bundled 175 records: 21 politicians, 67 purchases, 106 sales, and 2 exchanges (the purchase/sale counts do not claim to sum to all types). Source ingestion is Sep 7, 2026; its stale state is visible. Table fixtures are the seven most recent records sorted by filing date and identifier. Exact values are pulled into HTML from `Resources/trades.json`, rather than handwritten.

Labels: Disclosures, Leaderboard, Watchlist, Politicians, Alerts; Workspace, Following, Saved searches; Chamber, Activity, Party, Filing dates, Save search; Politician, Asset, Type, Disclosed range, Filed. Detail: Disclosure details, Close; Transaction → public filing; Traded, Filed, days until disclosure; Disclosed amount; Transaction / owner; Source; Open original filing. Empty preview: Choose a filing to inspect / Transaction / Public filing, without an invented record. Empty: No watched disclosures yet / Choose a disclosure, then follow its politician or watch its ticker / Browse disclosures.

Leaderboard controls remain Holding period, Minimum samples, Rank by excess return, Load market prices, Import price CSV; graphs show Model, S&P 500 · SPY, and Excess in percentage points. Layout-study fixture: Example member, 30 days, +7.43% model, +3.08% SPY, +4.35 pp excess, 3 scored / 2 skipped, explicitly illustrative. These fixture values do not enter the application or its caches. An unpriced app still shows its existing truthful empty state.

Settings, data health, alerts, and menu-bar content retain their existing data and actions; they inherit the theme without losing native form controls. The existing icon is included in the design set and retained in the app.


## Native implementation and verification boundary

Adaptive theme roles are implemented in `AppTheme`; headers use a quiet count line, with no summary-card grid. Table columns remain native and sortable. Responsive filter menus/date controls and leaderboard controls preserve all settings at narrower widths. The inspector has a Close action, a scrollable metadata region, a pinned original-source link, and the two-date chronology. Retrieval timestamps are readable UTC with their original exact string still available as selectable detail.

The graph displays percentage returns by subtracting the existing 100 baseline; the computation, weighting, matched SPY dates, rankings, and curve endpoint are unchanged. Its shared production domain is automatic and includes zero and any negative values; the 0–8% layout-study domain is only a fixture. A completed graph keeps its analyzed holding-period label during a subsequent calculation. Regression tests cover that state transition and UTC timestamp display.

The selected disclosure’s numeric delay uses a 220 ms spring and optional selection feedback, with Reduce Motion disabling animation. Opaque theme surfaces also support Reduce Transparency. Native semantic fonts, labeled controls, selectable metadata, and solid/dashed graph paths retain accessibility support. Actual VoiceOver and hardware feedback still require manual Mac review.

The seven-frame design set covers disclosures, selected inspector, benchmark comparison, filing-lens storyboard, dark disclosures, empty watchlist and retained icon. Politician grid, Alerts, Settings, Data health and menu bar are not separately storyboarded; their existing actions/data remain and the theme applies where appropriate. Before/after and concept sheets are reconstructions, not native execution evidence.
