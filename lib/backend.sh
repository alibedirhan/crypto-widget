#!/usr/bin/env bash
set -euo pipefail

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

CONKY_CFG="$HOME/.config/conky/cal-ticker.conf"
CONKY_AUTOSTART="$HOME/.config/autostart/cal-ticker-conky.desktop"

conky_write_config() {
  config_load 2>/dev/null || true
  
  local pos="${POSITION:-top_right}"
  local font="${FONT_FAMILY:-Noto Sans Mono}"
  local size="${FONT_SIZE:-18}"
  local x="${OFFSET_X:-16}"
  local y="${OFFSET_Y:-40}"
  local opac="${PANEL_OPACITY:-40}"
  local bg_color="${PANEL_COLOR:-000000}"
  local text_color="${TEXT_COLOR:-ffffff}"
  
  local alignment=""
  case "$pos" in
    top_left) alignment="top_left" ;;
    top_center) alignment="top_middle" ;;
    top_right) alignment="top_right" ;;
    middle_left) alignment="middle_left" ;;
    center) alignment="middle_middle" ;;
    middle_right) alignment="middle_right" ;;
    bottom_left) alignment="bottom_left" ;;
    bottom_center) alignment="bottom_middle" ;;
    bottom_right) alignment="bottom_right" ;;
    *) alignment="top_right" ;;
  esac
  
  mkdir -p "$(dirname "$CONKY_CFG")"
  cat > "$CONKY_CFG" <<EOF
conky.config = {
  update_interval = 3,
  double_buffer = true,

  own_window = true,
  own_window_type = 'dock',
  own_window_argb_visual = true,
  own_window_argb_value = ${opac},
  own_window_colour = '${bg_color}',
  own_window_hints = 'undecorated,sticky,skip_taskbar,skip_pager,below',

  alignment = '${alignment}',
  gap_x = ${x},
  gap_y = ${y},

  use_xft = true,
  xftalpha = 1.0,
  font = '${font}:size=${size}',
  draw_shades = false,
  draw_outline = false,
  default_color = '${text_color}',
  no_buffers = true,
  uppercase = false,

  minimum_width = 220, minimum_height = 60,
};

conky.text = [[
\${execpi 3 bash -lc 'cal-ticker-show | sed -n "1,4p"'}
\${execi 3 date -r \$HOME/.cache/cal-ticker-v3/render.txt "+Güncellendi:  %H:%M:%S"}
]];
EOF
}

conky_restart() {
  pkill -xf "conky -c $CONKY_CFG" 2>/dev/null || true
  nohup conky -c "$CONKY_CFG" >/dev/null 2>&1 &
  say "Conky yeniden başlatıldı."
}

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

backend_use_conky() {
  conky_pkg_install
  conky_write_config
  conky_autostart_enable
  conky_restart

  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions disable azclock@azclock.gitlab.com 2>/dev/null || true
  fi
  say "Backend: Conky etkin."
}

backend_use_extension() {
  pkill -xf "conky -c $CONKY_CFG" 2>/dev/null || true
  conky_autostart_disable

  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions enable azclock@azclock.gitlab.com 2>/dev/null || true
  fi
  if declare -F widget_apply_minimal >/dev/null 2>&1; then
    widget_apply_minimal
  else
    warn "widget_apply_minimal bulunamadı; lib/widget.sh yüklü mü?"
  fi
  say "Backend: GNOME Extension etkin."
}
