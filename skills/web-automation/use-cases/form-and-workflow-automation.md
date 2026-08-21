# Use case: form & workflow automation

## 1. When it fits
Replicating a manual workflow through the UI: fill forms, click through
sequences, submit, upload, download, send from a web client. The output is
work done, not data captured — if it's data rows you're after, see
bulk-data-extraction.

## 2. Extra questions (on top of the six core)
- Which steps are the fragile ones (the ones that used to break by hand)?
- After the first run: is the flow driven by the app's own endpoints? (Cheap
  signal: `performance.getEntriesByType("resource")`.)
- Failure budget: retry-and-continue, or stop on first failure?
- Who consumes the output — a report put in front of a human?

## 3. Settings deltas
- **Validate every act through a different channel** (URL shift, network
  request, DOM result — not the action's return value). A "successful" click
  that fires nothing is the #1 workflow failure.
- React inputs need the native setter; clicks that no-op need trusted
  `Input` events (see SKILL.md escalation ladder).
- The UI/network stance applies: prefer the app's own routes/params for
  state changes, but keep driving the flow through the frontend like a user.

## 4. Operational patterns
- Break the workflow into labeled steps and emit a trace (step → waited-for
  signal → outcome → duration) so a failed run reads like a log, not a
  mystery.
- Where the UI fights back, prefer the app's own equivalent action (a
  saved-view URL, a keyboard shortcut) over increasingly exotic clicks.
- Keep the session for continued use (don't stop the instance unless done).
- For long or repeated workflows, write NOTES.md + progress/ in
  `.web-automations/` (exact step list + resume point).

## 5. Known traps (static; site-specific findings go to the project NOTES.md)
- **"It succeeded" but nothing happened** — verify through another channel;
  a form that never submits is the classic silent no-op.
- **Multi-tab / extra windows break implicit target selection** — DevTools
  or a popup makes single-target commands error; be explicit about the
  target (see SKILL.md "Targeting tabs").
- **Overlays and capture-phase layers swallow clicks** — trusted `Input`
  events at viewport coordinates route to whatever is actually on top.
- **Navigation kills context** — pending evaluates error "context
  destroyed" mid-navigation; retry on the new page.
