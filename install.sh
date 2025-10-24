#!/usr/bin/env bash
set -euo pipefail

# Proje kökü (bu dosyanın bulunduğu dizin)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="cal-ticker-v3"
APP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/$APP_ID"

# Uygulama dosyalarını kullanıcı alanına kopyala
mkdir -p "$APP_HOME"
cp -a "$ROOT_DIR/"* "$APP_HOME/"

# Çalıştırma izinleri
chmod +x "$APP_HOME"/*.sh "$APP_HOME"/lib/*.sh

# Kurulum akışı
bash -lc "
  set -euo pipefail

  source '$APP_HOME/lib/core.sh'
  source '$APP_HOME/lib/utils.sh'
  source '$APP_HOME/lib/config.sh'
  source '$APP_HOME/lib/api.sh'
  source '$APP_HOME/lib/cache.sh'
  source '$APP_HOME/lib/widget.sh'
  source '$APP_HOME/lib/backend.sh'

  # Bağımlılıklar
  ensure_deps

  # Konfigürasyon var/yok
  config_ensure

  # Varsayılanları Conky backend'e uygun hale getir:
  # - PANGO kapalı (Conky düz metin okur)
  # - Altın kaynağı goldprice
  # - Sparkline açık
  sed -i 's/^USE_PANGO=.*/USE_PANGO=0/' \"\$CONF_FILE\" || true
  sed -i 's/^GOLD_SOURCE=.*/GOLD_SOURCE=goldprice/' \"\$CONF_FILE\" || true
  sed -i 's/^SHOW_SPARKLINE=.*/SHOW_SPARKLINE=1/' \"\$CONF_FILE\" || true

  # Wrapper komutları (~/.local/bin) oluştur
  mkdir -p \"\$HOME/.local/bin\"
  WRAP_MENU=\"\$HOME/.local/bin/cal-ticker\"
  WRAP_UPDATE=\"\$HOME/.local/bin/cal-ticker-update\"
  WRAP_SHOW=\"\$HOME/.local/bin/cal-ticker-show\"

  cat > \"\$WRAP_MENU\" <<E1
#!/usr/bin/env bash
bash \"$APP_HOME/ticker.sh\" \"\$@\"
E1
  chmod +x \"\$WRAP_MENU\"

  cat > \"\$WRAP_UPDATE\" <<E2
#!/usr/bin/env bash
bash \"$APP_HOME/ticker.sh\" --update-once
E2
  chmod +x \"\$WRAP_UPDATE\"

  cat > \"\$WRAP_SHOW\" <<'E3'
#!/usr/bin/env bash
set -euo pipefail
FILE=\"$HOME/.cache/cal-ticker-v3/render.txt\"
if [[ -s \"\$FILE\" ]]; then sed -n '1,10p' \"\$FILE\"; else echo -e \"BTC  : —\nETH  : —\nGOLD : —\"; fi
E3
  chmod +x \"\$WRAP_SHOW\"

  # İlk cache için XAU/FX cache temizle ve render üret
  rm -f \"\$CACHE_DIR/xau.txt\" \"\$CACHE_DIR/usdtry.txt\" 2>/dev/null || true
  render_once || true

  # Varsayılan backend: Conky (yarı saydam panel + sparkline + 'Güncellendi' satırı)
  backend_use_conky

  # systemd user timer (15s) etkinleştir
  timer_enable
"

echo
echo "[+] Kurulum tamam. Menü için:  cal-ticker"
echo "    (Conky backend • sağ-üst • yarı saydam panel • sparkline • 15s timer)"
# Kullanıcıyı menüye sokmak istersen aç:
"$APP_HOME/ticker.sh"
