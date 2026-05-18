# Claude OS Installer

A one-click installer for the Claude Code platform — Obsidian vault, semantic memory search, Claude Code CLI, [Jack Robert's claude-operating-system dashboard](https://github.com/ItsssssJack/claude-operating-system), and a `/onboard` skill that interviews you to personalize your memory system.

## What you get

- **Obsidian** — your local knowledge vault
- **Claude Code** — Anthropic's CLI, working out of your vault
- **Memsearch** — semantic search across your notes and past sessions
- **Claude OS dashboard** at `http://localhost:8081` — KPIs, memory graph, usage stats, automations, daily Dream prescriptions
- **Vault template** with universal `_wiki/` scaffolding and per-project stubs
- **Skills**:
  - `/onboard` — 52-question conversational interview that personalizes your memory
  - `consolidate-memory` — auto-runs every 24h to merge session learnings
  - `recall-all` — searches memsearch + built-in memory in one pass
- **CLAUDE.md** at the vault root that tells Claude how to work with you

After install, your first `/onboard` session writes the foundation. Everything else builds from real work over time.

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- A free Claude account at [claude.ai](https://claude.ai)
- ~3 GB free disk space

## Install

### Option 1: Terminal one-liner (recommended)

Paste this into Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/itsscottgilbert/claude-os-installer/master/install.sh)"
```

The script auto-clones the rest of the installer files and runs end-to-end. No download step needed.

### Option 2: Download and double-click

1. Download `claude-os-installer.zip` from the [latest release](https://github.com/itsscottgilbert/claude-os-installer/releases/latest)
2. Unzip it
3. Double-click `INSTALL.command`

**If macOS blocks `INSTALL.command`** (it will the first time, because the file isn't code-signed):

- Right-click `INSTALL.command` → **Open** → click **Open** in the dialog
- OR open Terminal and run: `xattr -d com.apple.quarantine /path/to/INSTALL.command`

After the first launch, macOS remembers it.

## What the installer does

1. Asks where to put your vault (default: `~/Claude Platform/`)
2. Installs Homebrew if missing
3. Installs Obsidian, Node.js, uv, Bun
4. Installs Claude Code (`@anthropic-ai/claude-code`)
5. Installs memsearch (`memsearch[onnx]`)
6. Updates your shell profile so all tools work in future Terminal sessions
7. Copies vault templates and substitutes machine-specific values
8. Drops skills into `~/.claude/skills/`
9. Clones the Claude OS dashboard to `~/code/claude-os/` and (optionally) runs its setup
10. Runs a smoke test and tells you what to do next

The whole thing takes 5-15 minutes depending on your internet speed. It's idempotent — re-run anytime to update or recover from a partial install.

## First run

After install, **open a new Terminal window** (so the updated PATH takes effect), then:

```bash
cd "~/Claude Platform"      # or wherever you put it
claude                       # log in if it's your first time
```

Inside Claude Code:

```
/onboard
```

The onboard skill runs a conversational interview (about 30 minutes, can be paused and resumed) and writes your starter memory files. After that you have a platform that knows you.

### Launching the dashboard

In a separate Terminal tab:

```bash
cd ~/code/claude-os
bun run dev
```

Opens at `http://localhost:8081`.

## Troubleshooting

**"command not found: claude" after install**
Open a new Terminal window. The installer updates `~/.zprofile`, but existing tabs don't pick that up automatically.

**INSTALL.command bounces back with a Gatekeeper warning**
See the "If macOS blocks INSTALL.command" section above. The terminal one-liner avoids this entirely.

**`bun run setup` failed or asked for keys I don't have**
Skip it. Press `n` when asked, or hit Ctrl+C. The dashboard still works without the optional integrations — you just get less data in some panels. Re-run later with `cd ~/code/claude-os && bun run setup`.

**Homebrew install asked for my password**
That's normal. It installs to `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel), which need admin permission.

**Re-run after a failed step**
Just re-run the installer. Every step checks "is this already done?" before acting.

**I want to reinstall from scratch**
See "Uninstall" below, then re-run.

## What's in the vault template

```
<your-vault>/
├── CLAUDE.md                    ← operating instructions Claude reads every session
└── _shared/
    ├── _wiki/                   ← universal foundation (you, AI rules, writing style)
    └── _wiki-project-stubs/     ← templates /onboard uses for each project
```

After `/onboard` runs, each project you mention gets its own folder with a 13-file `_wiki/` capturing mission, customer, voice, GTM, and project-specific rules.

## Updating

Re-run the installer. It pulls latest from GitHub and refreshes anything safe to refresh, skipping anything that would clobber your work:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/itsscottgilbert/claude-os-installer/master/install.sh)"
```

## Uninstall

```bash
rm -rf "~/Claude Platform"
rm -rf ~/.claude/skills/onboard
rm -rf ~/.claude/skills/consolidate-memory
rm -rf ~/.claude/skills/recall-all
rm -rf ~/.claude/projects/-Users-<you>-Claude-Platform
rm -rf ~/code/claude-os
uv tool uninstall memsearch
npm uninstall -g @anthropic-ai/claude-code
brew uninstall --cask obsidian
```

PATH lines in `~/.zprofile` won't break anything if you don't remove them, but you can clean them up by searching for "Added by claude-os-installer".

## Credits

- Dashboard: [Jack Robert / @ItsssssJack — claude-operating-system](https://github.com/ItsssssJack/claude-operating-system)
- Memsearch: [memsearch on PyPI](https://pypi.org/project/memsearch/)
- Claude Code: [Anthropic](https://github.com/anthropics/claude-code)

## License

MIT. See [LICENSE](LICENSE).
