# Calibration

A short interview before automating, **only when the gate says so** (see
SKILL.md "Use cases & calibration"): the request is open-ended and the
answers aren't already in context. Its purpose is alignment — knowing the
operator's intent — not form-filling.

Present each question one at a time, in this format: the question, 2–3
concrete options with a recommendation, and a one-line reason. **Skip any
question whose answer is already evident** (an old site with no CAPTCHAs
gets no challenge question).

Record the answers in the project notes (`.web-automations/NOTES.md`) when
the job is long-running or repeatable.

## The gate (run silently, first)

1. Has the operator already specified what/how — site, accounts, flow, approach?
2. Are we mid-conversation with that context fresh?
3. Is the request open-ended, no scope given?

→ If **1 or 2**: no interview; read the matching use-case doc and start.
→ If **3** and neither 1 nor 2: run the questions below.

## The six core questions

**Q1 — Purpose & horizon.** One-time pull, recurring, or an ongoing run?
*Options:* one-off / recurring (scheduleable) / long-running. *Why:* this
decides script-vs-hands-on, documentation depth, and pacing.

**Q2 — Site posture.** How hard does the site push back on automation?
*Options:* doc-less but relaxed / some friction / actively fights (challenges,
rate limits, bans). *Why:* effort and stealth calibrate to posture; fighting
sites need pacing, breaks, session hygiene — doc-less relaxed sites get the
fast path.

**Q3 — Challenge handling (operator's call, never a default).**
*Options:*
A) fully automatic — agent detects + solves, tracks how often challenges
   appear, and widens breaks as frequency rises;
B) human-gated — detect → pause → notify → operator clicks;
C) hard-stop — abort and touch nothing.
*Why:* this is a preference, not a rule; revisit if frequency shifts risk.

**Q4 — Pace & breaks.** Fast-and-loose, balanced, or careful? Should breaks
widen automatically when challenges or throttles appear?

**Q5 — Replicability.** Should this become a rerunnable, schedulable artifact
(script + checkpoints + notes), or is it a supervised one-shot?

**Q6 — Extraction preference.** Confirm the default stance below, or opt
into DOM-only.

## The UI/network stance (canonical)

Drive the UI like a user — navigate, click, type through the frontend, and
behave realistically. For data the page itself fetches, **passively harvest
the app's own network responses** (CDP Network: response → body): exact,
structured JSON, zero extra requests, invisible to the page. Never replace
the UI path with raw out-of-band API calls. When the app exposes no useful
endpoints, fall back to the DOM — and prefer the app's own URL
parameters/routes (state-as-API) over scraping rendered text.

## Settings map — answer → behavior

| Answer | Setting |
|---|---|
| recurring / long-running | checkpointed, resume-safe script + `.web-automations/` (NOTES + progress) |
| high-fight posture | pacing + breaks + session hygiene + passive network reading |
| Q3-A (fully automatic) | agent solves, tracks challenge frequency, widens breaks |
| Q3-B (human-gated) | detect → pause → notify → operator clicks |
| Q3-C (hard-stop) | abort on any challenge |
| verify/UX-only work | screenshots + evidence per step, no fixes |
