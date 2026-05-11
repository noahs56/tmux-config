# tmux config

My tmux configuration with vim keybindings and Claude Code session monitoring.

## Setup

```bash
# 1. Clone the repo
git clone https://github.com/noahs56/tmux-config.git
cd tmux-config

# 2. Symlink the config
ln -sf "$(pwd)/.tmux.conf" ~/.tmux.conf

# 3. Install TPM (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 4. Set up the session monitor scripts (used by the session picker)
mkdir -p ~/.claude/tmux-monitor
cp tmux-monitor/*.sh ~/.claude/tmux-monitor/
chmod +x ~/.claude/tmux-monitor/*.sh

# 5. Reload tmux config
tmux source-file ~/.tmux.conf

# 6. Install plugins (inside tmux)
# Press prefix + I (Ctrl-A then Shift-I)
```

## Keybindings

| Key | Action |
|-----|--------|
| `C-a` | Prefix (remapped from `C-b`) |
| `prefix + \` | Split pane horizontally |
| `prefix + -` | Split pane vertically |
| `C-h/j/k/l` | Navigate panes (no prefix needed) |
| `prefix + l` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Yank to clipboard (in copy mode) |
| `prefix + s` | Session picker |
| `prefix + r` | Reload config |

## Notes

- Clipboard uses `pbcopy` (macOS). On Linux, swap for `xclip` or `xsel`.
- Scroll speed is set to 1 line per wheel tick.
