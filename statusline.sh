#!/bin/bash
# Claude Code statusLine - powerline version
# Segments: model + effort | cwd (branch) | ctx% + tokens | cost | duration + api + time

input=$(cat)

# Parse all fields via one python call (faster than multiple)
IFS=$'\t' read -r model cwd git_dir ctx_pct in_tok ctx_size cost dur_ms api_ms thinking effort <<< "$(
  echo "$input" | python3 -c "
import sys, json, os
try:
    d = json.load(sys.stdin)
    m = d.get('model', {}).get('display_name', '?')
    m = m.replace('Claude ', '').replace(' (1M context)', '[1M]')
    cwd_raw = d.get('workspace', {}).get('current_dir') or d.get('cwd', '')
    cwd = os.path.basename(cwd_raw) or '~'
    ctx = d.get('context_window', {}) or {}
    ctx_pct = ctx.get('used_percentage') or 0
    in_tok = ctx.get('total_input_tokens') or 0
    ctx_size = ctx.get('context_window_size') or 0
    cost_usd = d.get('cost', {}).get('total_cost_usd', 0)
    dur_ms = d.get('cost', {}).get('total_duration_ms', 0)
    api_ms = d.get('cost', {}).get('total_api_duration_ms', 0)
    thinking = '1' if d.get('thinking', {}).get('enabled') else '0'
    effort = d.get('effort', {}).get('level', '') or '-'
    print('\t'.join(map(str, [m, cwd, cwd_raw or '.', int(ctx_pct), in_tok, ctx_size, f'{cost_usd:.2f}', dur_ms, api_ms, thinking, effort])))
except Exception:
    print('\t'.join(map(str, ['?', '?', '.', 0, 0, 0, '0.00', 0, 0, 0, '-'])))
"
)"

# Git branch (best-effort); fall back to short hash when detached HEAD
git_branch=$(git -C "$git_dir" branch --show-current 2>/dev/null)
git_detached=""
if [ -z "$git_branch" ]; then
  short=$(git -C "$git_dir" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$short" ]; then git_branch="@$short"; git_detached="1"; fi
fi
# Git dirty: count of changed (tracked+untracked) entries; empty if clean
git_dirty=""
if [ -n "$git_branch" ]; then
  n=$(git -C "$git_dir" status --porcelain 2>/dev/null | grep -c .)
  [ "$n" -gt 0 ] 2>/dev/null && git_dirty="$n"
fi

# Duration formatter
fmt_duration() {
  local ms=$1
  local s=$((ms / 1000))
  if [ "$s" -ge 3600 ]; then printf "%dh%dm" $((s/3600)) $(((s%3600)/60))
  elif [ "$s" -ge 60 ]; then printf "%dm%ds" $((s/60)) $((s%60))
  else printf "%ds" "$s"; fi
}
dur=$(fmt_duration "$dur_ms")

# API wait ratio: api time as % of wall-clock; shown only when meaningful
api_seg=""
if [ "$dur_ms" -gt 0 ] && [ "$api_ms" -gt 0 ]; then
  api_pct=$(( api_ms * 100 / dur_ms ))
  [ "$api_pct" -gt 100 ] && api_pct=100
  api_seg="api ${api_pct}%"
fi

# Token formatter: 84000 -> 84k, 1000000 -> 1M, 1500 -> 1.5k
fmt_tok() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { v = n / 1000000; if (v < 10) { s = sprintf("%.1f", v); sub(/\.0$/, "", s); printf "%sM", s } else { printf "%dM", int(v) } }'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { v = n / 1000; if (v < 10) { s = sprintf("%.1f", v); sub(/\.0$/, "", s); printf "%sk", s } else { printf "%dk", int(v) } }'
  else
    printf "%d" "$n"
  fi
}
tok_seg=""
if [ "$in_tok" -gt 0 ] && [ "$ctx_size" -gt 0 ]; then
  tok_seg=" $(fmt_tok "$in_tok")/$(fmt_tok "$ctx_size")"
fi

# ---- Powerline glyphs ----
SEP=$''      # right-pointing filled arrow
GIT=$''      # branch symbol
THIN=$'│'     # readable inner separator
RESET=$'\033[0m'

# 256-color helpers: fg(n)/bg(n)
fg() { printf '\033[38;5;%sm' "$1"; }
bg() { printf '\033[48;5;%sm' "$1"; }

# Segment background colors
C_MODEL=61     # muted indigo
C_DIR=31       # teal blue
C_COST=65      # muted green
C_TIME=238     # dark gray
# Context color by usage: green <60, yellow <80, orange <90, red >=90
ctx_label="ctx"
if   [ "$ctx_pct" -lt 60 ]; then C_CTX=28
elif [ "$ctx_pct" -lt 80 ]; then C_CTX=136
elif [ "$ctx_pct" -lt 90 ]; then C_CTX=166; ctx_label="ctx!"
else C_CTX=124; ctx_label="ctx!"; fi

# Effort badge + label: brain for high tiers, thought bubble for plain thinking
badge=""
case "$effort" in
  high|xhigh|max) badge=" 🧠 ${effort}" ;;
  low|medium)     [ "$thinking" = "1" ] && badge=" 💭 ${effort}" || badge=" ${effort}" ;;
  *)              [ "$thinking" = "1" ] && badge=" 💭" ;;
esac

time=$(date +"%H:%M")

# ---- Render powerline segments ----
out=""
# Segment 1: model + effort
out+="$(fg 255)$(bg $C_MODEL) ● ${model}${badge} "
# transition model -> dir
out+="$(fg $C_MODEL)$(bg $C_DIR)${SEP}"
# Segment 2: cwd (+ branch + dirty)
if [ -n "$git_branch" ]; then
  out+="$(fg 255)$(bg $C_DIR) ${cwd} $(fg 250)${GIT} ${git_branch}"
  [ -n "$git_dirty" ] && out+="$(fg 215) +${git_dirty}"
  out+=" "
else
  out+="$(fg 255)$(bg $C_DIR) ${cwd} "
fi
# transition dir -> ctx
out+="$(fg $C_DIR)$(bg $C_CTX)${SEP}"
# Segment 3: ctx% + tokens
out+="$(fg 255)$(bg $C_CTX) ${ctx_label} ${ctx_pct}%${tok_seg} "
# transition ctx -> cost
out+="$(fg $C_CTX)$(bg $C_COST)${SEP}"
# Segment 4: cost
out+="$(fg 255)$(bg $C_COST) \$${cost} "
# transition cost -> time
out+="$(fg $C_COST)$(bg $C_TIME)${SEP}"
# Segment 5: duration | api ratio | time  (thin separators + distinct shades)
out+="$(fg 252)$(bg $C_TIME) ${dur} "
if [ -n "$api_seg" ]; then
  out+="$(fg 240)${THIN}$(fg 245) ${api_seg} "
fi
out+="$(fg 240)${THIN}$(fg 252) ${time} "
# final cap
out+="${RESET}$(fg $C_TIME)${SEP}${RESET}"

printf "%b" "$out"
