# Web automation (chrome-agent)

This project can drive a **real Chrome browser from the command line** to
automate web tasks on the user's own accounts and sites. The capability is the
`chrome-agent` CLI (Chrome DevTools Protocol); the method is documented in
`skills/web-automation/SKILL.md`.

**When a task involves operating a browser** — filling forms, clicking through a
UI, reading a logged-in page, using a web app as an ad-hoc API, or a page that
ignores scripted clicks — read `skills/web-automation/SKILL.md` and follow it.

Quick start:

```bash
chrome-agent --version || uv tool install chrome-agent   # needs system Chrome
chrome-agent guide                                       # authoritative mechanics
```

Then use the sense→act loop and the escalation ladder described in the skill.
Scope: the user's own accounts/sites only — see the Scope section in the skill.
Do not use this to defeat CAPTCHAs/bot-detection or automate third-party
services against their terms.
