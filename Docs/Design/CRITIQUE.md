# CongressTrack critique history

## Round 1

Independent critic reviewed the before reconstruction and opened all seven individual Round 1 PNGs: Disclosures, Filing inspector, Benchmark comparison, Filing lens storyboard, Dark disclosures, Empty watchlist, and Existing icon. These are HTML layout studies, not captures of the native macOS app. Native Fluency is evaluated against macOS 14 windows, sidebar, table, inspector, toolbar, and pointer/keyboard conventions. The existing icon is a retained asset, not a redesign opportunity. Scores judge visible evidence; promised implementation behavior earns no extra points.

### Quick tests

- **Logo:** The graphite rail and amber focus suggest a research console, but Disclosures and Watchlist could still belong to many desktop record managers.
- **Squint:** The large heading leads most screens; the inspector competes with the unchanged Disclosures heading, and the Watchlist refresh action competes with its useful Browse action.
- **Category:** Removing teal cards and gain/loss colors improves the direction; a sidebar plus spacious table remains a familiar category skeleton.
- **Specificity:** Amber selection, neutral dashed SPY, and explicit disclosure delay have reasons; the large row heights, blank chart margins, and monospaced dark title do not yet share that precision.
- **Feature:** A plausible editorial headline is “A filing becomes a timeline you can verify,” but the verification action is not visible in the inspected inspector or storyboard.
- **Subtraction:** Removing the four summary cards improved the before screen; removing the repeated global Refresh disclosures button from Watchlist would improve action hierarchy, provided refresh remains reachable in the toolbar.

### Scores

A 4 means shippable studio work; a 5 means portfolio work. Fidelity is scored separately from the twelve-line stop-rule count.

| # | Rubric line | Score / 5 | Visible evidence |
| --- | --- | --- | --- |
| 1 | Concept on the pixel | 3 | The amber selected record and two-stop chronology communicate accountable research in the inspector, but the unselected table and empty Watchlist rely mainly on the rail palette to express the console concept. |
| 2 | Not the category average | 3 | The graphite/amber palette and unboxed benchmark depart from the teal card dashboard before, while the large title, filter strip, and spacious ruled rows retain a common desktop dashboard skeleton. |
| 3 | Not this skill's average | 4 | Ordinary proportional text, a substantial graphite rail, amber selection, and the modeled graph avoid the all-monospaced grey receipt default. |
| 4 | Hierarchy | 3 | Most headings lead clearly, but the inspector has two large competing titles and Watchlist exposes two equally accented actions with different relevance. |
| 5 | Typography | 3 | The large ticker, excess-return number, and quieter metadata create contrast, but the dark Disclosures title switches to visibly monospaced type and the broad table rows weaken the intended instrument typography. |
| 6 | Colour | 4 | Amber consistently marks selection, action, chronology, and the model; SPY stays neutral and dashed, while the dark screen has separately designed surface and rule contrast. |
| 7 | Richness | 3 | The rail, graph, and chronology supply restrained shape and color, but the Watchlist is mostly a generic outlined star over a large blank field and the storyboard adds little visual information. |
| 8 | Rhythm and space | 3 | Column starts are disciplined, but tall rows and a large header consume the working area, the chart has unused lateral space, and the inspector's important content falls below the frame. |
| 9 | Craft details | 2 | The benchmark has no return-axis labels and its 0%/100% progress labels sit outside the plotted endpoints; the inspector stops at Disclosed amount with its source action absent, and the bottom status strip cuts through the last visible table row. |
| 10 | Native fluency — macOS 14 | 3 | Window chrome, a persistent sidebar, search shortcut, sorting cue, and inspector division are recognizable Mac patterns, but large web-like filter buttons and the absence of visible inspector/utility toolbar controls keep this a reconstruction rather than convincing native UI. |
| 11 | Signature | 2 | The two-date disclosure lens is a useful premise, but all three storyboard panels show essentially the same completed chronology, with neither the selected row nor the original-source action shown. |
| 12 | The feature test | 3 | The composed inspector and amber/neutral comparison could support an editorial screenshot, but the current clipped verification flow and uncalibrated chart prevent a confident design feature recommendation. |
| 13 | Fidelity | 2 | All five primary destinations, filters, search, save, follow, watch, and Data health survive visibly, but Open original filing is below the captured inspector and Load market prices, exclusions/event details, and settings have no obvious route in this screen set. |

