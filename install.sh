#!/usr/bin/env bash
# Claude OS Installer v0.2.0
# Sets up Obsidian + memsearch + Claude Code + vault templates + skills + dashboard.
#
# Run via:
#   - Double-click INSTALL.command (after unzipping the release)
#   - ./install.sh (from a clone)
#   - /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/itsscottgilbert/claude-os-installer/master/install.sh)"
#     (auto-clones the repo and re-execs)

set -euo pipefail

INSTALLER_VERSION="0.2.0"
INSTALLER_REPO="https://github.com/itsscottgilbert/claude-os-installer.git"

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
printf "\n${BOLD}Claude OS Installer${NC} v${INSTALLER_VERSION}\n\n"

if [[ "$OSTYPE" != "darwin"* ]]; then
  fail "This installer is for macOS. Detected: $OSTYPE"
fi

# ── 2. Bootstrap — auto-clone if running standalone ────────────────────────
# When invoked via curl-bash, vault-template/ and skills/ don't exist next to
# install.sh. Detect that and clone the full repo to a temp dir, then re-exec.
if [[ ! -d "$SCRIPT_DIR/vault-template" ]] || [[ ! -d "$SCRIPT_DIR/skills" ]]; then
  info "Bootstrap: fetching installer files"
  if ! command -v git &>/dev/null; then
    step "git not found — install Xcode Command Line Tools first"
    xcode-select --install 2>/dev/null || true
    fail "git is required. Run 'xcode-select --install', accept the prompt, then re-run this installer."
  fi
  CLONE_DIR=$(mktemp -d -t claude-os-installer-XXXXXX)
  step "Cloning $INSTALLER_REPO → $CLONE_DIR"
  git clone --depth 1 --quiet "$INSTALLER_REPO" "$CLONE_DIR"
  ok "Bootstrap complete"
  printf "\n"
  exec bash "$CLONE_DIR/install.sh" "$@"
fi

# ── 3. Ask for vault location ──────────────────────────────────────────────
DEFAULT_VAULT="$HOME/Claude Platform"
printf "Where should I install your Claude OS vault?\n"
printf "Default: ${BOLD}%s${NC}\n" "$DEFAULT_VAULT"
read -r -p "Vault path [press Enter for default]: " VAULT_INPUT
VAULT_PATH="${VAULT_INPUT:-$DEFAULT_VAULT}"
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

if [[ -e "$VAULT_PATH" ]]; then
  warn "$VAULT_PATH already exists."
  read -r -p "Continue and merge with existing folder? [y/N]: " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || fail "Aborted."
fi

mkdir -p "$VAULT_PATH"
ok "Vault location: $VAULT_PATH"

# ── 4. Install Homebrew ────────────────────────────────────────────────────
info "Checking Homebrew"
BREW_PREFIX=""
if ! command -v brew &>/dev/null; then
  step "Installing Homebrew (will prompt for your Mac password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    BREW_PREFIX="/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    BREW_PREFIX="/usr/local"
  fi
else
  ok "Homebrew already installed"
  BREW_PREFIX=$(brew --prefix)
fi

# ── 5. Install Obsidian, Node, uv, Bun ─────────────────────────────────────
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

# ── 6. Install Claude Code ─────────────────────────────────────────────────
info "Installing Claude Code"
if ! command -v claude &>/dev/null; then
  step "claude (Anthropic CLI)"
  npm install -g @anthropic-ai/claude-code
else
  ok "Claude Code already installed"
fi

# ── 7. Install memsearch ───────────────────────────────────────────────────
info "Installing memsearch (semantic memory)"
if ! command -v memsearch &>/dev/null; then
  step "memsearch with ONNX embeddings"
  uv tool install "memsearch[onnx]"
  export PATH="$HOME/.local/bin:$PATH"
else
  ok "memsearch already installed"
fi

# ── 8. Persist PATH changes to shell profile ───────────────────────────────
info "Updating shell profile for future Terminal sessions"

USER_SHELL=$(basename "${SHELL:-/bin/zsh}")
case "$USER_SHELL" in
  zsh)  SHELL_PROFILE="$HOME/.zprofile" ;;
  bash) SHELL_PROFILE="$HOME/.bash_profile" ;;
  *)    SHELL_PROFILE="$HOME/.profile" ;;
esac
touch "$SHELL_PROFILE"

add_to_profile() {
  local line="$1"
  local marker="$2"
  if ! grep -qF "$marker" "$SHELL_PROFILE" 2>/dev/null; then
    printf '\n# Added by claude-os-installer\n%s\n' "$line" >> "$SHELL_PROFILE"
    step "Added to $SHELL_PROFILE: $marker"
  else
    ok "Already in $SHELL_PROFILE: $marker"
  fi
}

if [[ -n "$BREW_PREFIX" ]]; then
  add_to_profile "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" "brew shellenv"
fi
add_to_profile 'export PATH="$HOME/.local/bin:$PATH"' 'HOME/.local/bin'

# ── 9. Compute install-time placeholder values ─────────────────────────────
info "Configuring your vault"

HOSTNAME=$(hostname -s)
MACHINE_SPECS=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Mac")
COLLECTION_HASH=$(printf '%s' "$VAULT_PATH" | shasum -a 256 | cut -c1-8)
MEMSEARCH_COLLECTION="ms_${COLLECTION_HASH}"
ENCODED_PATH=$(printf '%s' "$VAULT_PATH" | sed 's|/|-|g')
MEMORY_PATH="$HOME/.claude/projects/${ENCODED_PATH}/memory"

