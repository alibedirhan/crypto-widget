#!/usr/bin/env bash
set -euo pipefail

APP_ID="cal-ticker-v3"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_HOME="$DATA_HOME/$APP_ID"
BIN_HOME="$HOME/.local/bin"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="cal-ticker.service"
TIMER_NAME="cal-ticker.timer"

DCONF_BASE="/org/gnome/shell/extensions/desktop-widgets"
W_KEY="widgets/cal-ticker"
E_KEY="$W_KEY/elements/command"

CONF_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cal-ticker-v3.conf"
CACHE_DIR="$HOME/.cache/$APP_ID"
LOG_DIR="$DATA_HOME/$APP_ID"

CONKY_CONFIG="$HOME/.config/conky/cal-ticker.conf"
CONKY_AUTOSTART="$HOME/.config/autostart/cal-ticker-conky.desktop"

say(){ printf "\033[32m[*]\033[0m %s\n" "$*"; }

systemctl --user disable --now "$TIMER_NAME" 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/$TIMER_NAME" "$SYSTEMD_USER_DIR/$SERVICE_NAME"
systemctl --user daemon-reload || true

pkill -xf "conky -c $CONKY_CONFIG" 2>/dev/null || true
rm -f "$CONKY_CONFIG" "$CONKY_AUTOSTART"

dconf reset -f "$DCONF_BASE/$E_KEY/" 2>/dev/null || true
dconf reset -f "$DCONF_BASE/$W_KEY/" 2>/dev/null || true

rm -f "$BIN_HOME/cal-ticker" "$BIN_HOME/cal-ticker-update" "$BIN_HOME/cal-ticker-show"

rm -rf "$APP_HOME" "$CACHE_DIR" "$LOG_DIR"
rm -f "$CONF_FILE"

say "CAL Ticker v3 tamamen kaldırıldı (iz bırakmadan)."
