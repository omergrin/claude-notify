#!/usr/bin/env bash
# notify.sh -- Sends a macOS desktop notification with click-to-focus.
# Handles both Stop (chat completed) and Notification (input needed) events.
set -euo pipefail

# Guard: jq is required for JSON parsing.
if ! command -v jq &>/dev/null; then
  echo "claude-notify: jq is required but not installed. Run: brew install jq" >&2
  exit 1
fi

# --- Parse payload (single jq call, tab-separated for safe reading) ---
payload="$(cat)"
IFS=$'\t' read -r hook_event session_id notification_type raw_message cwd < <(
  jq -r '[
    (.hook_event_name // ""),
    (.session_id // ""),
    (.notification_type // ""),
    (.message // ""),
    (.cwd // "")
  ] | join("\t")' <<<"$payload"
)

# Skip idle_prompt notifications (fires too frequently to be useful).
if [[ "$notification_type" == "idle_prompt" ]]; then
  exit 0
fi

# --- Message ---
title="Claude Code"
case "$hook_event" in
  Stop)
    message="Chat completed"
    ;;
  Notification)
    case "$notification_type" in
      user_input)
        message="User input: ${raw_message:-please review the proposed changes}"
        ;;
      permission_prompt)
        message="Decision needed: ${raw_message:-should I proceed?}"
        ;;
      *)
        message="${raw_message:-Notification received}"
        ;;
    esac
    ;;
  *)
    message="Event: ${hook_event}"
    ;;
esac

# --- Project path (used by vscode/cursor URI) ---
repo="${CLAUDE_PROJECT_DIR:-$cwd}"
if [[ -z "$repo" ]]; then
  repo="$PWD"
fi

# --- Load terminal context captured at session start ---
term=""
tty_path=""
iterm_session=""
context_file="/tmp/claude-notify-${session_id}.json"
if [[ -n "$session_id" && -f "$context_file" && ! -L "$context_file" ]]; then
  IFS=$'\t' read -r term tty_path iterm_session < <(
    jq -r '[(.term // ""), (.tty // ""), (.iterm_session // "")] | join("\t")' <"$context_file"
  )
fi
if [[ -z "$term" ]]; then
  term="${TERM_PROGRAM:-}"
fi

# --- Click-to-focus ---
# terminal-notifier supports -activate (bundle ID), -open (URI), and -execute (shell cmd).
focus_flag=()
case "$term" in
  Apple_Terminal)
    if [[ -n "$tty_path" && "$tty_path" =~ ^/dev/ttys[0-9]+$ ]]; then
      focus_flag=(-execute "osascript -e 'tell application \"Terminal\" to activate' -e 'tell application \"Terminal\" to set index of (first window whose tty of tab 1 is \"$tty_path\") to 1'")
    else
      focus_flag=(-activate com.apple.Terminal)
    fi
    ;;
  iTerm.app|iTerm2)
    if [[ -n "$iterm_session" && "$iterm_session" =~ ^[A-F0-9-]+$ ]]; then
      focus_flag=(-execute "osascript -e 'tell application \"iTerm2\"' -e 'activate' -e 'repeat with w in windows' -e 'repeat with t in tabs of w' -e 'repeat with s in sessions of t' -e 'if id of s is \"$iterm_session\" then select t' -e 'end repeat' -e 'end repeat' -e 'end repeat' -e 'end tell'")
    else
      focus_flag=(-activate com.googlecode.iterm2)
    fi
    ;;
  kitty)
    focus_flag=(-activate net.kovidgoyal.kitty)
    ;;
  ghostty)
    focus_flag=(-activate com.mitchellh.ghostty)
    ;;
  vscode)
    focus_flag=(-open "vscode://file${repo}")
    ;;
  cursor)
    focus_flag=(-open "cursor://file${repo}")
    ;;
  WarpTerminal)
    focus_flag=(-activate dev.warp.Warp-Stable)
    ;;
esac

# --- Send ---
# Sanitize message for osascript fallback (escape backslashes and quotes).
sanitized_message="${message//\\/\\\\}"
sanitized_message="${sanitized_message//\"/\\\"}"

if command -v terminal-notifier &>/dev/null; then
  terminal-notifier \
    -title "$title" \
    -message "$message" \
    -sound Submarine \
    ${focus_flag[@]+"${focus_flag[@]}"}
else
  osascript -e "display notification \"$sanitized_message\" with title \"$title\" sound name \"Submarine\""
fi
