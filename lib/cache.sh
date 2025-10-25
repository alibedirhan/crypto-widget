#!/usr/bin/env bash
set -euo pipefail

RENDER_FILE="$CACHE_DIR/render.txt"
HIST_FILE="$CACHE_DIR/history_btc.txt"

arrow_pct(){
  local pct="$1"; isnum "$pct" || { printf ""; return; }
  local p; p=$(printf "%.1f" "$pct")
  if awk "BEGIN{exit !($pct>0)}"; then
    (( ${USE_PANGO:-1} )) && printf " <span foreground=\"#24d17e\">▲ %s%%</span>" "$p" || printf " ▲ %s%%" "$p"
  elif awk "BEGIN{exit !($pct<0)}"; then
    (( ${USE_PANGO:-1} )) && printf " <span foreground=\"#ff6b6b\">▼ %s%%</span>" "${p#-}" || printf " ▼ %s%%" "${p#-}"
  fi
}

spark(){
  local nums=() v
  for v in "$@"; do
    [[ "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]] && nums+=("$v")
  done
  ((${#nums[@]}<2)) && { printf ""; return; }

  local min max
  min="${nums[0]}"; max="${nums[0]}"
  for v in "${nums[@]}"; do
    awk "BEGIN{exit !($v<=$min)}" || min="$v"
    awk "BEGIN{exit !($v>=$max)}" || max="$v"
  done

  local span; span=$(awk -v a="$max" -v b="$min" 'BEGIN{printf (a-b)}')
  awk "BEGIN{exit !($span==0)}" && { printf ""; return; }

  local bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █) out=""
  for v in "${nums[@]}"; do
    local norm; norm=$(awk -v x="$v" -v mn="$min" -v sp="$span" 'BEGIN{printf (x-mn)/sp}')
    local idx; idx=$(awk -v n="$norm" 'BEGIN{printf int(n*7)}')
    (( idx<0 )) && idx=0; (( idx>7 )) && idx=7
    out+="${bars[$idx]}"
  done
  printf "%s" "$out"
}

render_once(){
  config_load

  local btc_pair eth_pair btc_p btc_pct eth_p eth_pct xau_p usdtry now
  btc_pair="$(get_crypto BTC)"; btc_p="${btc_pair%|*}"; btc_pct="${btc_pair#*|}"
  eth_pair="$(get_crypto ETH)"; eth_p="${eth_pair%|*}"; eth_pct="${eth_pair#*|}"

  now="$(date +%s)"

  local xau_cache="$CACHE_DIR/xau.txt"
  local need_xau=1
  if [[ -f "$xau_cache" ]]; then
    local age; age=$(( now - $(stat -c %Y "$xau_cache" 2>/dev/null || echo 0) ))
    (( age < ${XAU_TTL:-300} )) && need_xau=0
  fi
  if (( need_xau )); then
    xau_p="$(get_gold)"; [[ -n "$xau_p" ]] && printf "%s" "$xau_p" > "$xau_cache"
  else
    xau_p="$(cat "$xau_cache" 2>/dev/null || true)"
  fi

  local usdtry_cache="$CACHE_DIR/usdtry.txt"
  local need_fx=1
  if [[ -f "$usdtry_cache" ]]; then
    local age; age=$(( now - $(stat -c %Y "$usdtry_cache" 2>/dev/null || echo 0) ))
    (( age < ${FX_TTL:-600} )) && need_fx=0
  fi
  if (( need_fx )); then
    usdtry="$(get_fx)"; [[ -n "$usdtry" ]] && printf "%s" "$usdtry" > "$usdtry_cache"
  else
    usdtry="$(cat "$usdtry_cache" 2>/dev/null || true)"
  fi

  tl_of(){ local usd="$1"; [[ -n "$usd" && -n "${usdtry:-}" ]] && awk -v p="$usd" -v r="$usdtry" 'BEGIN{printf "%.0f", p*r}'; }

  notify_hit(){
    command -v notify-send >/dev/null 2>&1 || return 0
    local s="$1" price="$2" dir="$3" thr="$4"
    local cooldown="${ALERT_COOLDOWN:-300}"
    
    if [[ "$cooldown" == "0" ]]; then
      notify-send "CAL Ticker" "${s} ${price%.*} ${dir} ${thr%.*}"
      return 0
    fi
    
    local key="${s}_${dir}_${thr}"
    key="${key//[^a-zA-Z0-9_]/_}"
    local now=$(date +%s)
    local alert_file="$CACHE_DIR/last_alert_${key}.txt"
    
    local last=0
    if [[ -f "$alert_file" ]]; then
      last=$(cat "$alert_file" 2>/dev/null || echo 0)
      [[ "$last" =~ ^[0-9]+$ ]] || last=0
    fi
    
    if (( now - last >= cooldown )); then
      notify-send "CAL Ticker" "${s} ${price%.*} ${dir} ${thr%.*}"
      echo "$now" > "$alert_file"
    fi
  }

  chk_thr(){
    local s="$1" price="$2"
    local up="ALERT_${s}_ABOVE" down="ALERT_${s}_BELOW"
    local a="${!up:-}" b="${!down:-}"
    [[ -n "$price" ]] || return 0
    [[ -n "$a" ]] && awk "BEGIN{exit !($price>$a)}" && notify_hit "$s" "$price" ">" "$a"
    [[ -n "$b" ]] && awk "BEGIN{exit !($price<$b)}" && notify_hit "$s" "$price" "<" "$b"
  }
  chk_thr BTC "$btc_p"; chk_thr ETH "$eth_p"

  if (( ${SHOW_SPARKLINE:-1} )) && isnum "${btc_p:-}"; then
    printf "%s\n" "$btc_p" >> "$HIST_FILE"
    local lines; lines=$(wc -l < "$HIST_FILE" 2>/dev/null || echo 0)
    if (( lines > ${SPARK_POINTS:-40} )); then
      tail -n "${SPARK_POINTS:-40}" "$HIST_FILE" > "$HIST_FILE.tmp" && mv "$HIST_FILE.tmp" "$HIST_FILE"
    fi
  fi

  LABEL_W=5; PRICE_W=8
  {
    if isnum "${btc_p:-}"; then
      local tl=""; if (( ${SHOW_TRY:-1} )) && isnum "${usdtry:-}"; then tl="$(tl_of "$btc_p")"; [[ -n "$tl" ]] && tl=" (₺ $(group_int "$tl"))"; fi
      printf "%-${LABEL_W}s : %${PRICE_W}s%s%s\n" "BTC" "$(group_int "$(roundi "$btc_p")")" "$tl" "$(arrow_pct "$btc_pct")"
    else printf "%-${LABEL_W}s : %${PRICE_W}s\n" "BTC" "—"; fi

    if isnum "${eth_p:-}"; then
      local tl=""; if (( ${SHOW_TRY:-1} )) && isnum "${usdtry:-}"; then tl="$(tl_of "$eth_p")"; [[ -n "$tl" ]] && tl=" (₺ $(group_int "$tl"))"; fi
      printf "%-${LABEL_W}s : %${PRICE_W}s%s%s\n" "ETH" "$(group_int "$(roundi "$eth_p")")" "$tl" "$(arrow_pct "$eth_pct")"
    else printf "%-${LABEL_W}s : %${PRICE_W}s\n" "ETH" "—"; fi

    if isnum "${xau_p:-}"; then
      local tl=""; if (( ${SHOW_TRY:-1} )) && isnum "${usdtry:-}"; then tl="$(tl_of "$xau_p")"; [[ -n "$tl" ]] && tl=" (₺ $(group_int "$tl"))"; fi
      printf "%-${LABEL_W}s : %${PRICE_W}s%s\n" "GOLD" "$(group_int "$(roundi "$xau_p")")" "$tl"
    else printf "%-${LABEL_W}s : %${PRICE_W}s\n" "GOLD" "—"; fi

    if (( ${SHOW_SPARKLINE:-1} )) && [[ -f "$HIST_FILE" ]]; then
      mapfile -t pts < "$HIST_FILE"
      local filtered=()
      for x in "${pts[@]}"; do [[ "$x" =~ ^-?[0-9]+([.][0-9]+)?$ ]] && filtered+=("$x"); done
      ((${#filtered[@]}>1)) && { echo -n "BTC 24h:   "; spark "${filtered[@]}"; echo; }
    fi
  } > "$RENDER_FILE"
  (( ${LOG_ENABLE:-1} )) && log "render updated"
}

show_cache(){
  if [[ -s "$RENDER_FILE" ]]; then sed -n '1,10p' "$RENDER_FILE"
  else echo -e "BTC  : —\nETH  : —\nGOLD : —"; fi
}
