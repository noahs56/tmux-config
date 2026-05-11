#!/usr/bin/env bash
# detect-state.sh — Detect Claude Code session state from a tmux pane
# Usage: detect-state.sh <session:window.pane>
# Output: STATE|label
#   READY        — agent answered, waiting for user input
#   RUNNING      — agent is thinking/working
#   PERMISSION   — agent needs human decision (allow/deny)
#   TYPING       — user is mid-typing a message
#   SHELL        — regular shell, not Claude Code
#   EMPTY        — pane is empty or unreadable

PANE="$1"
if [[ -z "$PANE" ]]; then
    echo "EMPTY|no pane"
    exit 0
fi

# Capture the full visible pane content
CONTENT=$(tmux capture-pane -t "$PANE" -p 2>/dev/null)
if [[ -z "$CONTENT" ]]; then
    echo "EMPTY|no content"
    exit 0
fi

# Check if this is a Claude Code session
# Look for distinctive Claude Code UI elements
if ! echo "$CONTENT" | grep -q 'bypass permissions\|Context .* Usage\|CLAUDE.md\|MCPs'; then
    echo "SHELL|shell"
    exit 0
fi

# Check for permission/decision prompts
if echo "$CONTENT" | grep -qiE 'Allow .*(yes|no|y/n)|approve.*deny|allow.*deny|Allow once|Allow always|press .* to confirm|Do you want to allow'; then
    echo "PERMISSION|needs decision"
    exit 0
fi

# Find the LAST occurrence of the ❯ prompt character
# The prompt sits above the status bar (which takes up ~4-5 lines at bottom)
LAST_PROMPT_LINE=$(echo "$CONTENT" | grep -n '❯' | tail -1)

if [[ -n "$LAST_PROMPT_LINE" ]]; then
    # Extract just the content of the last prompt line
    prompt_content=$(echo "$LAST_PROMPT_LINE" | sed 's/^[0-9]*://')

    # Check if prompt is empty (just ❯ with optional whitespace)
    if echo "$prompt_content" | grep -qE '^❯[[:space:]]*$'; then
        echo "READY|answered"
        exit 0
    fi

    # Prompt has text — user is typing
    if echo "$prompt_content" | grep -qE '^❯ .+'; then
        echo "TYPING|user typing"
        exit 0
    fi
fi

# Has Claude Code indicators but no visible ❯ prompt — agent is running
echo "RUNNING|working"