### Five changes for Round 2

1. **Make the inspector a usable verification surface — screen 02.** Pin an **Open original filing** action in a 44 pt inspector footer, keep metadata in an explicitly scrollable middle region, and use a compact chronology of about 120 pt with its existing dates and six-day delay. Show amount, owner, provenance/review flags, and source either above that footer or in the visible scroll region. Add the native inspector toggle/close control. Keep amount and filing date reachable in the narrowed table through native column sizing or a clear horizontal-scroll affordance; selecting a row must not silently remove access to those columns.
2. **Calibrate the benchmark — screen 03.** Put both series in one defined plot rectangle with a left axis titled **Return (%)**, a labeled zero baseline, and labeled ticks generated from the same numeric scale as the fixture. For this illustrative example, a 0–8% domain with 2 pp ticks is sufficient. Align holding-period 0% and 100% directly beneath the start and end of the curves, or use Day 0 and Day 30 at those exact positions. Place +7.43% and +3.08% at the corresponding actual y positions, use the same scale for both, and expose the 3 scored / 2 skipped row above the status strip. Retain the illustrative label and amber/neutral dashed treatment.
3. **Show the filing lens progressing — screen 04.** Replace the three repeated timelines with three distinct crops: (1) an actual selected row with its amber edge, (2) that record beside the opened chronology inspector, (3) the inspector with delay, provenance, and **Open original filing** visibly together. The same record, dates, and six-day interval must persist. Show the Reduce Motion note beneath the sequence; do not present “original source visible” beneath a panel with no source.
4. **Tune density and type for a research desk — screens 01, 02, and 05.** Use one proportional condensed heading family in both modes at 34 pt, 13 pt content/control text, 12 pt metadata, and tabular numerals for dates/money. Use roughly 48 pt two-line disclosure rows and a 220–240 pt sidebar at the 1060 × 680 minimum; larger windows may grow columns, not inflate every row. Reserve a fixed status-bar layout region so partial rows end inside the scrolling table rather than underneath status text. Keep the 40 pt ticker and 48 pt excess number as deliberate exceptions.
5. **Make retained utilities and the right primary action obvious — screens 03 and 06, shared toolbar.** Put disclosure refresh in the native toolbar with its existing shortcut/help, give Leaderboard an explicit **Load market prices** action next to **Import CSV**, and expose a named menu or disclosure for **Exclusions**, **Events**, and **Price provenance**. Add a visible Settings route or standard macOS Settings menu representation. On empty Watchlist, keep **Browse disclosures** as the sole prominent content action. These can be compact native controls; no additional dashboard cards are needed.

### Data and axis defects

- The benchmark fixture is explicitly labeled illustrative in two places. It is not represented as actual politician performance; that distinction is clear and should remain.
- The displayed arithmetic is correct: +7.43% − +3.08% = +4.35 percentage points. The inspector dates Aug 28 to Sep 3 correctly yield six days.
- The chart has no labeled return axis or identified zero baseline, so its endpoints cannot be verified against the displayed returns. This is a calibration defect, not evidence that the illustrative headline arithmetic is wrong.
- The holding-period 0%/100% labels span the content region while the plotted curves occupy a narrower, centered region. Consequently the visual start/end do not correspond to those labels.
- The summary counts are internally explainable: 67 purchases + 106 sales leave the two exchanges described in DIRECTION.md; no change is required, though the complete activity breakdown can remain available elsewhere.
- The final disclosure row and benchmark table body are cut by the captured status region; the inspector's range/source controls are absent from the frame. Explicit scrolling and pinned actions must make reachability evident.
- The storyboard says the original source is visible in its third panel, but that panel contains no source label or link.

### Round result