step "Machine: $HOSTNAME ($MACHINE_SPECS)"
step "Memsearch collection: $MEMSEARCH_COLLECTION"
step "Memory path: $MEMORY_PATH"

# ── 10. Copy vault templates ───────────────────────────────────────────────
info "Installing vault templates"

mkdir -p "$VAULT_PATH/_shared/_wiki"
for f in "$SCRIPT_DIR/vault-template/_wiki-template/"0[1-3]-*.template; do
  base=$(basename "$f" .template)
  cp "$f" "$VAULT_PATH/_shared/_wiki/$base"
done
step "Shared _wiki/ templates → _shared/_wiki/"

cp "$SCRIPT_DIR/vault-template/CLAUDE.md.template" "$VAULT_PATH/CLAUDE.md"
step "CLAUDE.md → vault root"

mkdir -p "$VAULT_PATH/_shared/_wiki-project-stubs"
cp "$SCRIPT_DIR/vault-template/_wiki-template/project-stubs/"*.template "$VAULT_PATH/_shared/_wiki-project-stubs/"
step "Project stub templates → _shared/_wiki-project-stubs/"

# ── 11. Substitute install-time placeholders ───────────────────────────────
substitute_in_file() {
  local file="$1"
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

# ── 12. Create memory directory ────────────────────────────────────────────
info "Creating Claude Code memory directory"
mkdir -p "$MEMORY_PATH"
if [[ ! -f "$MEMORY_PATH/MEMORY.md" ]]; then
  : > "$MEMORY_PATH/MEMORY.md"
  ok "MEMORY.md created (empty — will be populated by /onboard)"
else
  ok "MEMORY.md already exists, leaving as-is"
fi

# ── 13. Install Claude Code skills ─────────────────────────────────────────
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

# ── 14. Install Claude OS dashboard ────────────────────────────────────────
info "Installing Claude OS dashboard (Jack Robert's claude-operating-system)"
DASHBOARD_DIR="$HOME/code/claude-os"

if [[ -d "$DASHBOARD_DIR/.git" ]]; then
  ok "Dashboard already cloned at $DASHBOARD_DIR"
  step "Pulling latest"
  git -C "$DASHBOARD_DIR" pull --ff-only || warn "Could not fast-forward; leaving local copy as-is"
else
  mkdir -p "$HOME/code"
  step "Cloning ItsssssJack/claude-operating-system → $DASHBOARD_DIR"
  git clone --quiet https://github.com/ItsssssJack/claude-operating-system.git "$DASHBOARD_DIR"
fi

step "bun install (can take a minute)"
(cd "$DASHBOARD_DIR" && bun install --silent)

printf "\n"
printf "The dashboard's setup script scans your machine and installs a daily 'dream' cron.\n"
printf "It may prompt for optional API keys (Pinecone, OpenRouter). You can skip those.\n"
read -r -p "Run dashboard setup now? [Y/n]: " RUN_SETUP
if [[ ! "$RUN_SETUP" =~ ^[Nn] ]]; then
  step "Running bun run setup"
  (cd "$DASHBOARD_DIR" && bun run setup) || warn "Dashboard setup hit an issue — you can re-run 'bun run setup' inside $DASHBOARD_DIR later"
else
  step "Skipped. Run 'cd $DASHBOARD_DIR && bun run setup' later when you're ready."
fi

# ── 15. Smoke test ─────────────────────────────────────────────────────────
info "Verifying install"
SMOKE_OK=true

check_cmd() {
  local cmd="$1" label="$2"
  if command -v "$cmd" &>/dev/null; then
    local v
    v=$("$cmd" --version 2>&1 | head -1 || echo "")
    ok "$label: $v"
  else
    warn "$label not on PATH"
    SMOKE_OK=false
  fi
}

check_cmd node "Node"
check_cmd bun  "Bun"
check_cmd uv   "uv"
check_cmd claude "Claude Code"
check_cmd memsearch "memsearch"
if [[ -d "/Applications/Obsidian.app" ]]; then
  ok "Obsidian: installed in /Applications/Obsidian.app"
else
  warn "Obsidian app not found in /Applications/"
  SMOKE_OK=false
fi
if [[ -f "$VAULT_PATH/CLAUDE.md" ]]; then
  ok "Vault: CLAUDE.md present"
else
  warn "Vault CLAUDE.md missing"
  SMOKE_OK=false
fi
if [[ -d "$HOME/.claude/skills/onboard" ]]; then
  ok "/onboard skill installed"
else
  warn "/onboard skill missing"
  SMOKE_OK=false
fi

# ── 16. Final instructions ─────────────────────────────────────────────────
printf "\n"
if $SMOKE_OK; then
  printf "${GREEN}${BOLD}✓ Install complete — all checks passed.${NC}\n\n"
else
  printf "${YELLOW}${BOLD}! Install finished, but some checks failed (see above).${NC}\n"
  printf "  This installer is idempotent — re-run it to retry.\n\n"
fi

printf "${BOLD}Next steps:${NC}\n\n"
printf "  1. If you don't have a Claude account yet, sign up at:\n"
printf "     ${BLUE}https://claude.ai${NC}\n\n"
printf "  2. ${BOLD}Open a new Terminal window${NC} (so PATH updates take effect) and run:\n"
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
