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

Use this on **accounts and sites you own or are authorized to automate**:
your email/web clients, your dashboards, internal tools, your own test sites.
Do **not** use this to defeat access controls or scrape third-party services
against their terms. If a page fights back and it isn't yours, stop — get
permission or find a real API; don't climb harder.

Within authorized work, *how* pages that fight back are handled is the
**operator's preference, decided in the calibration (below)** — never a
silent default. Some operators want fully automatic challenge handling
(solve, track frequency, widen breaks as challenges rise); others want
challenges handed to them to click; others want an immediate stop. Ask.

## Use cases & calibration — orient before automating

This skill is **static**: its documents change only when the operator asks.
Findings from your work live in the **project**, not here (below).

Different jobs need different behavior. Decide which use case this is, and
calibrate when the job is open-ended:

- **`use-cases/README.md`** — the classifier: which kind of automation is
  this (bulk data extraction / form & workflow / recurring monitoring), and
  how to treat mixed jobs.
- **`use-cases/calibration.md`** — a short interview run *before* touching
  the browser, one question at a time (options + a recommendation each),
  covering purpose & horizon, site posture, challenge handling, pace,
  replicability, and extraction preference.

**The gate (run silently first):**
1. Has the operator already specified what/how — site, accounts, flow, approach?
2. Are we mid-conversation with that context fresh (a long build session, this
   repo, prior discussion)?
3. Is the request open-ended — "scrape X", no scope given?

→ If **1 or 2**: skip the interview; the answers are already in context —
   read the relevant use-case doc and start.
→ If **3** and neither 1 nor 2: run the calibration, then the use-case doc.

Long-running or repeatable jobs also create the project's automation
workspace: `.web-automations/NOTES.md` (how the site works, decisions, resume
state + exact next command) and `.web-automations/progress/` (append-only
checkpoints + cursor). A fresh agent must be able to take over a run purely
from that directory.

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

The skill folder carries a pinned snapshot of upstream chrome-agent at the
**v0.5.7** release: `docs/guide.md`, `docs/collaboration-guide.md`, `docs/
cdp-collaboration-reference.md`, `docs/monitor-integration.md`, `docs/
event-driven-without-monitor.md`. Use it offline or to diff what changed; the
CLI's `guide` wins when they disagree.

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

## CAPTCHA widgets & closed shadow roots (Cloudflare Turnstile)

Verified first-hand in a local lab (official test sitekeys) against the real
widget internals. Modern Turnstile mounts its widget iframe inside a **closed
shadow root**: page JS is blind to it — `querySelectorAll('iframe')` returns 0
while the checkbox renders, `element.shadowRoot` is `null` (closed), and only
the form field (`input#cf-chl-widget-…_response`) sits in light DOM. So
CAPTCHA "find the iframe and click it" logic written in page JS silently
no-ops — wrong channel, not wrong selector. This is the canonical
rung-1-fails-silently→rung-2 case, and detection must leave page JS entirely.

The stack that works (implemented in `scripts/turnstile-detect.sh` — bash,
zero-dep CLI probe — and `scripts/turnstile.py` — stdlib Python twin with the
same interface, for embedding in Python codebases):

1. **Detect** — CDP `DOM.getDocument '{"depth":-1,"pierce":true}'` pierces
   closed shadow roots (page JS cannot). Find the `iframe` whose `src` matches
   `challenges.cloudflare.com` (id `cf-chl-widget`). Alternative surface:
   `DOM.getNodeForLocation '{"x":…,"y":…}'` returns the node under a coordinate.
2. **Measure** — `DOM.getBoxModel '{"backendNodeId":N}'` → viewport box; its
   center is the click target. Use `backendNodeId` (not `nodeId`) — it survives
   across one-shot calls, `nodeId` goes stale.
3. **Click** — synthetic `element.click()` cannot land (closed root +
   cross-origin iframe). Trusted `Input.dispatchMouseEvent` press+release at
   the center routes through the compositor into the shadow/iframe —
   viewport-relative, no iframe math. On the interactive test key this single
   click produced a passing token.
4. **Verify** — `turnstile.getResponse()` works from page JS even though the
   widget DOM is closed; empty = not passed, token = passed,
   `error-callback`/`timeout-callback` = blocked. Invisible widgets mount a
   hidden iframe: its box is degenerate (0-size / off-viewport) — don't click,
   wait on token/error instead.

Behavioral reality (verified with page-level pointer logging): events routed to
the widget iframe are **invisible to the parent page** — a page observes your
approach only until the pointer crosses into the frame (measured: 7 of 20
approach moves visible, the click itself never). Real risk engines also weigh
dwell, press duration, micro-jitter, and environmental signals (IP/UA/TLS
reputation); the heavy weights are environmental, so no input path rescues a
flagged fingerprint — and plain clicks pass clean traffic.

