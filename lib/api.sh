#!/usr/bin/env bash
set -euo pipefail

curl_opts=(--silent --show-error --max-time 5 --connect-timeout 2 --retry 2 --retry-delay 1 \
  -H 'User-Agent: Mozilla/5.0' -H 'Cache-Control: no-cache' -H 'Pragma: no-cache')

get_crypto(){ # $1: BTC|ETH -> last|pct
  local sym="$1" last="" pct=""
  case "${CRYPTO_SOURCE:-binance}" in
    binance)
      local j; j="$(curl "${curl_opts[@]}" "https://data-api.binance.vision/api/v3/ticker/24hr?symbol=${sym}USDT" || true)"
      last="$(jq -r '.lastPrice' <<<"$j" 2>/dev/null || true)"
      pct="$(jq -r '.priceChangePercent' <<<"$j" 2>/dev/null || true)"
      ;;
    coingecko)
      local id="bitcoin"; [[ "$sym" == "ETH" ]] && id="ethereum"
      local j; j="$(curl "${curl_opts[@]}" "https://api.coingecko.com/api/v3/simple/price?ids=${id}&vs_currencies=usd&include_24hr_change=true" || true)"
      last="$(jq -r ".\"$id\".usd" <<<"$j" 2>/dev/null || true)"
      pct="$(jq -r ".\"$id\".usd_24h_change" <<<"$j" 2>/dev/null || true)"
      ;;
    coinbase)
      local j; j="$(curl "${curl_opts[@]}" "https://api.coinbase.com/v2/prices/${sym}-USD/spot" || true)"
      last="$(jq -r '.data.amount' <<<"$j" 2>/dev/null || true)"
      pct=""
      ;;
  esac
  printf "%s|%s" "${last:-}" "${pct:-}"
}

get_gold(){
  local price=""
  case "${GOLD_SOURCE:-yahoo}" in
    yahoo)
      local j; j="$(curl "${curl_opts[@]}" 'https://query1.finance.yahoo.com/v7/finance/quote?symbols=XAUUSD=X' || true)"
      price="$(jq -r '.quoteResponse.result[0].regularMarketPrice' <<<"$j" 2>/dev/null || true)"
      ;;
    goldprice)
      local j; j="$(curl "${curl_opts[@]}" 'https://data-asg.goldprice.org/dbXRates/USD' || true)"
      price="$(jq -r '.items[0].xauPrice' <<<"$j" 2>/dev/null || true)"
      ;;
  esac
  printf "%s" "${price:-}"
}

get_fx(){
  local try=""
  case "${FX_SOURCE:-exchangerate}" in
    exchangerate)
      local j; j="$(curl "${curl_opts[@]}" 'https://api.exchangerate.host/latest?base=USD&symbols=TRY' || true)"
      try="$(jq -r '.rates.TRY' <<<"$j" 2>/dev/null || true)"
      ;;
    tcmb)
      local xml; xml="$(curl "${curl_opts[@]}" 'https://www.tcmb.gov.tr/kurlar/today.xml' || true)"
      try="$(grep -A3 -i '<Currency Kod="USD"' <<<"$xml" | grep -E 'ForexSelling|BanknoteSelling' | head -n1 | sed -E 's/.*>([0-9.,]+)<.*/\1/' | tr ',' '.')"
      ;;
  esac
  printf "%s" "${try:-}"
}