Only 2 of the 12 design lines reach 4, and Craft details and Signature are below 3. Fidelity is also below 3. This is a coherent direction with concrete layout defects still to resolve, rather than finished studio work. Native interaction, VoiceOver, and production feature preservation remain outside what these HTML PNGs can establish.

**Not done by the stop rule in critique.md.**

## Round 2

The same independent critic opened all seven individual PNGs in `shots/r2` and all seven in `shots/r2-small`, including both retained-icon renders. The minimum study is 1060 × 680; image scaling does not turn it into a native Mac screenshot. The reported zero scanner FAILs are useful mechanical evidence, but the scores below come from the rendered screens. Native implementation now exists; this review does not claim to have run it.

### Which Round 1 asks landed

| Round 1 ask | Result | Visible evidence |
| --- | --- | --- |
| Usable verification inspector | Landed, with minimum-window polish remaining | Close and the pinned Open original filing action are present at both sizes; amount, owner, source, review, and retrieval metadata appear in the large frame, and the narrow table explicitly tells the user to scroll for amount/filed columns. |
| Calibrated benchmark | Landed | Both series start at the labeled zero baseline, share 0–8% return ticks, end at accurately placed +7.43%/+3.08% labels, and align to holding-progress ticks; the 3 / 2 row is visible at both sizes. |
| Progressive filing lens | Landed | Select shows the amber record, Inspect adds dates and delay, and Verify adds amount, source, review, and the original-filing action; the record and six-day chronology stay consistent. |
| Density and typography | Mostly landed | Dark and light titles now use the same proportional face, rows are quieter, and complete large-window disclosure rows clear the status region; narrow inspector/filter/status wrapping still consumes working room. |
| Retained utilities and primary action | Landed | Refresh, Settings, and Inspector have toolbar routes; Leaderboard exposes price load/import and event/exclusion/provenance controls; Browse is the only amber content action in empty Watchlist. |

No declined asks were reported. The native density and existing icon remain accepted constraints.

### Quick tests

- **Logo:** The calibrated amber/neutral comparison and filing-to-source chronology now express the research console without requiring its name; the empty Watchlist remains more generic.
- **Squint:** The inspector ticker owns the selected state, the excess number owns the comparison, and Watchlist has one relevant content action.
- **Category:** The cardless comparison and verification workflow are distinct improvements, but the list/rail/filter skeleton remains familiar.
- **Specificity:** The return scale, matched endpoints, delay, and pinned source action are purposeful; the wrapped keyboard shortcut and inspector status layout are accidental.
- **Feature:** “Select a public record; inspect its delay; verify its source” is now actually shown, although the overall screen set still needs stronger finish for an editorial feature.
- **Subtraction:** The removal of large content Refresh buttons improved every screen; the stable toolbar keeps the action available.

### Scores

| # | Rubric line | Round 1 | Round 2 / 5 | Visible evidence |
| --- | --- | --- | --- | --- |
| 1 | Concept on the pixel | 3 | 4 | The inspector joins an amber selected record to a measured disclosure interval and pinned source action, while the comparison has a visibly calibrated shared return scale. |
| 2 | Not the category average | 3 | 3 | Card removal, restrained amber, and explicit provenance distinguish the direction, but the spacious sidebar/filter/table structure remains a recognizable financial-records application pattern. |
| 3 | Not this skill's average | 4 | 4 | A graphite housing, proportional headings, an amber modeled series, and clear light/dark surfaces avoid the grey monospaced receipt default. |
| 4 | Hierarchy | 3 | 4 | Disclosures becomes subordinate when the large inspector ticker appears, the graph's excess number leads, and Watchlist now has one prominent Browse action. |
| 5 | Typography | 3 | 4 | Light and dark titles now agree, ticker and excess numerals have deliberate scale contrast, and table metadata is quieter than names and tickers. |
| 6 | Colour | 4 | 4 | Amber still owns focus/action/model/chronology, SPY remains neutral and dashed, and the designed dark surface hierarchy survives the minimum-size frame. |
| 7 | Richness | 3 | 3 | The plotted comparison and staged chronology provide meaningful shapes, but the large empty Watchlist still consists of a generic star and text in an undifferentiated field. |
| 8 | Rhythm and space | 3 | 3 | The large disclosure screen is calmer and complete, but minimum-width Save search wraps to a second row, the inspector status expands into broken lines, and metadata reaches a hard clipped scroll boundary. |
| 9 | Craft details | 2 | 3 | Chart alignment and real filing metadata now withstand inspection; remaining rough edges are the missing-glyph-looking source-link suffix, raw retrieval timestamp, wrapped shortcut, and narrow status text. |
| 10 | Native fluency — macOS 14 | 3 | 3 | Toolbar utilities, Close, and pinned inspector action strengthen the Mac pattern, but the two-line minimum-window search field/shortcut and absent visible scroll cues still look like an HTML reconstruction under pressure. |
| 11 | Signature | 2 | 4 | The three distinct storyboard states now clearly show the same selected filing becoming a chronology and then a verifiable original-source action. |
| 12 | The feature test | 3 | 3 | The inspector and calibrated comparison are credible research-tool screenshots, but the minimum-size rough edges and generic empty state still limit an editorial design feature. |
| 13 | Fidelity | 2 | 4 | All five destinations and retained search/filter/save/follow/watch/source/health/price-import routes are visibly present, with events, exclusions, provenance, and Settings now reachable; this does not certify unseen production functions. |

