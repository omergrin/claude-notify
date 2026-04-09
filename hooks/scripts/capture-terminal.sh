#!/usr/bin/env bash
# capture-terminal.sh -- Captures terminal identity at session start.
# Writes context to a temp file that notify.sh reads on Stop/Notification events.
set -euo pipefail

# Guard: jq is required for JSON parsing.
if ! command -v jq &>/dev/null; then
  echo "claude-notify: jq is required but not installed. Run: brew install jq" >&2
  exit 1
fi

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
if [[ -z "$session_id" ]]; then
  exit 0
fi

# Validate session_id to prevent path traversal.
if [[ ! "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "claude-notify: invalid session_id" >&2
  exit 1
fi

# Hooks run as subprocesses without a tty -- walk the process tree to find one.
resolve_tty() {
  local pid=$$
  while [ "$pid" -gt 1 ] 2>/dev/null; do
    local t
    t="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')"
    if [ -n "$t" ] && [ "$t" != "??" ]; then
      echo "/dev/$t"
      return
    fi
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  done
}

# Cursor is a VS Code fork and sets TERM_PROGRAM=vscode.
# Distinguish by checking __CFBundleIdentifier (set by macOS for GUI apps).
term="${TERM_PROGRAM:-}"
if [[ "$term" == "vscode" ]]; then
  bundle="${__CFBundleIdentifier:-}"
  case "$bundle" in
    com.todesktop.*) term="cursor" ;;
  esac
fi

# Write context as properly escaped JSON using jq.
context_file="/tmp/claude-notify-${session_id}.json"
jq -n \
  --arg term "$term" \
  --arg tty "$(resolve_tty)" \
  --arg iterm_session "${ITERM_SESSION_ID##*:}" \
  '{term: $term, tty: $tty, iterm_session: $iterm_session}' \
  > "$context_file"
