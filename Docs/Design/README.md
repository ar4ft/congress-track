# Mac design studies

[Direction and feature inventory](DIRECTION.md) · [Critique history](CRITIQUE.md)

These are HTML reconstructions and layout studies, not captures of the native SwiftUI app. Disclosure values come from the bundled CC0 source records. The benchmark study uses explicitly illustrative prices and an **Example member**; these are not politician returns and do not ship as market data. The existing app icon is retained.

The invoked [app-designer skill](https://github.com/fortvna/app-designer) is adapted to macOS 14 windows. This replaces phone chrome and thumb-zone rules with native table, sidebar, inspector, pointer and keyboard conventions. Apple fonts are not installed in the Linux renderer; fonts are approximations here, and native SwiftUI uses system SF families.

To reproduce from the repository root:

```sh
npx skills add https://github.com/fortvna/app-designer --skill app-designer --agent codex --yes
npm install --prefix .agents/skills/app-designer --no-audit --no-fund
python3 Docs/Design/tools/build-mockups.py
node Docs/Design/tools/render.mjs Docs/Design/explore.html --out Docs/Design/shots/explore --scale 3
node Docs/Design/tools/render.mjs Docs/Design/mockup.html --out Docs/Design/shots/r4 --scale 3
node Docs/Design/tools/render.mjs Docs/Design/mockup.html --out Docs/Design/shots/r4-small --width 1060 --height 680 --scale 3
node Docs/Design/tools/render.mjs Docs/Design/before-after.html --out Docs/Design/shots/before-after --scale 3
```

Install Chromium (or set `APP_DESIGNER_CHROME` to its executable) if unavailable. The wrapper serves repository files over loopback while rendering, then stops its server. It preserves the upstream scan's contrast, typography, collision, copy and palette checks. Two platform corrections are documented in its code: Mac canvases are not skipped by the small-phone rule; ink boxes respect actual scroll/ellipsis clipping. It does not disable scan failures.

Warnings for 13px native checkbox artwork and 30px minimum-window toolbar buttons concern iPhone touch targets. Mac checkboxes sit in clickable labels and retain native keyboard behavior; pointer controls use Mac sizing, named accessibility labels, help and keyboard shortcuts; they need not become 44px mobile buttons. Dense tables intentionally use a limited body/metadata scale around a large screen title. No text is made smaller to fit the minimum window.

Main proofs: `shots/explore/sheet.png`, `shots/before-after/sheet.png`, and the final `shots/r4/sheet.png`. Open individual 3x PNGs for detail. Scan JSON sits beside each sheet. The final large and minimum-window scans have zero failures. The legacy “before” comparison retains its original contrast failures as audit evidence; it is not a passing final screen. Study scrollbars are drawn from actual DOM viewport/content ratios to remain visible in headless Chromium; production uses native scroll indicators and the system’s scrollbar preference.

Native validation is through GitHub's macOS CI: Swift unit tests, Intel/Apple silicon packaging, app launch, and update integrity. Mockup scans do not prove native rendering or VoiceOver, motion timing, keyboard feel, notification delivery, or layout at every macOS accessibility setting; those need a running Mac.

The four critique rounds reached 2 → 6 → 9 → 10 of 12 design lines scoring 4, with no final score below 3 and Fidelity 4. The final correction made chart labels readable at both sizes; iteration stopped at the four-round budget. The research console won over the reading room (less useful decoration) and public bulletin (color competed with records). The filing lens is the signature interaction. See the linked direction inventory for preserved features and the critique for evidence.
