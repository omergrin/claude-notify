# claude-notify

macOS desktop notifications for Claude Code with click-to-focus support.

Get notified when Claude finishes work or needs your input. Click the notification to jump back to the terminal where Claude is running.

## Installation

```bash
git clone https://github.com/omergrinboim/claude-notify.git ~/dev/claude-notify
claude plugin add ~/dev/claude-notify
```

Or load directly for a single session:

```bash
claude --plugin-dir ~/dev/claude-notify
```

### Dependencies

- **jq** (required): `brew install jq`
- **terminal-notifier** (recommended): `brew install terminal-notifier`

Without `terminal-notifier`, notifications use native macOS `osascript` (no click-to-focus).

Run `/notify-setup` inside Claude Code to verify your setup.

## How It Works

| Hook | When | Notification |
|---|---|---|
| **SessionStart** | Session begins | Captures terminal identity (app, tty) |
| **Stop** | Chat finishes | "Chat completed" |
| **Notification** | Claude needs input | Contextual message (user input / decision needed) |

Idle prompt notifications are silently skipped.

## Supported Terminals

| Terminal | Click-to-Focus | Tested |
|---|---|---|
| Terminal.app | Focuses the exact window (matched by tty) | Yes |
| iTerm2 | Focuses the exact tab (matched by session ID) | Yes |
| VS Code | Opens the exact project window (`vscode://` URI) | Yes |
| Cursor | Opens the exact project window (`cursor://` URI) | Yes |
| Kitty | Activates app | — |
| Ghostty | Activates app | — |
| Warp | Activates app | — |

Other terminals receive notifications without click-to-focus.

## Troubleshooting

Run `/notify-setup` to diagnose issues.

- **No notifications**: Install `jq` (`brew install jq`)
- **No click-to-focus**: Install `terminal-notifier` (`brew install terminal-notifier`)
- **Wrong terminal detected**: Check `echo $TERM_PROGRAM`
- **macOS Focus mode**: Notifications are suppressed when Focus / Do Not Disturb is enabled

## License

MIT
