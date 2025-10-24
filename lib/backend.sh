#!/usr/bin/env bash
set -euo pipefail

# Bu dosya Conky ve GNOME Extension backend geçişini yönetir.
# utils.sh içindeki say()/warn() fonksiyonları yüklü varsayılmıştır.

# Conky kurulum kontrolü
conky_pkg_install() {
  if ! command -v conky >/dev/null 2>&1; then
    say "Conky kuruluyor..."
    if command -v apt >/dev/null 2>&1; then
      sudo apt update -y >/dev/null 2>&1 || true
      sudo apt install -y conky-all >/dev/null 2>&1 || true
    else
      warn "apt bulunamadı; Conky'yi manuel kurmanız gerekebilir."
    fi
  fi
}

# Yollar
CONKY_CFG="$HOME/.config/conky/cal-ticker.conf"
CONKY_AUTOSTART="$HOME/.config/autostart/cal-ticker-conky.desktop"

# Conky yapılandırması (sparkline + 'Güncellendi' satırı + yarı saydam panel)
conky_write_config() {
  mkdir -p "$(dirname "$CONKY_CFG")"
  cat > "$CONKY_CFG" <<'EOF'
conky.config = {
  update_interval = 3,
  double_buffer = true,

  own_window = true,
  own_window_type = 'dock',
  own_window_argb_visual = true,
  own_window_argb_value = 40,        -- 0=tam şeffaf, 30-50: hafif panel
  own_window_colour = '000000',
  own_window_hints = 'undecorated,sticky,skip_taskbar,skip_pager,below',

  alignment = 'top_right',
  gap_x = 16,
  gap_y = 40,

  use_xft = true,
  xftalpha = 1.0,
  font = 'Noto Sans Mono:size=18',
  draw_shades = false,
  draw_outline = false,
  default_color = 'white',
  no_buffers = true,
  uppercase = false,

  minimum_width = 220, minimum_height = 60,
};

-- Düz metin (PANGO kapalı). İlk 4 satır: BTC/ETH/GOLD + BTC 24h sparkline
conky.text = [[
${execpi 3 bash -lc 'cal-ticker-show | sed -n "1,4p"'}
${execi 3 date -r $HOME/.cache/cal-ticker-v3/render.txt "+Güncellendi:  %H:%M:%S"}
]];
EOF
}

# Conky yeniden başlat
conky_restart() {
  pkill -xf "conky -c $CONKY_CFG" 2>/dev/null || true
  nohup conky -c "$CONKY_CFG" >/dev/null 2>&1 &
  say "Conky yeniden başlatıldı."
}

# Otomatik başlatma
conky_autostart_enable() {
  mkdir -p "$(dirname "$CONKY_AUTOSTART")"
  cat > "$CONKY_AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=CAL Ticker (Conky)
Exec=conky -c $CONKY_CFG
X-GNOME-Autostart-enabled=true
EOF
  say "Conky autostart etkin."
}

conky_autostart_disable() {
  rm -f "$CONKY_AUTOSTART"
  say "Conky autostart kapatıldı."
}

# Varsayılan backend: Conky
backend_use_conky() {
  conky_pkg_install
  conky_write_config
  conky_autostart_enable
  conky_restart

  # GNOME Desktop Widgets uzantısını çakışma olmasın diye kapatalım (menüden tekrar açılabilir)
  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions disable azclock@azclock.gitlab.com 2>/dev/null || true
  fi
  say "Backend: Conky etkin."
}

# Alternatif backend: GNOME Extension (Desktop Widgets)
backend_use_extension() {
  # Conky'yi kapat + autostart'ı devre dışı bırak
  pkill -xf "conky -c $CONKY_CFG" 2>/dev/null || true
  conky_autostart_disable

  # Uzantıyı aç ve minimal widget profilini uygula
  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions enable azclock@azclock.gitlab.com 2>/dev/null || true
  fi
  # widget_apply_minimal() lib/widget.sh içinde
  if declare -F widget_apply_minimal >/dev/null 2>&1; then
    widget_apply_minimal
  else
    warn "widget_apply_minimal bulunamadı; lib/widget.sh yüklü mü?"
  fi
  say "Backend: GNOME Extension etkin."
}
