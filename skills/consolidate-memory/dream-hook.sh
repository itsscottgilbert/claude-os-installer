#!/usr/bin/env bash
#
# dream-hook.sh - Stop hook that checks dream conditions and triggers consolidation
#
# Add to settings.json:
#   "hooks": {
#     "Stop": [{
#       "type": "command",
#       "command": "bash ~/.claude/skills/consolidate-memory/dream-hook.sh"
#     }]
#   }
#
# Fires when a Claude Code session ends. Checks if 24hrs + 5 sessions
# have passed since last dream. If so, spawns claude in the background
# to run /dream. Zero overhead when conditions aren't met (~10ms check).

SKILL_DIR="$HOME/.claude/skills/consolidate-memory"

# Run the condition check
if bash "$SKILL_DIR/should-dream.sh" 2>/dev/null; then
    # Conditions met - spawn dream in background
    # Use claude -p to run the dream skill non-interactively
    nohup claude -p "Run the consolidate-memory skill. Read $SKILL_DIR/SKILL.md and execute all 4 phases for all projects." \
        --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
        > /tmp/consolidate-memory-$(date +%Y%m%d-%H%M%S).log 2>&1 &

    echo "Consolidate-memory started in background (PID: $!)"
fi

# Always exit 0 so we don't block the session from closing
exit 0
