#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook: lists up to 3 Obsidian notes whose filename contains a word
# of the prompt (4+ letters, cut to 6 so "networking" finds "network"), as a hint to read them
# through the obsidian MCP. Silent otherwise.
# Skipped in ~/.claude-work (gateway providers) and in the reflect fork.
set -o errexit -o nounset -o pipefail
[ -z "${CLAUDE_CONFIG_DIR:-}${CLAUDE_REFLECT_HOOK:-}" ] && [ -d "${OBSIDIAN_VAULT:-}" ] || exit 0

# Filler words would match inside unrelated names ("them" in "Mathematical").
stop='^(from|them|this|that|with|have|what|when|then|than|your|also|here|there|same|used|just|like|make|only|some|does|done|want|need|which|other|these|those|about|check|date|list|more|most|next|into|over|very|will|should|could|would)$'
words=$(jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '\n' |
  grep -vE "$stop" | awk 'length >= 4 { print substr($0, 1, 6) }' | sort -u | paste -sd '|' -) || true
[ -n "$words" ] || exit 0
hits=$(cd "$OBSIDIAN_VAULT" && find . -name '*.md' -not -path './.*' |
  grep -iE "/[^/]*($words)[^/]*\.md$" | head -3) || true
[ -n "$hits" ] || exit 0

echo "Obsidian notes whose filename matches this prompt; read them with the obsidian MCP if relevant:"
echo "$hits"
