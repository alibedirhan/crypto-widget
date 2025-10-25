#!/usr/bin/env bash
set -euo pipefail

dget(){ dconf read "${DCONF_BASE}/$1" 2>/dev/null || true; }
dset(){ dconf write "${DCONF_BASE}/$1" "$2" 2>/dev/null || true; }

group_int(){
  local i="$1"
  # Validate input is a number
  [[ "$i" =~ ^[0-9]+$ ]] || { printf "%s" "$i"; return; }
  
  if command -v numfmt >/dev/null 2>&1; then
    # Use numfmt with grouping (adds thousands separator)
    LC_NUMERIC=en_US.UTF-8 numfmt --grouping "$i" 2>/dev/null || printf "%s" "$i"
  else
    # Fallback: manual grouping with sed (adds comma every 3 digits from right)
    printf "%s" "$i" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
  fi
}
isnum(){ [[ "${1:-}" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; }
roundi(){ printf "%.0f" "${1:-0}" 2>/dev/null || printf "0"; }
log(){ printf "[%s] %s\n" "$(date '+%F %T')" "$*" >> "$LOG_FILE"; }