### Five remaining concrete fixes

1. **Keep the minimum-size toolbar on one line — all `r2-small` screens.** Make the search control a single-line native field, truncate its placeholder to **Politician or ticker** if necessary, and keep **⌘F** unbroken in its own trailing slot. Use 28–32 pt toolbar controls. At 1060 pt width, use native icon toolbar items with help labels for Refresh/Inspector or an overflow menu rather than letting search become two lines. Preserve Settings reachability.
2. **Give the narrow inspector a compact working layout — `r2-small/02`.** Keep Save search on the filter row by shortening labels or using a native filter menu once the inspector is open. Replace the three long status fragments with one concise stale-source line plus a single-line **Data health** link; move coverage detail to the health view or a second deliberately arranged line. Target a 32–40 pt status region instead of the current multi-line block. Do not enlarge table rows or remove retained filters.
3. **Show that metadata and comparisons continue — screen 02 at both sizes and screen 03 at minimum size.** Draw the actual vertical scrollbar or a clear scroll affordance for the inspector middle region, and a horizontal scrollbar for the narrowed table in addition to its useful scroll instruction. Keep Open original filing pinned. Ensure the minimum Leaderboard makes Purchase events / Excluded records / Price provenance discoverable through a visible scroll affordance or a compact visible details menu; those controls currently fall beneath the captured frame.
4. **Finish provenance and link typography — screen 02 and storyboard Verify.** Replace the small box-like suffix after Open original filing with the same supported external-link symbol used by the native app, or omit the suffix in the study. Display retrieval time as **Sep 4, 2026 · 20:31 UTC** with the exact timestamp available through selectable detail/help; the ISO string is accurate but visually dominates the research metadata. Keep source/review text and data selectable.
5. **Make empty Watchlist belong to this console — screen 06.** Replace the isolated outlined star with a small static filing-lens preview using the existing selected-row edge, two endpoint markers, and an honest **Choose a filing to inspect** label. Do not invent a delay, amount, member, or activity. Keep Browse as the single prominent action, use the same 24–28 pt content alignment as other screens, and limit the preview to roughly 120 pt high so this remains a quiet useful empty state.

### Data and layout checks

