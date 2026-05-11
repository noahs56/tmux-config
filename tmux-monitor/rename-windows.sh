#!/usr/bin/env bash
# rename-windows.sh — Update tmux session names with Claude Code status indicators
# Run this periodically (e.g., every 3 seconds) to keep names in sync
#
# Status indicators (prepended to session name):
#   (ready)    — agent answered, waiting for user input
#   (running)  — agent is actively working
#   (decide!)  — agent needs human decision
#   (typing)   — user is composing a message
#   (shell)    — not a Claude Code session
#
# Usage:
#   ./rename-windows.sh          # one-shot update
#   ./rename-windows.sh --loop   # continuous loop (every 3s)
#   ./rename-windows.sh --loop 5 # continuous loop (every 5s)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOOP=false
INTERVAL=3

if [[ "$1" == "--loop" ]]; then
    LOOP=true
    [[ -n "$2" ]] && INTERVAL="$2"
fi

get_status_prefix() {
    local state="$1"
    case "$state" in
        READY)      echo "" ;;
        RUNNING)    echo "" ;;
        PERMISSION) echo "" ;;
        TYPING)     echo "" ;;
        SHELL)      echo "" ;;
        EMPTY)      echo "" ;;
        *)          echo "" ;;
    esac
}

strip_prefix() {
    # Remove any existing status prefix from a session name
    echo "$1" | sed -E 's/^((🟢|🔵|🔴|🟡|\(ready\)|\(running\)|\(decide!\)|\(typing\)|\(shell\)) )+//'
}

update_sessions() {
    # Get all sessions
    while IFS= read -r line; do
        session_name=$(echo "$line" | cut -d: -f1)

        # Get the original name (strip any existing prefix)
        original=$(strip_prefix "$session_name")

        # Find the first pane in this session
        first_pane="${session_name}:0.0"

        # Also check other panes in case pane 0 is not Claude but pane 1 is
        best_state="EMPTY"
        best_detail=""

        panes=$(tmux list-panes -t "$session_name" -F "#{pane_index}" 2>/dev/null)
        for pane_idx in $panes; do
            target="${session_name}:0.${pane_idx}"
            result=$("$SCRIPT_DIR/detect-state.sh" "$target" 2>/dev/null)
            state=$(echo "$result" | cut -d'|' -f1)
            detail=$(echo "$result" | cut -d'|' -f2)

            # Priority: PERMISSION > RUNNING > TYPING > READY > SHELL > EMPTY
            case "$state" in
                PERMISSION)
                    best_state="PERMISSION"
                    best_detail="$detail"
                    break  # highest priority, stop looking
                    ;;
                RUNNING)
                    if [[ "$best_state" != "PERMISSION" ]]; then
                        best_state="RUNNING"
                        best_detail="$detail"
                    fi
                    ;;
                TYPING)
                    if [[ "$best_state" != "PERMISSION" && "$best_state" != "RUNNING" ]]; then
                        best_state="TYPING"
                        best_detail="$detail"
                    fi
                    ;;
                READY)
                    if [[ "$best_state" == "EMPTY" || "$best_state" == "SHELL" ]]; then
                        best_state="READY"
                        best_detail="$detail"
                    fi
                    ;;
                SHELL)
                    if [[ "$best_state" == "EMPTY" ]]; then
                        best_state="SHELL"
                        best_detail="$detail"
                    fi
                    ;;
            esac
        done

        prefix=$(get_status_prefix "$best_state")

        if [[ -n "$prefix" ]]; then
            new_name="${prefix} ${original}"
        else
            new_name="$original"
        fi

        # Only rename if changed
        if [[ "$new_name" != "$session_name" ]]; then
            tmux rename-session -t "$session_name" "$new_name" 2>/dev/null
        fi

    done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null)
}

if $LOOP; then
    while true; do
        update_sessions
        sleep "$INTERVAL"
    done
else
    update_sessions
fi
