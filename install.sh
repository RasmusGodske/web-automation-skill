#!/usr/bin/env bash
# install.sh — make the web-automation skill available to the agent harnesses
# on this machine. Ensures the chrome-agent CLI is installed, then symlinks the
# skill (and an AGENTS.md pointer) into the locations common harnesses read.
#
# Usage:
#   ./install.sh [--project DIR] [--no-tool] [--force]
#   ./install.sh --help
#
# Idempotent: re-running relinks. Symlinks (not copies) so `git pull` updates
# every harness at once.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO/skills/web-automation"
PROJECT=""
INSTALL_TOOL=1
FORCE=0

usage(){ sed -n '2,12p' "$0"; exit 0; }
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="${2:?--project needs a dir}"; shift 2;;
    --no-tool) INSTALL_TOOL=0; shift;;
    --force)   FORCE=1; shift;;
    -h|--help) usage;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

link(){ # link <target> <linkname>
  local tgt="$1" ln="$2"
  mkdir -p "$(dirname "$ln")"
  if [ -e "$ln" ] || [ -L "$ln" ]; then
    if [ "$FORCE" = 1 ]; then rm -rf "$ln"; else
      echo "  skip (exists): $ln  — use --force to replace"; return; fi
  fi
  ln -s "$tgt" "$ln"; echo "  linked: $ln -> $tgt"
}

echo "web-automation-skill installer"
echo "repo: $REPO"

# 1) capability: chrome-agent CLI
if [ "$INSTALL_TOOL" = 1 ]; then
  if command -v chrome-agent >/dev/null 2>&1; then
    echo "chrome-agent: present ($(chrome-agent --version 2>/dev/null || echo '?'))"
  else
    echo "chrome-agent: installing..."
    if command -v uv >/dev/null 2>&1; then uv tool install chrome-agent
    elif command -v pipx >/dev/null 2>&1; then pipx install chrome-agent
    else pip install --user chrome-agent; fi
  fi
fi

# 2) skill into harness locations
echo "wiring skill into detected harnesses:"

# Claude Code — personal skills dir (all projects)
link "$SKILL_SRC" "$HOME/.claude/skills/web-automation"

# A specific project, if requested: Claude Code skill + AGENTS.md pointer
if [ -n "$PROJECT" ]; then
  PROJECT="$(cd "$PROJECT" && pwd)"
  link "$SKILL_SRC" "$PROJECT/.claude/skills/web-automation"
  # AGENTS.md pointer for AGENTS.md-aware harnesses (Codex, Cursor, Zed, ...)
  if [ ! -e "$PROJECT/AGENTS.md" ] || [ "$FORCE" = 1 ]; then
    link "$REPO/AGENTS.md" "$PROJECT/AGENTS.md"
  else
    echo "  note: $PROJECT/AGENTS.md exists — append this line yourself:"
    echo "        See \`web-automation\`: $SKILL_SRC/SKILL.md"
  fi
fi

cat <<EOF

Done.
- Claude Code: the skill auto-loads from ~/.claude/skills/web-automation.
  (Or install as a plugin: /plugin marketplace add RasmusGodske/web-automation-skill)
- Other harnesses: point them at $SKILL_SRC/SKILL.md, or run with --project DIR
  to drop an AGENTS.md pointer into a repo.
- Verify the tool: chrome-agent --version && chrome-agent guide
EOF
