---
name: web-automation
description: >-
  Drive a real Chrome browser from the command line to automate web tasks on
  your own accounts and sites — fill forms, click through UIs, send emails from
  a web client, scrape a logged-in page, use a web app as an ad-hoc API. Uses
  the `chrome-agent` CLI (Chrome DevTools Protocol). Load this whenever a task
  means operating a browser, a page ignores a scripted click, or you need
  trusted mouse/keyboard input, cross-origin-iframe / shadow-DOM interaction,
  screenshots of a rendered page, or authenticated in-page fetches.
---

# Web automation via chrome-agent (CDP from the CLI)

You drive a real Chrome through the Chrome DevTools Protocol from the shell.
The agent's clicks and keystrokes travel the **same path inside Chrome as a
human's**, so pages that reject scripted automation still accept them. This
skill is the *method*; the tool ships the authoritative *mechanics*.

## Scope — read first

Use this on **accounts and sites you own or are authorized to automate**.
The right uses are your own workflows: your email/web clients, your dashboards,
internal tools, your own test sites. Do **not** use this to defeat CAPTCHAs,
bot-detection, or access controls on sites you don't control, to
scrape/abuse third-party services against their terms, or to impersonate a
human where a site has decided it doesn't want automation. Those are out of
scope for this skill regardless of how it's framed. If a page fights back and
it isn't yours, stop — that's a signal to get permission or use a real API,
not to climb harder.

## Step 0 — is the tool here?

```bash
chrome-agent --version || uv tool install chrome-agent   # or: pip install chrome-agent
```
Requires a system Chrome/Chromium. Only runtime dep is `websockets`.

## Step 1 — always read the shipped guide first

The tool prints its own authoritative, version-correct guide. **Run it** — it
tracks the live protocol and is more current than anything written here:

```bash
chrome-agent guide          # full agent guide (mechanics, gotchas, Monitor)
chrome-agent help <inst> <Domain>[.<method>]   # live protocol reference from the running browser
```

This skill deliberately does **not** duplicate the guide (it would go stale).
This file is the *decision procedure* and the *reuse workflow*; `chrome-agent
guide` is the reference. Read both.

## The mental model