- The return arithmetic remains correct: +7.43% − +3.08% = +4.35 pp. The plotted endpoint positions match the labeled 0–8% axis to visual precision, and the holding-progress ticks now align with the plot.
- The labels still expressly identify illustrative prices and a layout study. No measured politician performance is implied.
- Aug 28 to Sep 3 remains six days. The member, ticker, dates, range, and house-clerk source persist across inspector/storyboard states.
- The shared graph scale fixed Round 1's axis defect. A production chart must derive its domain from real values, including negative returns, rather than retaining this study's 0–8% fixture domain; this is an implementation condition, not a defect in the explicitly illustrative example.
- Partial rows at the boundary of a scrolling native table are acceptable. The new fixed boundary and horizontal-scroll instruction address the previous silent loss of columns; a visible scrolling cue is still needed in the study.
- The pinned source action is fully visible at minimum size. Source/review metadata below the scroll boundary is acceptable when the scroll region is made evident.
- The minimum-size search placeholder and shortcut wrap, and the narrow inspector splits Data health into two lines. The automatic scans do not invalidate these visible layout defects.
- Existing icon preservation is confirmed. Its original teal is not a reason to reintroduce teal into the application interface.

### Round result

6 of the 12 design lines are now at 4; none are below 3. Fidelity rises to 4. The Round 1 functional visual defects were substantially addressed, and this is a meaningful improvement rather than a scoring plateau. The stop rule requires at least 9 of 12 lines at 4, so the remaining minimum-window finish and empty-state specificity still matter. Scores do not claim native execution, VoiceOver validation, or unseen production feature verification.

**Not done by the stop rule in critique.md.**

## Round 3

The same independent critic opened all seven individual `shots/r3` PNGs and all seven `shots/r3-small` PNGs. The retained icon was inspected at both sizes and remains unchanged. These continue to be HTML studies; no native Mac execution or VoiceOver certification is inferred. Zero reported scan FAILs support mechanical review but do not replace pixel inspection. After spotting very small chart labels, the critic read the SVG sizing in `tools/build-mockups.py` only to quantify the visible issue; no UI or generator code was edited.

### Which Round 2 asks landed

| Round 2 ask | Result | Visible evidence |
| --- | --- | --- |
| Single-line toolbar | Landed | Every minimum frame keeps Politician or ticker and ⌘F on one line; compact Refresh/Inspector items and labeled Settings fit without increasing titlebar height. |
| Compact narrow inspector working layout | Landed | Filters and Save search share one row; Source stale and Data health fit a compact single-line footer with more room for records. |
| Visible continuation and retained utility access | Landed | Horizontal/vertical scrollbars show the table and inspector bounds; purchase events, excluded records, and price provenance now sit above the comparison and stay visible at minimum size. |
| Provenance/link finish | Landed | The original-source action now uses a clear external-link shape, retrieval time has a human UTC presentation, and exact timestamp detail is indicated. |
| Direction-specific empty Watchlist | Landed | The star is replaced with the filing lens's amber edge and endpoint track, without a fabricated member, amount, dates, or delay. |

No asks were declined. The new compact controls retain Mac density and the existing icon.

### Quick tests

- **Logo:** The filing preview carries the chronology idea even into an empty screen; the console now has a consistent visual premise across its core states.
- **Squint:** Ticker, excess return, and the single Watchlist action retain priority; compact toolbar controls do not compete with them.
- **Category:** The sidebar/table skeleton is familiar, while the filing-to-source lens remains the distinguishing workflow.
- **Specificity:** The constrained source footer, split scrolling regions, amber source action, and instruction preview each have a clear job.
- **Feature:** The verification screenshot is composed and accountable; the set is studio-ready as a direction, although restrained enough that editorial feature quality remains a 3.
- **Subtraction:** Removing the new Watchlist preview would erase the concept from that state; removing compact utility access would make the minimum comparison harder to research.

### Scores