Testing: Cloudflare's official test sitekeys — `1x00000000000000000000AA`
always-pass, `2x00000000000000000000AB` always-fail, `1x…BB`/`2x…BB` invisible
pass/fail, `3x00000000000000000000FF` forces interactive challenge — work on
`localhost` and return dummy tokens (`XXXX.DUMMY.TOKEN.XXXX`). They
short-circuit the risk engine, so use them for mechanics (detect/click/verify),
never to conclude about real evaluation; behavioral A/B needs a real sitekey on
your own domain.

## Targeting tabs

An instance can hold several tabs; direct one-shots at the right one:

```bash
chrome-agent <inst> --target 2 Page.navigate '{"url":"..."}'   # 1-based index
chrome-agent <inst> --target 956FD3C2 Runtime.evaluate '{...}' # target-id prefix
chrome-agent <inst> --url example.com Runtime.evaluate '{...}' # url substring
```

Multiple tabs with no specifier is an error that lists them. **Index gotcha:**
`--target N` indices sort by stable target id, **not** tab creation/visual
order — opening a tab renumbers the others. Prefer `--url` or an id prefix.

## Working on SPAs & dynamic sites

Modern sites are single-page apps: the URL is a routing hint, `readyState` can
read "complete" while nothing changed, and the DOM is rebuilt constantly. Six
habits keep you honest on any of them.

**1. Validate the act — cheaply, never assume.** After any action — typing,
clicking, submitting — verify the expected effect actually happened: a network
request fired, a URL shifted, a list re-rendered. Pick the cheapest
trustworthy signal: a captured request beats a DOM read, a DOM read beats
pixels. A control that returns success is not proof; the field can show your
text while no request ever fires. Cheap validation is also a regression
tripwire — when the site changes behavior later, the check fails the moment it
drifts instead of silently collecting wrong results.

**2. The app's state is your alternative API.** Most apps encode actions
(search, filters, pagination, tabs) as URL parameters or navigable routes.
When an interaction doesn't validate, find the parameter, route, or in-app
control that produces the same effect — the same request the UI would make,
with fewer fragile pieces. Act → cheap-validate → on failure, slide to the
app's own equivalent action and validate again.

**3. Verify like a skeptic.** An action's return value proves nothing; confirm
through a different channel than the one you acted on. A screenshot is ground
truth for what's on screen — and a screenshot call that hangs is itself a
signal that the page is stuck, not a broken tool.

**4. Classify the failure before retrying.** Four look-alikes need four
different responses: the action didn't land (no-op), the thing genuinely
doesn't exist, the page render is broken (frozen), or it was a one-off blip.
When "nothing appears" repeats, probe a known-good control first — it
separates "the site stopped working" from "there's nothing there" before you
record anything.

**5. Wait for signals, not durations.** Speed doesn't come from shorter
sleeps — it comes from precise readiness detection. After an action, wait for
the specific thing that proves the effect: the row that should appear, the
request that should fire, the spinner that should vanish. Poll for that
condition with a timeout as a backstop, not a fixed sleep (except as a final
fallback). This self-tunes: a fast site is handled fast automatically, a slow
one just waits its actual latency. And it merges with validation: if the
expected signal never appears, that *is* the failure to classify — you never
end up hoping a sleep was long enough. Fixed delays then have exactly one job:
deliberate rate-limiting between actions — a site-consent posture set with the
operator, never a performance tool.

**6. Make every wait observable.** A wait isn't done when the timer elapses —
it ends with a *classified outcome*. Log each one (what was waited for,
seen/timeout, how long it took) so a run leaves a trace you can read after the
fact: which step stalled, where, and for how long. When "it should load in 5
seconds" doesn't, that's not a mystery — it's a line in the file. This turns a
failed automation from "re-run it to debug" into "read the trace and see which
step never produced its signal."

Timestamps earn their keep only when they let you *compute durations*: record
them with millisecond precision plus an epoch value so any two events can be
diffed, and time operations as start/end *span* events (a login, a submit, a
render wait). "This step took longer than usual" is then a number you can
aggregate, not a feeling.

## Common non-click patterns (often better than driving the UI)

- **Web UI as an ad-hoc API.** `Runtime.evaluate` running `fetch()` *inside* the
  logged-in page inherits its session — same-origin API calls, zero credential
  handling. Pass `awaitPromise:true` and `returnByValue:true` (without the
  former it returns before the data resolves).
- **API discovery.** `performance.getEntriesByType("resource")` recovers the
  backend endpoints the page already called — post-hoc, no live `Network`
  subscription. After 2–3 guessed endpoints 404, stop guessing and observe one
  real request via `attach +Network.responseReceived` (filename is in
  `content-disposition`).
- **React-controlled inputs** need the native setter so React sees the change:
  ```bash
  chrome-agent <inst> Runtime.evaluate '{"expression":"(()=>{const el=document.querySelector(\"#email\");const set=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,\"value\").set;set.call(el,\"a@b.com\");el.dispatchEvent(new Event(\"input\",{bubbles:true}));})()"}'
  ```
- **Typing (trusted):** `Input.insertText '{"text":"..."}'` or `Input.dispatchKeyEvent`.
- **Cookie handoff for bulk.** `Network.getCookies '{"urls":["https://host/"]}'`
  extracts the session into a `Cookie:` header so `curl` (or any client) can fan
  out a large transfer outside the CDP channel.
