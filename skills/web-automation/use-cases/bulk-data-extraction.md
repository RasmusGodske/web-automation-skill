# Use case: bulk data extraction

## 1. When it fits
Turning a site's rows/pages into structured data you're authorized to
collect: product catalogs, listings, directory entries, search-result pages.
If it's not about data output, see form-and-workflow or recurring-monitoring.

## 2. Extra questions (on top of the six core)
- Expected volume (tens? thousands?) — decides checkpoint granularity.
- Pagination model: numbered pages, Next-button, infinite scroll?
- Recurring schedule (feeds Q5) and destination format (CSV/JSON/Db)?
- Any rows that look empty-but-shouldn't (drives the canary choice)?

## 3. Settings deltas
- Default stance from calibration: UI-driven navigation + passive harvest of
  the app's own responses; DOM only when no useful endpoints exist.
- Volume → append-only output with a **dedupe key per row** (resume-safe:
  re-running never duplicates, never re-fetches a done key).
- Posture from Q2 sets pace/breaks; don't run extraction faster than the
  site's own UI would page through it.

## 4. Operational patterns
- **Canary**: know one item that exists; when everything turns "empty",
  probe it — separates "site stopped serving" from "nothing there" before
  you record data.
- Verify pagination via a real signal (footer range text, URL change), not
  a sleep; a page that didn't advance is a failure, not a wait.
- Screenshot at page boundaries; pixels catch what DOM text hides (page
  didn't actually change, wrong page rendered).
- Session hygiene: single tab, no parallel requests; session expiry mid-run
  looks like site breakage — the canary catches it.
- Long jobs: write NOTES.md + progress/ in `.web-automations/` and keep the
  resume command exact (see recurring-monitoring for the discipline).

## 5. Known traps (static; site-specific findings go to the project NOTES.md)
- **Column/index assumptions drift across redesigns** — anchor on header
  texts, not fixed cell indices; re-verify with a screenshot when the UI
  changes.
- **Virtualized grids** — only visible rows exist in the DOM; the extractor
  must sweep the scroll container, and a row can be captured once by key.
- **"No matches found" ≠ broken** — could be a genuine empty. Classify
  (route/state/empty/transient) before concluding.
- **Bans masquerade as maintenance** — an "access denied / multiple accounts /
  permanent block" page may wear a "scheduled maintenance" banner. Match the
  ban text explicitly and hard-stop; never grind a ban.
- **Wrong-route blanks** — apps with two id-spaces render blank shells on
  the wrong route; try the site's own equivalent route (how the app itself
  links the item) before concluding "no data".
- **Challenge widgets hide in OOPIFs** — invisible to page DOM; detect at
  the browser-target level (see SKILL.md CAPTCHA section) and follow the
  operator's chosen posture.
