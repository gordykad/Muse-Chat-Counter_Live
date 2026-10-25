#!/usr/bin/env bash
# Chat title token ticker — per-chat polling script (template).
#
# Setup: copy to ~/hooks/scripts/chat-ticker-<CHAT_ID>.sh and replace
# every <CHAT_ID> with the target chat's id. The hook that runs this
# script should poll every 600 seconds.
#
# Behavior: reads ONLY the ticker state file. Ends `silent` while the
# chat title's ~x suffix matches the latest recorded session_status
# read; ends `wake` (with the state as payload) when a fresher read
# was recorded but never stamped.
set -euo pipefail
source "$HATCH_HOOK_RUNTIME"

STATE="$HOME/hooks/state/chat-ticker-<CHAT_ID>.json"

if [ ! -f "$STATE" ]; then
  silent "no ticker state file" '{}'
  exit 0
fi

VALUE="$(jq -r '.value // empty' "$STATE")"
STAMPED="$(jq -r '.stamped_value // empty' "$STATE")"

if [ -z "$VALUE" ]; then
  silent "no token value recorded yet" '{}'
  exit 0
fi

if [ "$VALUE" = "$STAMPED" ]; then
  silent "title suffix current" "{\"value\": $VALUE}"
  exit 0
fi

log "ticker drift detected" "{\"value\": $VALUE, \"stamped_value\": $STAMPED}"
wake "chat title token suffix is stale" "$(jq -c '{chat_id, base_name, value, stamped_value}' "$STATE")"