- **File upload without a dialog.** `DOM.setFileInputFiles` sets paths on a
  `<input type=file>` with no OS picker. Identify the input by
  **`backendNodeId`** — the node handle that survives across one-shot calls
  (`nodeId`/`objectId` go stale between calls).
- **Reach into shadow DOM / cross-origin iframes.** `DOM.getDocument
  '{"depth":-1,"pierce":true}'` traverses where a main-frame `querySelector`
  can't; `DOM.getNodeForLocation '{"x":…,"y":…,"includeUserAgentShadowDOM":true}'`
  returns the node under a coordinate. Trusted `Input` stays viewport-relative.
- **Exact-size PDF.** `Page.printToPDF` with explicit `paperWidth`/`paperHeight`
  (inches) + zero margins + `printBackground:true` (the `--print-to-pdf` flag
  ignores `@page` size and emits US Letter).
- **Screenshot decode:** `data` is base64 PNG at the top level (not `result.data`).
  Use `scripts/shot.sh <inst> <out.png>` in this skill folder.
- **Wait on readiness, not a fixed sleep:** poll `document.readyState === "complete"`
  via `Runtime.evaluate` in a short retry loop, or attach `+Page.loadEventFired`
  before acting.

## Reacting to events (this harness has no Monitor tool)

Claude Code's Monitor turns an `attach` stream into live notifications. Here
the equivalent is one backgrounded `attach` plus one blocking wait per event
you care about — `scripts/cdp-wait.py` (upstream's, v0.5.7):

```bash
# once per flow: stream subscribed events to a file
chrome-agent attach <inst> +Page.frameNavigated +Page.loadEventFired \
  +Runtime.exceptionThrown +Network.loadingFailed > /tmp/events.jsonl 2>&1 &
# per event: block until it lands (measured ~82 ms vs ~4.9 s for a sleep 5)
python3 scripts/cdp-wait.py --file /tmp/events.jsonl \
  --method Page.loadEventFired --timeout 20
```

Rules that keep this honest:
- **Subscription menu is `help`:** `chrome-agent help <inst> <Domain>` prints an
  explicit `Events:` block; `help <inst> <Domain>.event` shows the payload. The
  live protocol is truth, not a static list.
- **Always include failure events** (`+Runtime.exceptionThrown
  +Network.loadingFailed`). A happy-path-only stream stays silent through
  trouble, and silence looks identical to "nothing happened yet."
- `cdp-wait.py` catches events that fired *before* the wait started; bare
  `tail -f` silently drops those.
- **Never point a raw `ws://…/devtools/page/<id>` at CDP** — the socket connects
  and receives zero events (no `Domain.enable` handshake). Use `attach`.
- Never `head` a monitored pipeline; filter with `jq --unbuffered` /
  `grep --line-buffered` (jq buffers by default and stalls events).
- One-shots **can't intercept `Network`** (they detach immediately) — persistent
  sessions use `attach` or the Python API.

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

## Gotchas

- **Navigation kills context.** A pending `Runtime.evaluate` errors with
  "context destroyed" when the page navigates — retry on the new page.
- **One-shot latency** ~70 ms (process startup). Tight loops or event capture →
  `attach` / the Python driver.
- **Multiple live instances** disable name auto-selection for bare one-shots —
  they error and list the instances. `help` is exempt (schema is identical).
- **Event isolation.** Each `attach` session sees only its own subscriptions;
  add/remove mid-session via stdin (`+Event` / `-Event`).
- **Sandbox launches** (containers, bubblewrap) record sandbox-local PIDs and
  the browser dies with the sandbox — launch on the host, fresh port (never
  reuse another instance's `--remote-debugging-port`).

## Further reading & credits

- `chrome-agent guide` (pinned copy: `docs/guide.md` @ v0.5.7) — authoritative,
  version-tracked mechanics.
- `docs/collaboration-guide.md` + `docs/cdp-collaboration-reference.md` —
  multi-agent / human-agent collaboration and the "binding bridge" (observing
  a user's clicks/scroll/selection, which raw CDP doesn't expose).
- `docs/event-driven-without-monitor.md` — event-driven observation in depth,
  with the reproducible proof (`scripts/cdp-wait.py`, `scripts/cdp-wait-prove.sh`).
- `docs/monitor-integration.md` — Claude Code Monitor integration: dual-channel
  architecture, usage, troubleshooting.
- **Python API:** `from chrome_agent.cdp_client import CDPClient, get_ws_url` +
  the generated typed domains (`chrome_agent.domains.*`); `send(method=…,
  params=…)` reaches any method, bindings or not.
- Built on **Corey Gallon**'s `chrome-agent` (<https://github.com/captivus/chrome-agent>),
  his talk (<https://www.youtube.com/watch?v=26RtyAm9y_Q>), and blog
  (<https://gallon.me>). The rung-ladder and trusted-input method are his.
