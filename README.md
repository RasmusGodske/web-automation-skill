# web-automation-skill

A portable agent skill for driving a **real Chrome browser from the command
line** to automate web tasks on your own accounts and sites — fill forms, click
through UIs, send mail from a web client, scrape a logged-in page, use a web app
as an ad-hoc API.

It wraps [`chrome-agent`](https://pypi.org/project/chrome-agent/), a thin CLI
over the Chrome DevTools Protocol (CDP). The skill itself is just a methodology
document plus two helper scripts — the actual browser capability lives in the
`chrome-agent` package, which is harness-agnostic and self-documents via
`chrome-agent guide`.

## Two layers

| Layer | What | How it's distributed |
| --- | --- | --- |
| **Capability** | `chrome-agent` CLI (drives Chrome over CDP) | PyPI: `uv tool install chrome-agent` |
| **Skill** | `SKILL.md` + `scripts/` (methodology + helpers) | this repo (below) |

The skill is deliberately thin: it carries the *method* (a sense→act loop and a
rung 1→2 escalation ladder for stubborn UIs) and a *reuse workflow* (explore by
hand, then write the solved flow down as a committed script). Mechanics are
delegated to `chrome-agent guide` so there is little to keep in sync.

## Scope

Use this on accounts and sites **you own or are authorized to automate** — your
own workflows. It is not for defeating CAPTCHAs / bot-detection, evading access
controls, or automating third-party services against their terms. See the Scope
section at the top of [`SKILL.md`](skills/web-automation/SKILL.md).

## Install

### Prerequisite (all harnesses)

```bash
uv tool install chrome-agent        # or: pip install chrome-agent
chrome-agent --version              # needs a system Chrome/Chromium
```

### Claude Code — as a plugin (recommended)

```
/plugin marketplace add RasmusGodske/web-automation-skill
/plugin install web-automation@web-automation-skill
```

The skill then auto-loads in every project when a task involves driving a
browser.

### Claude Code — clone + symlink (no marketplace)

```bash
git clone git@github.com:RasmusGodske/web-automation-skill.git
ln -s "$PWD/web-automation-skill/skills/web-automation" ~/.claude/skills/web-automation   # personal, all projects
# or into a project: ln -s ... <project>/.claude/skills/web-automation
```

### Other agent harnesses

The skill is plain Markdown + shell, and the capability is a normal CLI, so any
shell-capable agent can use it. Point your harness at the methodology doc:

- Harnesses that read **`AGENTS.md`** (Codex, Cursor, Zed, and others): this
  repo ships an [`AGENTS.md`](AGENTS.md) that references the skill body. Include
  or symlink it where your harness expects.
- Anything else: run [`install.sh`](install.sh), which ensures `chrome-agent`
  is installed and symlinks the skill/doc into the locations it detects.

```bash
./install.sh            # detects harnesses and wires things up
./install.sh --help     # see what it will touch
```

## Layout

```
skills/web-automation/SKILL.md     canonical methodology (single source of truth)
skills/web-automation/scripts/     shot.sh (screenshot helper), replay-template.sh
AGENTS.md                          harness-neutral pointer to the skill body
.claude-plugin/                    Claude Code plugin + marketplace manifests
install.sh                         cross-harness installer
```

## Credits

This skill stands entirely on the work of **Corey Gallon** ([@captivus](https://github.com/captivus)):

- **`chrome-agent`** — the CLI this skill wraps: <https://github.com/captivus/chrome-agent>
- His talk on CDP-based agent browser automation (the "meatbag ladder", the
  sense→act loop, the trusted-input insight): <https://www.youtube.com/watch?v=26RtyAm9y_Q>
- His blog: <https://gallon.me>

The rung-ladder framing and the trusted-vs-synthetic-input mechanic are his;
this repo only packages the methodology as a portable, installable skill. For
multi-agent / human-agent collaboration and the "binding bridge" technique, see
`docs/collaboration-guide.md` in the chrome-agent repo.

## License

MIT

