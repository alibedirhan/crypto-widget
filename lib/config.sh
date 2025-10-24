#!/usr/bin/env bash
set -euo pipefail

# Senin default'ların
config_ensure(){
  [[ -f "$CONF_FILE" ]] && return 0
  cat > "$CONF_FILE" <<EOF
# === ${APP_ID} Config ===
CRYPTO_SOURCE=binance
GOLD_SOURCE=yahoo
FX_SOURCE=exchangerate
SHOW_TRY=1
USE_PANGO=1
SHOW_SPARKLINE=1
SPARK_POINTS=40
LOG_ENABLE=1
XAU_TTL=300
FX_TTL=600
ALERT_BTC_ABOVE=
ALERT_BTC_BELOW=
ALERT_ETH_ABOVE=
ALERT_ETH_BELOW=
EOF
  say "Varsayılan config yazıldı: $CONF_FILE"
}

config_load(){
  config_ensure
  # shellcheck disable=SC1090
  source "$CONF_FILE"
  : "${CRYPTO_SOURCE:=binance}" "${GOLD_SOURCE:=yahoo}" "${FX_SOURCE:=exchangerate}"
  : "${SHOW_TRY:=1}" "${USE_PANGO:=1}"
  : "${SHOW_SPARKLINE:=1}" "${SPARK_POINTS:=40}" "${LOG_ENABLE:=1}"
  : "${XAU_TTL:=300}" "${FX_TTL:=600}"
}

config_edit_thresholds(){
  echo "Mevcut eşikler:"; grep -E '^ALERT_' "$CONF_FILE" || true
  read -rp "ALERT_BTC_ABOVE: " a1
  read -rp "ALERT_BTC_BELOW: " a2
  read -rp "ALERT_ETH_ABOVE: " a3
  read -rp "ALERT_ETH_BELOW: " a4
  for k in ALERT_BTC_ABOVE ALERT_BTC_BELOW ALERT_ETH_ABOVE ALERT_ETH_BELOW; do
    grep -q "^$k=" "$CONF_FILE" || echo "$k=" >> "$CONF_FILE"
  done
  [[ -n "${a1:-}" ]] && sed -i "s|^ALERT_BTC_ABOVE=.*|ALERT_BTC_ABOVE=$a1|" "$CONF_FILE"
  [[ -n "${a2:-}" ]] && sed -i "s|^ALERT_BTC_BELOW=.*|ALERT_BTC_BELOW=$a2|" "$CONF_FILE"
  [[ -n "${a3:-}" ]] && sed -i "s|^ALERT_ETH_ABOVE=.*|ALERT_ETH_ABOVE=$a3|" "$CONF_FILE"
  [[ -n "${a4:-}" ]] && sed -i "s|^ALERT_ETH_BELOW=.*|ALERT_ETH_BELOW=$a4|" "$CONF_FILE"
  say "Eşikler güncellendi."
}

config_edit_sources(){
  echo "Kaynaklar (mevcut):"; grep -E '^(CRYPTO_SOURCE|GOLD_SOURCE|FX_SOURCE)=' "$CONF_FILE" || true
  echo "Kripto: 1) binance 2) coingecko 3) coinbase"
  read -rp "Seçim [1]: " c; c="${c:-1}"
  case "$c" in 1) cs=binance;; 2) cs=coingecko;; 3) cs=coinbase;; *) cs=binance;; esac
  echo "Altın: 1) yahoo 2) goldprice"
  read -rp "Seçim [1]: " g; g="${g:-1}"
  case "$g" in 1) gs=yahoo;; 2) gs=goldprice;; *) gs=yahoo;; esac
  echo "Kur: 1) exchangerate 2) tcmb"
  read -rp "Seçim [1]: " f; f="${f:-1}"
  case "$f" in 1) fs=exchangerate;; 2) fs=tcmb;; *) fs=exchangerate;; esac
  sed -i "s|^CRYPTO_SOURCE=.*|CRYPTO_SOURCE=$cs|" "$CONF_FILE"
  sed -i "s|^GOLD_SOURCE=.*|GOLD_SOURCE=$gs|" "$CONF_FILE"
  sed -i "s|^FX_SOURCE=.*|FX_SOURCE=$fs|" "$CONF_FILE"
  say "Kaynaklar güncellendi: $cs / $gs / $fs"
}
