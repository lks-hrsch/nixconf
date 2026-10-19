#!/usr/bin/env bash
# Claude Code status line: RGB gradient, dynamic emoji, cost, code velocity

input=$(cat)

# ── Colors: Catppuccin Mocha ──
CYAN='\033[38;2;137;220;235m'    # sky
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
MAGENTA='\033[38;2;203;166;247m' # mauve
PEACH='\033[38;2;250;179;135m'
DIM='\033[38;2;108;112;134m'     # overlay0
BOLD='\033[1m'
RESET='\033[0m'

# ── Truecolor helper ──
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

# ── Parse JSON fields ──
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
FIVE_HR=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
SEVEN_DAY=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
FIVE_HR_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | floor')
SEVEN_DAY_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty | floor')

# Color a rate-limit percentage by how close the window is to exhaustion.
quota_color() {
  if [ "$1" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# Epoch seconds -> strftime format (default HH:MM). BSD/macOS date uses -r, GNU date uses -d.
clock_time() { date -r "$1" "+${2:-%H:%M}" 2>/dev/null || date -d "@$1" "+${2:-%H:%M}"; }


# ── Git info ──
branch=""
repo=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
fi

# ── Context bar: RGB gradient, full blocks only ──
BAR_WIDTH=20

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")

  # Round to nearest block
  filled=$(( (used_int * BAR_WIDTH + 50) / 100 ))

  bar=""
  for (( i=0; i<BAR_WIDTH; i++ )); do
    pos=$(( i * 100 / (BAR_WIDTH - 1) ))

    # Mocha green (166,227,161) -> yellow (249,226,175) -> red (243,139,168)
    if [ "$pos" -le 50 ]; then
      r=$(( 166 + 83 * pos / 50 ))
      g=$(( 227 - pos / 50 ))
      b=$(( 161 + 14 * pos / 50 ))
    else
      adj=$(( pos - 50 ))
      r=$(( 249 - 6 * adj / 50 ))
      g=$(( 226 - 87 * adj / 50 ))
      b=$(( 175 - 7 * adj / 50 ))
    fi

    if [ "$i" -lt "$filled" ]; then
      bar="${bar}$(rgb $r $g $b)█"
    else
      bar="${bar}\033[38;2;69;71;90m░"
    fi
  done
  bar="${bar}${RESET}"

  if [ "$used_int" -ge 90 ]; then status_emoji="🚨"
  elif [ "$used_int" -ge 70 ]; then status_emoji="🔥"
  elif [ "$used_int" -ge 20 ]; then status_emoji="⚡"
  else status_emoji="🟢"; fi

  if [ "$used_int" -ge 90 ]; then pct_color="$RED"
  elif [ "$used_int" -ge 70 ]; then pct_color="$YELLOW"
  else pct_color="$GREEN"; fi

  ctx_part="${status_emoji} ${bar} ${pct_color}${used_int}%${RESET}"
else
  ctx_part="🟢 \033[38;2;69;71;90m░░░░░░░░░░░░░░░░░░░░${RESET} --%"
fi

# ── Cost ──
cost_part="${YELLOW}$(printf '$%.2f' "$cost")${RESET}"

# ── Code velocity ──
velocity="${GREEN}+${lines_add}${RESET} ${RED}-${lines_del}${RESET}"

# ── Ponytail mode badge (plugin writes this flag at SessionStart) ──
pony=""
pony_flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.ponytail-active"
if [ -f "$pony_flag" ]; then
  pony_mode=$(head -n1 "$pony_flag" | tr -d '[:space:]')
  pony_color=108
  [ "$pony_mode" = "ultra" ] && pony_color=173
  if [ -z "$pony_mode" ] || [ "$pony_mode" = "full" ]; then
    pony="\033[38;5;${pony_color}m[PONYTAIL]\033[0m"
  else
    pony="\033[38;5;${pony_color}m[PONYTAIL:$(printf '%s' "$pony_mode" | tr '[:lower:]' '[:upper:]')]\033[0m"
  fi
fi

# ── Rate limits (second line): 5h with reset time + time left, 7d ──
quota=""
if [ -n "$FIVE_HR" ]; then
  five_int=$(printf '%.0f' "$FIVE_HR")
  quota="5h: $(quota_color "$five_int")${five_int}%${RESET}"
  # Reset time is only useful once some of the window is actually spent.
  if [ -n "$FIVE_HR_RESET" ] && [ "$five_int" -gt 0 ]; then
    remaining=$(( FIVE_HR_RESET - $(date +%s) ))
    [ "$remaining" -lt 0 ] && remaining=0
    quota="${quota} ${DIM}→ $(clock_time "$FIVE_HR_RESET") ($(( remaining / 3600 ))h$(printf '%02d' $(( remaining % 3600 / 60 )))m left)${RESET}"
  fi
fi
if [ -n "$SEVEN_DAY" ]; then
  seven_int=$(printf '%.0f' "$SEVEN_DAY")
  quota="${quota:+$quota ${DIM}|${RESET} }7d: $(quota_color "$seven_int")${seven_int}%${RESET}"
  if [ -n "$SEVEN_DAY_RESET" ] && [ "$seven_int" -gt 0 ]; then
    remaining=$(( SEVEN_DAY_RESET - $(date +%s) ))
    [ "$remaining" -lt 0 ] && remaining=0
    quota="${quota} ${DIM}→ $(clock_time "$SEVEN_DAY_RESET" '%a %H:%M') ($(( remaining / 86400 ))d$(( remaining % 86400 / 3600 ))h left)${RESET}"
  fi
fi

# ── Line 1: session; line 2: rate limits (omitted without quota data) ──
out=""
[ -n "$pony" ] && out="$pony"
[ -n "$repo" ] && out="${out:+$out }${BOLD}${YELLOW}${repo}${RESET}"
[ -n "$branch" ] && out="${out:+$out }${BOLD}${CYAN}🌿 (${branch})${RESET}"
out="${out:+$out ${DIM}|${RESET} }${ctx_part}"
out="${out} ${DIM}|${RESET} ${cost_part}"
out="${out} ${DIM}|${RESET} ${velocity}"
out="${out} ${DIM}|${RESET} ${MAGENTA}🤖 ${model}${RESET}"
[ -n "$EFFORT" ] && out="${out} ${PEACH}⚡ ${EFFORT}${RESET}"

printf '%b' "$out"
[ -n "$quota" ] && printf '\n%b' "$quota"
exit 0