| # | Rubric line | Round 2 | Round 3 / 5 | Visible evidence |
| --- | --- | --- | --- | --- |
| 1 | Concept on the pixel | 4 | 4 | Calibrated comparison, selected chronology, pinned original source, and the honest empty filing preview now share the same research-console idea. |
| 2 | Not the category average | 3 | 3 | The lens and amber/neutral comparison have specificity, while the spacious rail/filter/table skeleton remains familiar to desktop financial research tools. |
| 3 | Not this skill's average | 4 | 4 | Graphite material, proportional headings, warm focus, and readable content hierarchy keep the direction distinct from an all-monospaced receipt. |
| 4 | Hierarchy | 4 | 4 | Inspector ticker and source action, comparison excess number, and Watchlist Browse each own their state without a competing large refresh button. |
| 5 | Typography | 4 | 4 | Consistent light/dark heading treatment and tabular financial values maintain the intended hierarchy; tiny SVG chart labels are recorded separately as a concrete craft defect. |
| 6 | Colour | 4 | 4 | Amber retains its explicit focus/action/model/chronology roles, the benchmark stays neutral and dashed, and dark contrast remains controlled. |
| 7 | Richness | 3 | 4 | The new empty preview extends the selected-record edge and two-endpoint shape into Watchlist, joining the rail, graph, and chronology under one restrained art direction. |
| 8 | Rhythm and space | 3 | 4 | Minimum inspector filters and status now stay on deliberate single lines, independent scroll regions end cleanly, and the primary source action remains fully visible. |
| 9 | Craft details | 3 | 3 | Metadata and external-link finish improved, but the minimum comparison's axis, tick, and endpoint text is visibly much smaller than surrounding 12 pt metadata. |
| 10 | Native fluency — macOS 14 | 3 | 4 | Compact toolbar items, an unbroken search shortcut, responsive filter menu, distinct scroll regions, Close, and pinned inspector action now convincingly express desktop control conventions in the static study. |
| 11 | Signature | 4 | 4 | The three distinct filing-lens states still connect the same record to a six-day chronology and original-source verification, with reduced-motion behavior stated. |
| 12 | The feature test | 3 | 3 | The selected inspector and comparison are composed, useful screenshots, but the restrained generic table skeleton and tiny plotted labels limit an editorial feature recommendation. |
| 13 | Fidelity | 4 | 4 | All previously restored destinations/actions remain reachable; compact filters and visible scrollbars preserve the narrowed table's amount/filed access, while comparison utilities remain visible above the graph. |

### Remaining concrete defect and follow-up

**Fix plotted label size — screen 03, especially `r3-small`.** The SVG has a `940 × 280` viewBox, internal 12-unit text, and a minimum-window height of 150 pt. Its uniform fit scales that text to about **6.4 pt**, versus about **9.4 pt** at the 220 pt large-window height. This matches the visible tiny return ticks, progress ticks, titles, and endpoint labels. Keep these labels at **11–12 pt in window coordinates** by using unscaled text outside the plot or responsive SVG geometry/font sizing. Keep the chart's existing axis domain, accurate endpoint positions, shared series scale, amber/neutral roles, illustrative note, and visible scored/skipped row. Do not enlarge every other control to compensate. Re-render both comparison sizes and have this same critic rescore the correction, or explicitly label the correction unscored as the rubric requires.

There are no additional blocking pixel defects to invent merely to fill a five-item list. Native keyboard/trackpad operation, system scrollbar preference behavior, selectable exact timestamp, VoiceOver, and full production feature preservation remain real-Mac verification work, not failures asserted from these studies. The 30 pt Mac toolbar and native checkbox targets are accepted, and the retained icon is accepted.

### Data and layout checks

- The shared return axis and holding-progress positions remain calibrated. +7.43% − +3.08% still yields +4.35 pp, and the endpoint positions match the stated values.
- The fixture is still explicitly illustrative. No actual politician return or invented Watchlist record is presented.
- The inspector/storyboard preserve Jonathan Jackson, VSAT, Aug 28/Sep 3, six days, amount range, and original filing verification. Human retrieval time remains consistent with the recorded UTC timestamp.
- The minimum inspector's cropped lower metadata now has a clear vertical scroll cue; the source action is pinned outside that region. Narrowed columns have an explicit horizontal scrollbar and instruction.
- The comparison's clipped bottom method text is inside an evident scrolling content region, not obscured by status text; this is acceptable desktop behavior.
- The small chart-label issue is a legibility defect rather than an arithmetic or axis-domain mismatch. Automatic scan success did not catch it.

### Round result

**9 of 12 design lines are at 4, and none are below 3. Fidelity remains 4.** The score trend is 2 → 6 → 9 qualifying lines, so no plateau applies. The design meets the stop rule for the reviewed HTML studies. The concrete chart-label defect must still be corrected and either rescored or disclosed as unscored; meeting the stop rule does not erase it. Native app execution and VoiceOver remain uncertified.

