#!/usr/bin/env bash
# shot.sh — capture a screenshot from a chrome-agent instance and decode to PNG.
# Usage: shot.sh <instance> [out.png]
# The CDP result puts base64 bytes at top-level `data` (not result.data).
set -euo pipefail

inst="${1:?usage: shot.sh <instance> [out.png]}"
out="${2:-shot.png}"

chrome-agent "$inst" Page.captureScreenshot '{"format":"png"}' \
  | python3 -c "import sys,json,base64; d=json.load(sys.stdin); open('$out','wb').write(base64.b64decode(d['data']))"

echo "saved $out"
