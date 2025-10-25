#!/usr/bin/env bash
set -euo pipefail

curl_opts=(--silent --show-error --max-time 15 --connect-timeout 10 --retry 2 --retry-delay 1 \
  -H 'User-Agent: Mozilla/5.0' -H 'Cache-Control: no-cache' -H 'Pragma: no-cache')

# Validate API response value
# Returns 0 if valid price, 1 if invalid
validate_price(){
  local val="$1"
  # Check for "null", empty, or non-numeric values
  [[ "$val" == "null" || -z "$val" ]] && return 1
  [[ "$val" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  return 0
}

get_crypto(){
  local sym="$1" last="" pct=""
  case "${CRYPTO_SOURCE:-binance}" in
    binance)
      local j; j="$(curl "${curl_opts[@]}" "https://data-api.binance.vision/api/v3/ticker/24hr?symbol=${sym}USDT" 2>/dev/null | tr -d '\0' || true)"
      last="$(jq -r '.lastPrice' <<<"$j" 2>/dev/null || true)"
      validate_price "$last" || last=""
      pct="$(jq -r '.priceChangePercent' <<<"$j" 2>/dev/null || true)"
      [[ "$pct" == "null" || -z "$pct" ]] && pct=""
      ;;
    coingecko)
      local id="bitcoin"; [[ "$sym" == "ETH" ]] && id="ethereum"
      local j; j="$(curl "${curl_opts[@]}" "https://api.coingecko.com/api/v3/simple/price?ids=${id}&vs_currencies=usd&include_24hr_change=true" 2>/dev/null | tr -d '\0' || true)"
      last="$(jq -r ".\"$id\".usd" <<<"$j" 2>/dev/null || true)"
      validate_price "$last" || last=""
      pct="$(jq -r ".\"$id\".usd_24h_change" <<<"$j" 2>/dev/null || true)"
      [[ "$pct" == "null" || -z "$pct" ]] && pct=""
      ;;
    coinbase)
      local j; j="$(curl "${curl_opts[@]}" "https://api.coinbase.com/v2/prices/${sym}-USD/spot" 2>/dev/null | tr -d '\0' || true)"
      last="$(jq -r '.data.amount' <<<"$j" 2>/dev/null || true)"
      validate_price "$last" || last=""
      pct=""
      ;;
  esac
  printf "%s|%s" "${last:-}" "${pct:-}"
}

get_gold(){
  local price=""
  case "${GOLD_SOURCE:-yahoo}" in
    yahoo)
      local j; j="$(curl "${curl_opts[@]}" 'https://query1.finance.yahoo.com/v7/finance/quote?symbols=XAUUSD=X' 2>/dev/null | tr -d '\0' || true)"
      price="$(jq -r '.quoteResponse.result[0].regularMarketPrice' <<<"$j" 2>/dev/null || true)"
      validate_price "$price" || price=""
      ;;
    goldprice)
      local j; j="$(curl "${curl_opts[@]}" 'https://data-asg.goldprice.org/dbXRates/USD' 2>/dev/null | tr -d '\0' || true)"
      price="$(jq -r '.items[0].xauPrice' <<<"$j" 2>/dev/null || true)"
      validate_price "$price" || price=""
      ;;
  esac
  printf "%s" "${price:-}"
}

get_fx(){
  local try=""
  case "${FX_SOURCE:-exchangerate}" in
    exchangerate)
      local j; j="$(curl "${curl_opts[@]}" 'https://api.exchangerate.host/latest?base=USD&symbols=TRY' 2>/dev/null | tr -d '\0' || true)"
      try="$(jq -r '.rates.TRY' <<<"$j" 2>/dev/null || true)"
      validate_price "$try" || try=""
      ;;
    tcmb)
      local xml; xml="$(curl "${curl_opts[@]}" 'https://www.tcmb.gov.tr/kurlar/today.xml' 2>/dev/null | tr -d '\0' || true)"
      try="$(grep -A3 -i '<Currency Kod="USD"' <<<"$xml" | grep -E 'ForexSelling|BanknoteSelling' | head -n1 | sed -E 's/.*>([0-9.,]+)<.*/\1/' | tr ',' '.')"
      ;;
  esac
  printf "%s" "${try:-}"
}