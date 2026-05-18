# Claude OS Installer

A one-click installer for Scott Gilbert's Claude Code platform — Obsidian vault, semantic memory search, Claude Code CLI, and a personalized memory system that gets to know you in your first session.

## What you get

- **Obsidian** — your local knowledge vault
- **Claude Code** — Anthropic's CLI, working out of your vault
- **Memsearch** — semantic search across your notes and past sessions
- **Claude OS dashboard** — Jack Robert's [`claude-operating-system`](https://github.com/ItsssssJack/claude-operating-system) at `http://localhost:8081` (KPIs, memory graph, usage, automations, daily Dream prescriptions)
- **A pre-built vault template** with project scaffolding and universal operating rules
- **Skills** including `/onboard` (52-question interview that personalizes your memory) and `consolidate-memory` (auto-runs every 24h to merge session learnings into persistent memory)
- **A CLAUDE.md** at the vault root that tells Claude how to work with you

After install, your first `/onboard` session writes the foundation. Everything else builds from real work over time.

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- A free Claude account at [claude.ai](https://claude.ai)
- ~3 GB free disk space

## Install

### Option 1: Download and double-click

1. Go to [Releases](https://github.com/itsscottgilbert/claude-os-installer/releases/latest)
2. Download `claude-os-installer.zip`
3. Unzip
4. Double-click `INSTALL.command`

The first time you run it, macOS may block it. **Right-click → Open**, then click Open in the dialog. After that it works normally.

### Option 2: Terminal one-liner

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/itsscottgilbert/claude-os-installer/main/install.sh)"
```

This pulls the script and runs it. Same end result.

## What the installer does

1. Asks where to put your vault (default: `~/Claude Platform/`)
2. Installs Homebrew if missing
3. Installs Obsidian, Node.js, uv, Bun
4. Installs Claude Code (`@anthropic-ai/claude-code`)
5. Installs memsearch (`memsearch[onnx]`)
6. Copies vault templates into your new vault
7. Drops skills into `~/.claude/skills/`
8. Clones the Claude OS dashboard to `~/code/claude-os/` and runs its setup
9. Tells you what to do next

The whole thing takes 5-15 minutes depending on your internet speed.

## First run

After install:

```bash
cd "~/Claude Platform"      # or wherever you put it
claude                       # log in if it's your first time
```

Inside Claude Code:

```
/onboard
```

The onboard skill runs a conversational interview (about 30 minutes, can be paused) and writes your starter memory files. After that you have a platform that knows you.

### Launching the dashboard

In a separate Terminal tab:

```bash
cd ~/code/claude-os
bun run dev
```

Opens at `http://localhost:8081`.

## What's in the vault template

```
<your-vault>/
├── CLAUDE.md                  ← operating instructions Claude reads every session
├── _shared/
│   ├── _wiki/                 ← universal foundation (you, AI rules, writing style)
│   └── _wiki-project-stubs/   ← templates the onboard skill uses for each project
```

After `/onboard` runs, each project you mention gets its own folder with a 13-file `_wiki/` that captures mission, customer, voice, GTM, and project-specific rules.

## Updating

```bash
cd "~/Claude Platform"
curl -fsSL https://raw.githubusercontent.com/itsscottgilbert/claude-os-installer/main/install.sh | bash
```

Existing files won't be overwritten. New skills and template updates will land.

## Uninstall

```bash
rm -rf "~/Claude Platform"
rm -rf "~/.claude/skills/onboard"
rm -rf "~/.claude/projects/-Users-<you>-Claude-Platform"
uv tool uninstall memsearch
npm uninstall -g @anthropic-ai/claude-code
brew uninstall --cask obsidian
```

## License

MIT.
