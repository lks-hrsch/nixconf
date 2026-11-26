#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
# Claude Code PreCompact and SessionEnd hook: runs /reflect in a detached headless fork of the
# session, so learned facts are saved before compaction drops detail or the session ends.
# A hook cannot make the live session run a command, and at exit there is no turn left.
# Logs: ${XDG_STATE_HOME:-~/.local/state}/claude-reflect/. CLAUDE_REFLECT_DRY_RUN=1 only prints.

# The fork runs the same hooks; this keeps it from reflecting on itself.
[ -n "${CLAUDE_REFLECT_HOOK:-}" ] && exit 0
command -v claude >/dev/null || exit 0

input=$(cat)
field() { jq -r --arg k "$1" '.[$k] // empty' <<<"$input"; }
session=$(field session_id)
transcript=$(field transcript_path)
cwd=$(field cwd)
event=$(field hook_event_name)
[ -n "$session" ] && [ -f "$transcript" ] && [ -d "$cwd" ] || exit 0

# Opt-in per repo: only where .claude/learned-facts.md exists (a manual /reflect creates it).
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.claude/learned-facts.md" ] || exit 0

# Fewer than 3 typed prompts is too short a session to be worth a model run.
prompts=$(jq -Rn '[inputs | fromjson? | select(.type == "user" and (.isMeta | not)
  and (.message.content | type) == "string")] | length' "$transcript")
[ "$prompts" -ge 3 ] || exit 0

state="${XDG_STATE_HOME:-$HOME/.local/state}/claude-reflect"
mkdir -p "$state"
# One reflect per repo at a time, so two forks never edit the facts file together.
# shortcut: a fork killed mid-run leaves its lock dir behind; rmdir it by hand if reflects stop.
lock="$state/$(printf %s "$root" | cksum | cut -d' ' -f1).lock"
mkdir "$lock" 2>/dev/null || exit 0

if [ -n "${CLAUDE_REFLECT_DRY_RUN:-}" ]; then
  echo "would reflect session $session ($event, $prompts prompts) in $root"
  rmdir "$lock"
  exit 0
fi

log="$state/$(date +%Y%m%d-%H%M%S)-$event-$session.log"
cd "$root"
# Only the facts file is writable, and no Bash: nobody is there to approve anything.
# shellcheck disable=SC2016 # $1-$3 expand inside the child sh, passed as arguments
CLAUDE_REFLECT_HOOK=1 nohup sh -c '
  claude -p --resume "$1" --fork-session --model sonnet \
    --allowedTools Read Glob Grep "Edit(./.claude/learned-facts.md)" \
    -- "/reflect Headless run from a $2 hook: nobody can approve changes, so skip the promote step and only append facts."
  rmdir "$3"
' sh "$session" "$event" "$lock" >"$log" 2>&1 </dev/null &
