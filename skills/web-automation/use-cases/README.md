# Web-automation use cases

Decide which of these the job is, run the gate in `calibration.md`, open the
matching document, and start. The skill is static — these documents change
only when the operator asks. Findings from your work live in the project
(`.web-automations/`, see below).

## Which one is this?

- **Bulk data extraction** — harvest rows/pages of structured data from a
  site you're authorized to use (catalogs, listings, directory entries,
  result pages). → `bulk-data-extraction.md`

- **Form & workflow automation** — replicate a manual workflow in the UI:
  fill forms, click sequences, submit, download, send. →
  `form-and-workflow-automation.md`

- **Recurring monitoring / long-term runs** — the same job runs repeatedly,
  on a schedule, or for hours-to-days, and state must survive interruptions.
  → `recurring-monitoring.md`

## Doesn't fit one of these?

Mixed jobs ("scrape this site AND verify my own form after") happen — don't
invent a new category. Run the shared calibration, then **compose**: apply
the relevant questions, settings, and patterns from each matching section.
The calibration answers still apply as-is.

## The project workspace

For long-running or repeatable jobs, keep everything automation-related under
a project directory:

```
.web-automations/
  NOTES.md          ← the site, its mechanics (routes/endpoints/quirks),
                      anti-automation posture, decisions made, current resume
                      state + exact next command
  progress/         ← append-only checkpoints (one row per completed item)
                      + a cursor file (resume point)
```

A fresh-context agent must be able to take over purely from `NOTES.md` +
`progress/`. Scale the depth to the horizon: a one-minute job gets nothing,
an overnight run gets the full record.
