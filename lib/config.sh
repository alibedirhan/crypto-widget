#!/usr/bin/env bash
set -euo pipefail

config_migrate(){
  # Eski config dosyalarını güncelle (eksik değişkenleri ekle)
  local updated=0
  
  # Kontrol edilecek değişkenler (key:default_value formatında)
  local required_vars=(
    "POSITION:top_right"
    "FONT_FAMILY:Noto Sans Mono"
    "FONT_SIZE:18"
    "OFFSET_X:16"
    "OFFSET_Y:40"
    "PANEL_COLOR:000000"
    "TEXT_COLOR:ffffff"
  )
  
  for item in "${required_vars[@]}"; do
    local key="${item%%:*}"
    local default_val="${item#*:}"
    
    # Değişken yoksa ekle
    if ! grep -q "^${key}=" "$CONF_FILE" 2>/dev/null; then
      echo "${key}=${default_val}" >> "$CONF_FILE"
      updated=1
    fi
  done
  
  if (( updated )); then
    say "Config güncellendi (v3.1 değişkenleri eklendi)"
  fi
}

config_ensure(){
  if [[ ! -f "$CONF_FILE" ]]; then
    # Yeni config oluştur
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
ALERT_COOLDOWN=300
POSITION=top_right
FONT_FAMILY=Noto Sans Mono
FONT_SIZE=18
OFFSET_X=16
OFFSET_Y=40
PANEL_COLOR=000000
TEXT_COLOR=ffffff
EOF
    say "Varsayılan config yazıldı: $CONF_FILE"
  else
    # Mevcut config'i kontrol et ve eksik değişkenleri ekle
    config_migrate
  fi
}

config_load(){
  config_ensure
  
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    
    value="${value%%#*}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    
    case "$key" in
      CRYPTO_SOURCE|GOLD_SOURCE|FX_SOURCE|SHOW_TRY|USE_PANGO|SHOW_SPARKLINE|\
      SPARK_POINTS|LOG_ENABLE|XAU_TTL|FX_TTL|ALERT_BTC_ABOVE|ALERT_BTC_BELOW|\
      ALERT_ETH_ABOVE|ALERT_ETH_BELOW|ALERT_COOLDOWN|\
      POSITION|FONT_FAMILY|FONT_SIZE|OFFSET_X|OFFSET_Y|PANEL_COLOR|TEXT_COLOR)
        export "$key=$value"
        ;;
    esac
  done < "$CONF_FILE"
  
  : "${CRYPTO_SOURCE:=binance}" "${GOLD_SOURCE:=yahoo}" "${FX_SOURCE:=exchangerate}"
  : "${SHOW_TRY:=1}" "${USE_PANGO:=1}"
  : "${SHOW_SPARKLINE:=1}" "${SPARK_POINTS:=40}" "${LOG_ENABLE:=1}"
  : "${XAU_TTL:=300}" "${FX_TTL:=600}"
  : "${ALERT_COOLDOWN:=300}"
  : "${POSITION:=top_right}" "${FONT_FAMILY:=Noto Sans Mono}" "${FONT_SIZE:=18}"
  : "${OFFSET_X:=16}" "${OFFSET_Y:=40}"
  : "${PANEL_COLOR:=000000}" "${TEXT_COLOR:=ffffff}"
}

config_edit_thresholds(){
  echo "Mevcut eşikler:"; grep -E '^ALERT_' "$CONF_FILE" || true
  echo
  read -rp "ALERT_BTC_ABOVE: " a1
  read -rp "ALERT_BTC_BELOW: " a2
  read -rp "ALERT_ETH_ABOVE: " a3
  read -rp "ALERT_ETH_BELOW: " a4
  
  echo
  echo "Bildirim aralığı:"
  echo "  [1] 10 saniye"
  echo "  [2] 30 saniye"
  echo "  [3] 1 dakika"
  echo "  [4] 5 dakika (önerilen)"
  echo "  [5] 10 dakika"
  echo "  [6] 1 saat"
  echo "  [7] Devre dışı"
  echo "  [8] Özel"
  read -rp "Seçim [4]: " cooldown_choice
  cooldown_choice="${cooldown_choice:-4}"
  
  local cooldown_val=300
  case "$cooldown_choice" in
    1) cooldown_val=10 ;;
    2) cooldown_val=30 ;;
    3) cooldown_val=60 ;;
    4) cooldown_val=300 ;;
    5) cooldown_val=600 ;;
    6) cooldown_val=3600 ;;
    7) cooldown_val=0 ;;
    8) 
      read -rp "Saniye cinsinden girin: " custom_val
      if [[ "$custom_val" =~ ^[0-9]+$ ]]; then
        cooldown_val="$custom_val"
      else
        echo "Geçersiz değer, varsayılan 300 kullanılıyor."
        cooldown_val=300
      fi
      ;;
    *)
      echo "Geçersiz seçim, varsayılan 300 kullanılıyor."
      cooldown_val=300
      ;;
  esac
  
  for k in ALERT_BTC_ABOVE ALERT_BTC_BELOW ALERT_ETH_ABOVE ALERT_ETH_BELOW ALERT_COOLDOWN; do
    grep -q "^$k=" "$CONF_FILE" || echo "$k=" >> "$CONF_FILE"
  done
  
  [[ -n "${a1:-}" ]] && sed -i "s|^ALERT_BTC_ABOVE=.*|ALERT_BTC_ABOVE=$a1|" "$CONF_FILE"
  [[ -n "${a2:-}" ]] && sed -i "s|^ALERT_BTC_BELOW=.*|ALERT_BTC_BELOW=$a2|" "$CONF_FILE"
  [[ -n "${a3:-}" ]] && sed -i "s|^ALERT_ETH_ABOVE=.*|ALERT_ETH_ABOVE=$a3|" "$CONF_FILE"
  [[ -n "${a4:-}" ]] && sed -i "s|^ALERT_ETH_BELOW=.*|ALERT_ETH_BELOW=$a4|" "$CONF_FILE"
  sed -i "s|^ALERT_COOLDOWN=.*|ALERT_COOLDOWN=$cooldown_val|" "$CONF_FILE"
  
  say "Eşikler ve bildirim aralığı güncellendi."
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