**Done by the stop rule in critique.md.**

## Round 4 — final focused correction

The same critic opened both corrected individual `03-benchmark-comparison.png` frames in `shots/r4` and `shots/r4-small`. A fresh SHA-256 comparison confirmed that only the comparison PNG changed in each seven-frame set; all six other frames are byte-identical to Round 3. Their established evidence and scores therefore carry forward. This is the fourth and final budgeted critique round, with no new taste pass.

### Correction result

**The tiny plotted-text defect is resolved.** Return ticks, progress ticks, axis titles, and endpoint values are now legible at both window sizes and visually match the neighboring metadata scale. The wider plot uses the available comparison width while retaining the same numeric domain and progress mapping. The illustrative label, shared zero baseline, neutral dashed SPY, amber model, controls, and scored/skipped row remain visible. There are no new collisions or clipped endpoint labels.

### Final scores

| # | Rubric line | Round 3 | Round 4 / 5 | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Concept on the pixel | 4 | 4 | Calibrated comparison and filing-to-source lens remain; unchanged core frames retain their Round 3 evidence. |
| 2 | Not the category average | 3 | 3 | The direction remains specific in workflow and color, with a familiar desktop rail/filter/table skeleton. |
| 3 | Not this skill's average | 4 | 4 | Graphite, amber, proportional text, and distinct visual measurements remain unchanged. |
| 4 | Hierarchy | 4 | 4 | The excess-return number still leads the comparison, and legible plot labels support rather than compete with it. |
| 5 | Typography | 4 | 4 | Corrected plot text now holds its metadata scale at minimum width; established heading/table hierarchy is unchanged. |
| 6 | Colour | 4 | 4 | Amber model and neutral dashed SPY preserve the established single-accent system. |
| 7 | Richness | 4 | 4 | The plot now fills its working width; unchanged rail, chronology, and filing preview retain one restrained art direction. |
| 8 | Rhythm and space | 4 | 4 | Corrected comparison preserves visible controls and scored/skipped information at both sizes; other responsive layouts are unchanged. |
| 9 | Craft details | 3 | 4 | Axis/progress/endpoint labels are now readable, aligned, and unclipped, resolving the last concrete defect named in Round 3. |
| 10 | Native fluency — macOS 14 | 4 | 4 | Unchanged compact toolbar, responsive filters, scroll cues, and pinned inspector source action retain their Round 3 evidence. |
| 11 | Signature | 4 | 4 | The byte-identical three-state storyboard still connects selection, chronology, and original-source verification. |
| 12 | The feature test | 3 | 3 | The research console is composed and useful; its restrained familiar desktop skeleton does not by itself earn a stronger editorial-feature score. |
| 13 | Fidelity | 4 | 4 | No restored route disappeared, comparison utilities remain visible, and all other frames are identical to the prior reviewed set. |

### Final defect and data check

- No remaining concrete pixel or axis defect was found in this focused correction. No additional polish requests are introduced.
- Both curves share the labeled 0–8% return domain and zero baseline. Their start/end positions match the 0%/100% progress ticks; endpoint positions still match +7.43% and +3.08%.
- +7.43% − +3.08% = +4.35 pp remains correct; scored/skipped remains 3 / 2. The values are explicitly illustrative and are not actual politician returns.
- Bottom method text remains within an evidently scrollable content region. The pinned status strip does not imply that the content is unavailable.
- Native macOS execution, VoiceOver, keyboard/trackpad feel, and full production functionality remain uncertified by these HTML studies. That is the scope of the evidence, not an additional pixel defect or a reason to continue this critique budget.

### Final result

**10 of 12 design lines are at 4, none are below 3, and Fidelity is 4.** The qualifying-line trend is 2 → 6 → 9 → 10. The final concrete correction was reviewed and rescored; there are no unscored visual changes in this final set. Stop design iteration under the rubric and carry the stated native-validation limits into the delivery report.

**Done by the stop rule in critique.md.**