An agent does two things in a loop: **sense** the page, then **act** on it.
There is no separate "verify" step — **the next sense is the verification.**
Never trust an action's return value; an act that "succeeded" with no error can
have done nothing. Confirm through a *different channel* than the one you acted
on (clicked a button → check the URL / the network / the DOM result, not the
click's return).

Senses (match the channel to the question):
- **What the page *says*** → `DOM`, `Accessibility`, `Runtime.evaluate`. Primary, high-fidelity.
- **What it *looks like*** → `Page.captureScreenshot`. Last resort for reading content (pixels are lossy); right choice for layout / images.
- **What it *reports*** → `Network`, console (`Runtime`), `Log`.

## The escalation ladder — climb only as high as the page forces you

Start cheap. Escalate one rung **only when the rung below silently no-ops** —
not when a selector looks wrong. Log/verify at each rung before climbing.

**Rung 1 — synthetic (free, instant, the default).** A scripted
`element.click()` or direct in-page JS via `Runtime.evaluate`. If the page
exposes an API or the control is an ordinary button, this is all you need.
Events are stamped `isTrusted: false`.

**Rung 2 — trusted input (real Chrome input path).** When a synthetic click
silently does nothing, the page is gating on event trust. Use `Input.*`, which
enters Chrome's native pipeline and is stamped `isTrusted: true`. This reaches
what synthetic clicks can't: cross-origin iframes, capture-phase overlays,
shadow-DOM overlays, canvas apps, drag-and-drop UIs. A real click is
**press + release** at viewport coordinates:

```bash
# locate: center of the OUTER element (inner nodes can return 0,0,0,0)
chrome-agent <inst> Runtime.evaluate '{"expression":"(()=>{const r=document.querySelector(\"#submit\").getBoundingClientRect();return{x:Math.round(r.x+r.width/2),y:Math.round(r.y+r.height/2)};})()","returnByValue":true}'
# act (trusted): press then release
chrome-agent <inst> Input.dispatchMouseEvent '{"type":"mousePressed","x":400,"y":300,"button":"left","clickCount":1}'
chrome-agent <inst> Input.dispatchMouseEvent '{"type":"mouseReleased","x":400,"y":300,"button":"left","clickCount":1}'
# sense again (independent channel): did state change?
chrome-agent <inst> Runtime.evaluate '{"expression":"location.href","returnByValue":true}'
```
Trusted `Input` coordinates are viewport-relative — Chrome routes the event to
whatever is under them, **including inside a cross-origin iframe**, with no
iframe-relative math.

**Rung 3 — human-fidelity interaction.** Only for UIs that legitimately need
realistic motion/timing (some drag-based widgets, gesture UIs on your own
sites). A drag is a real path: `mousePressed`, several `mouseMoved` steps with
eased/curved motion, `mouseReleased`. Vision (screenshot → reason → act) when
the page state only exists in pixels. Keep this rung within the Scope section
above.

## Common non-click patterns (often better than driving the UI)

- **Web UI as an ad-hoc API.** `Runtime.evaluate` running `fetch()` *inside* the
  logged-in page inherits its session — same-origin API calls, zero credential
  handling. Pass `awaitPromise:true` and `returnByValue:true`.
- **React-controlled inputs** need the native setter so React sees the change:
  ```bash
  chrome-agent <inst> Runtime.evaluate '{"expression":"(()=>{const el=document.querySelector(\"#email\");const set=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,\"value\").set;set.call(el,\"a@b.com\");el.dispatchEvent(new Event(\"input\",{bubbles:true}));})()"}'
  ```
- **Typing (trusted):** `Input.insertText '{"text":"..."}'` or `Input.dispatchKeyEvent`.
- **Screenshot decode:** `data` is base64 PNG at the top level (not `result.data`).
  Use `scripts/shot.sh <inst> <out.png>` in this skill folder.
- **Wait on readiness, not a fixed sleep:** poll `document.readyState === "complete"`
  or attach `+Page.loadEventFired` before acting.

## Step 2 — the reuse workflow (this is the whole point)

The value isn't solving a page once — it's **never having to solve it again.**

1. **Explore by hand.** Run the sense → act loop interactively. Climb the ladder
   until the flow works. Note the exact rung and coordinates/selectors that worked.
2. **Write the solved path down.** Capture the working command sequence as a
   committed artifact so no model is needed to replay it:
   - a shell script or Python driver in the target repo (`scripts/`), or
   - a small **project skill** (`.claude/skills/<flow-name>/`) if an agent should
     run it, or both.
   Use `scripts/replay-template.sh` in this skill folder as a starting skeleton.
3. **Loop it.** A written-down flow runs 1 or 1000 times with no model in the
   middle — that's the speed and cost win over a per-step MCP loop.

Solve once, reuse forever. That's how the same method travels across every repo.

## Cleanup discipline (not optional)

A launched instance is a full Chrome process that keeps running and eating
memory until stopped. When done with an instance **you** launched:

```bash
chrome-agent stop <inst>
chrome-agent status          # VERIFY it's gone — the stop's return is not the proof
chrome-agent cleanup         # drop any dead instances / stale session dirs
```
Keep an instance alive only deliberately (e.g. a login session you want later).

## Further reading & credits

- `chrome-agent guide` — the tool's authoritative, version-tracked mechanics.
- Multi-agent / human-agent collaboration and the "binding bridge" (observing a
  user's clicks/scroll/selection, which raw CDP doesn't expose): see
  `docs/collaboration-guide.md` in the chrome-agent repo.
- Built on **Corey Gallon**'s `chrome-agent` (<https://github.com/captivus/chrome-agent>),
  his talk (<https://www.youtube.com/watch?v=26RtyAm9y_Q>), and blog
  (<https://gallon.me>). The rung-ladder and trusted-input method are his.
