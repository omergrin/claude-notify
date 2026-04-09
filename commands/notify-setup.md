---
name: notify-setup
description: Check claude-notify dependencies and test notifications
---

Run the following diagnostics for the claude-notify plugin and report the results:

## 1. Check dependencies

Run these commands and report pass/fail for each:

- `command -v jq` — **required** for parsing hook payloads
- `command -v terminal-notifier` — **optional** but recommended for click-to-focus

If `jq` is missing: `brew install jq`
If `terminal-notifier` is missing: `brew install terminal-notifier` (notifications will still work via osascript fallback, but without click-to-focus)

## 2. Detect terminal

Report the value of `$TERM_PROGRAM`. Map it to the supported terminal:

| TERM_PROGRAM | Terminal | Click-to-focus method |
|---|---|---|
| Apple_Terminal | Terminal.app | Focuses correct window via tty |
| iTerm.app / iTerm2 | iTerm2 | Activates app |
| kitty | Kitty | Activates app |
| ghostty | Ghostty | Activates app |
| vscode | VS Code | Opens project via `vscode://` URI |
| cursor | Cursor | Opens project via `cursor://` URI |
| WarpTerminal | Warp | Activates app |

If not recognized, report it as "Unknown — notification will fire but no click-to-focus".

## 3. Send test notification

First, find the plugin's notify script by searching for `hooks/scripts/notify.sh` inside `~/.claude/plugins/` or `~/dev/claude-notify/`. Then run:

```
echo '{"hook_event_name":"Stop","session_id":"test-setup"}' | bash <path-to-notify.sh>
```

Ask the user whether the notification appeared and if clicking it focused the correct window.

## 4. Summary

Print a summary table:

| Check | Status |
|---|---|
| jq | installed / MISSING |
| terminal-notifier | installed / missing (optional) |
| Terminal | detected name |
| Test notification | sent |
