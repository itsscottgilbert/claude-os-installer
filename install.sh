#!/usr/bin/env bash
# Claude OS Installer
# Sets up Obsidian + memsearch + Claude Code + vault templates + skills.
# Run via INSTALL.command (double-click) or directly: ./install.sh

set -euo pipefail

# ── Colors and helpers ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${GREEN}==>${NC} ${BOLD}%s${NC}\n" "$1"; }
step()  { printf "    ${BLUE}→${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}!${NC}  %s\n" "$1"; }
fail()  { printf "${RED}✗${NC}  %s\n" "$1" >&2; exit 1; }
ok()    { printf "${GREEN}✓${NC}  %s\n" "$1"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ── 1. Sanity checks ───────────────────────────────────────────────────────
printf "\n${BOLD}Claude OS Installer${NC}\n\n"

if [[ "$OSTYPE" != "darwin"* ]]; then
  fail "This installer is for macOS. Detected: $OSTYPE"
fi

if [[ ! -d "$SCRIPT_DIR/vault-template" ]] || [[ ! -d "$SCRIPT_DIR/skills" ]]; then
  fail "Installer files missing. Expected vault-template/ and skills/ next to install.sh."
fi

# ── 2. Ask for vault location ──────────────────────────────────────────────
DEFAULT_VAULT="$HOME/Claude Platform"
printf "Where should I install your Claude OS vault?\n"
printf "Default: ${BOLD}%s${NC}\n" "$DEFAULT_VAULT"
read -r -p "Vault path [press Enter for default]: " VAULT_INPUT
VAULT_PATH="${VAULT_INPUT:-$DEFAULT_VAULT}"
# Expand ~ if present
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

if [[ -e "$VAULT_PATH" ]]; then
  warn "$VAULT_PATH already exists."
  read -r -p "Continue and merge with existing folder? [y/N]: " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || fail "Aborted."
fi

mkdir -p "$VAULT_PATH"
ok "Vault location: $VAULT_PATH"

# ── 3. Install Homebrew ────────────────────────────────────────────────────
info "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  step "Installing Homebrew (will prompt for your Mac password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this session (handles both Apple Silicon and Intel)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  ok "Homebrew already installed"
fi

# ── 4. Install Obsidian, Node, uv, Bun ─────────────────────────────────────
info "Installing apps and tools"

if ! brew list --cask obsidian &>/dev/null; then
  step "Obsidian"
  brew install --cask obsidian
else
  ok "Obsidian already installed"
fi

if ! command -v node &>/dev/null; then
  step "Node.js"
  brew install node
else
  ok "Node $(node --version) already installed"
fi

if ! command -v uv &>/dev/null; then
  step "uv (Python tool manager)"
  brew install uv
else
  ok "uv already installed"
fi

if ! command -v bun &>/dev/null; then
  step "Bun (for the Claude OS dashboard)"
  brew install oven-sh/bun/bun
else
  ok "Bun $(bun --version) already installed"
fi

# ── 5. Install Claude Code ─────────────────────────────────────────────────
info "Installing Claude Code"
if ! command -v claude &>/dev/null; then
  step "claude (Anthropic CLI)"
  npm install -g @anthropic-ai/claude-code
else
  ok "Claude Code already installed"
fi

# ── 6. Install memsearch ───────────────────────────────────────────────────
info "Installing memsearch (semantic memory)"
if ! command -v memsearch &>/dev/null; then
  step "memsearch with ONNX embeddings"
  uv tool install "memsearch[onnx]"
  # Ensure ~/.local/bin is on PATH for next steps in this session
  export PATH="$HOME/.local/bin:$PATH"
else
  ok "memsearch already installed"
fi

# ── 7. Compute install-time placeholder values ─────────────────────────────
info "Configuring your vault"

HOSTNAME=$(hostname -s)
MACHINE_SPECS=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Mac")
# Collection ID: prefix + 8-char hash of vault path (deterministic)
COLLECTION_HASH=$(printf '%s' "$VAULT_PATH" | shasum -a 256 | cut -c1-8)
MEMSEARCH_COLLECTION="ms_${COLLECTION_HASH}"
# Encoded path for ~/.claude/projects/...
ENCODED_PATH=$(printf '%s' "$VAULT_PATH" | sed 's|/|-|g')
MEMORY_PATH="$HOME/.claude/projects/${ENCODED_PATH}/memory"

step "Machine: $HOSTNAME ($MACHINE_SPECS)"
step "Memsearch collection: $MEMSEARCH_COLLECTION"
step "Memory path: $MEMORY_PATH"

# ── 8. Copy vault templates ────────────────────────────────────────────────
info "Installing vault templates"

# Universal shared _wiki/ files (01-03)
mkdir -p "$VAULT_PATH/_shared/_wiki"
for f in "$SCRIPT_DIR/vault-template/_wiki-template/"0[1-3]-*.template; do
  base=$(basename "$f" .template)
  cp "$f" "$VAULT_PATH/_shared/_wiki/$base"
done
step "Shared _wiki/ templates → _shared/_wiki/"

# CLAUDE.md at vault root
cp "$SCRIPT_DIR/vault-template/CLAUDE.md.template" "$VAULT_PATH/CLAUDE.md"
step "CLAUDE.md → vault root"

# Project stub templates stay in _shared/ for the onboard skill to use
mkdir -p "$VAULT_PATH/_shared/_wiki-project-stubs"
cp "$SCRIPT_DIR/vault-template/_wiki-template/project-stubs/"*.template "$VAULT_PATH/_shared/_wiki-project-stubs/"
step "Project stub templates → _shared/_wiki-project-stubs/"

# ── 9. Substitute install-time placeholders ────────────────────────────────
# User-specific placeholders (name, voice, projects) are filled by the /onboard skill.
# Here we fill only what's known at install time.

substitute_in_file() {
  local file="$1"
  # macOS sed needs '' after -i; uses BRE
  sed -i '' \
    -e "s|{{vault_path}}|${VAULT_PATH}|g" \
    -e "s|{{machine_name}}|${HOSTNAME}|g" \
    -e "s|{{machine_specs}}|${MACHINE_SPECS}|g" \
    -e "s|{{memsearch_collection}}|${MEMSEARCH_COLLECTION}|g" \
    -e "s|{{memory_path}}|${MEMORY_PATH}|g" \
    "$file"
}

substitute_in_file "$VAULT_PATH/CLAUDE.md"
for f in "$VAULT_PATH/_shared/_wiki/"*.md; do
  substitute_in_file "$f"
done

ok "Install-time placeholders filled"

# ── 10. Create memory directory ────────────────────────────────────────────
info "Creating Claude Code memory directory"
mkdir -p "$MEMORY_PATH"
if [[ ! -f "$MEMORY_PATH/MEMORY.md" ]]; then
  cat > "$MEMORY_PATH/MEMORY.md" <<'EOF'
EOF
  ok "MEMORY.md created (empty — will be populated by /onboard)"
else
  ok "MEMORY.md already exists, leaving as-is"
fi

# ── 11. Install Claude Code skills ─────────────────────────────────────────
info "Installing Claude Code skills"
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  if [[ ! -d "$HOME/.claude/skills/$skill_name" ]]; then
    cp -r "$skill_dir" "$HOME/.claude/skills/"
    step "Installed: $skill_name"
  else
    warn "Skill already exists, skipping: $skill_name"
  fi
done

# ── 12. Install Claude OS dashboard ────────────────────────────────────────
info "Installing Claude OS dashboard (Jack Robert's claude-operating-system)"
DASHBOARD_DIR="$HOME/code/claude-os"

if [[ -d "$DASHBOARD_DIR/.git" ]]; then
  ok "Dashboard already cloned at $DASHBOARD_DIR"
  step "Pulling latest"
  git -C "$DASHBOARD_DIR" pull --ff-only || warn "Could not fast-forward; leaving local copy as-is"
else
  mkdir -p "$HOME/code"
  step "Cloning ItsssssJack/claude-operating-system → $DASHBOARD_DIR"
  git clone https://github.com/ItsssssJack/claude-operating-system.git "$DASHBOARD_DIR"
fi

step "bun install (this can take a minute)"
(cd "$DASHBOARD_DIR" && bun install)

step "bun run setup (scans your machine, installs dream skill + cron)"
(cd "$DASHBOARD_DIR" && bun run setup) || warn "Dashboard setup hit an issue — you can re-run 'bun run setup' inside $DASHBOARD_DIR later"

# ── 13. Final instructions ─────────────────────────────────────────────────
printf "\n"
printf "${GREEN}${BOLD}✓ Install complete.${NC}\n\n"

printf "${BOLD}Next steps:${NC}\n\n"
printf "  1. If you don't have a Claude account yet, sign up at:\n"
printf "     ${BLUE}https://claude.ai${NC}\n\n"
printf "  2. Open a new Terminal window and run:\n"
printf "       ${BOLD}cd \"$VAULT_PATH\"${NC}\n"
printf "       ${BOLD}claude${NC}\n\n"
printf "     (First run will ask you to log in to your Claude account.)\n\n"
printf "  3. Inside Claude Code, type:\n"
printf "       ${BOLD}/onboard${NC}\n\n"
printf "     That will run the interview and personalize your memory system.\n\n"
printf "  4. To launch the Claude OS dashboard in a separate Terminal tab:\n"
printf "       ${BOLD}cd $DASHBOARD_DIR && bun run dev${NC}\n\n"
printf "     Then open ${BLUE}http://localhost:8081${NC} in your browser.\n\n"
printf "${BOLD}Vault:${NC}     $VAULT_PATH\n"
printf "${BOLD}Memory:${NC}    $MEMORY_PATH\n"
printf "${BOLD}Dashboard:${NC} $DASHBOARD_DIR\n\n"
