#!/usr/bin/env bash
# replay-template.sh — skeleton for a "written-down" solved browser flow.
#
# Fill this in AFTER you've explored a flow by hand and know which rung and
# which coordinates/selectors work. A committed replay script runs the flow
# with no model in the loop — solve once, reuse forever.
#
# Usage: cp this into <your-repo>/scripts/<flow-name>.sh and edit.
set -euo pipefail

INST="${INST:-flow-01}"                 # instance name; override with INST=...
START_URL="${START_URL:-https://example.com}"

# --- helpers -----------------------------------------------------------------
ca() { chrome-agent "$INST" "$@"; }     # one-shot CDP command against the instance

eval_js() {                             # eval_js '<expr>' -> prints result.value
  ca Runtime.evaluate "$(python3 -c 'import json,sys; print(json.dumps({"expression": sys.argv[1], "returnByValue": True}))' "$1")" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result",{}).get("value",""))'
}

wait_ready() {                          # poll readyState instead of sleeping
  for _ in $(seq 1 40); do
    [ "$(eval_js 'document.readyState')" = "complete" ] && return 0
    sleep 0.25
  done
  echo "timeout waiting for page ready" >&2; return 1
}

center() {                              # center 'selector' -> "x y" viewport coords
  eval_js "(()=>{const r=document.querySelector('$1').getBoundingClientRect();return Math.round(r.x+r.width/2)+' '+Math.round(r.y+r.height/2);})()"
}

click_trusted() {                       # click_trusted <selector>  (rung 2)
  read -r x y < <(center "$1")
  ca Input.dispatchMouseEvent "{\"type\":\"mousePressed\",\"x\":$x,\"y\":$y,\"button\":\"left\",\"clickCount\":1}" >/dev/null
  ca Input.dispatchMouseEvent "{\"type\":\"mouseReleased\",\"x\":$x,\"y\":$y,\"button\":\"left\",\"clickCount\":1}" >/dev/null
}

# --- flow --------------------------------------------------------------------
# Launch (or reuse a running instance), then act. Comment out launch/stop if you
# want to attach to an already-running login session.
chrome-agent launch --port 9222 >/dev/null 2>&1 || true

ca Page.navigate "{\"url\":\"$START_URL\"}" >/dev/null
wait_ready

# TODO: your solved steps. Sense -> act -> sense-again. Example shape:
#   click_trusted '#open-compose'
#   eval_js "document.querySelector('#to').value='x@y.com'"     # rung 1 where it works
#   click_trusted '#send'
#   [ "$(eval_js 'document.querySelector(\".sent-toast\")?.textContent||\"\"')" ] || { echo 'send not confirmed' >&2; exit 1; }

echo "flow complete"

# chrome-agent stop "$INST"   # uncomment if this flow owns the instance lifecycle
