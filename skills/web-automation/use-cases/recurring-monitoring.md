# Use case: recurring monitoring / long-term runs

## 1. When it fits
The same automation runs on a schedule, repeatedly, or for hours-to-days;
state must survive interruptions and a fresh agent (or a new day) must be
able to take over. Applies to any of the other use cases with a long
horizon.

## 2. Extra questions (on top of the six core)
- Cadence and typical run length?
- Who operates it after setup — unattended overnight, or watched?
- Alerting: how should a failure reach a human (log line? file? exit code)?
- How much must persist between runs (cursor, dedupe set, session)?

## 3. Settings deltas
- **Checkpointed, resume-safe script is mandatory** (append-only output +
  dedupe keys + cursor), plus `.web-automations/NOTES.md` + `progress/` —
  the exact resume command must live in the notes.
- Pacing profile chosen from posture AND whether a human is present:
  unattended runs favor slower, safer profiles; attended runs can go faster
  (matches how bans actually happen: sustained unattended volume).
- Session refresh path documented (how to re-login / re-import cookies).

## 4. Operational patterns
- **Canary probe** separates "account/site degraded" from "genuinely empty":
  probe a known-good control after repeated blanks; abort loudly on a dead
  session instead of recording garbage.
- Appends + cursor writes are power-loss-safe; tolerate torn last lines on
  resume.
- Emit an event trace with durations (wait → outcome → ms) — it is the
  evidence for pacing and posture decisions later.
- Session and challenge discipline: single tab, no parallel; challenge
  frequency rising with session age is a signal to widen breaks or refresh
  the session.
- Run phases as commands (`status`, phase N, `resume`) so any agent can
  re-orient from `NOTES.md`.

## 5. Known traps (static; site-specific findings go to the project NOTES.md)
- **Unattended overnight runs trip rate limits** — schedule bursts or use
  the slow profile; bans are a function of sustained volume over time.
- **Session expiry mid-run looks like site breakage** — the canary
  distinguishes them; document the re-auth path.
- **Challenge/proxy infra failures masquerade as site problems** — a dead
  tunnel or expired IP rotation reads as a timeout wave; verify egress/IP
  before blaming the site, and pin the IP where the account depends on
  stickiness (one account per IP — shared pools can get you flagged by
  other users' traffic).
- **Canaries must count FAILURES, not successes** — a run of genuine empties
  is not a dead session; only flaky outcomes should alarm.
- Document-as-you-go: every finding about the site, its posture, and pacing
  goes into NOTES.md so a fresh-context agent inherits it; the skill itself
  stays static.
