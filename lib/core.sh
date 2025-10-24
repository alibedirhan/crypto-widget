#!/usr/bin/env bash
set -euo pipefail

NC="\033[0m"; BOLD="\033[1m"
CYAN="\033[36m"; MAG="\033[35m"; YEL="\033[33m"; GRN="\033[32m"; RED="\033[31m"
say(){ printf "${GRN}[+]${NC} %s\n" "$*"; }
warn(){ printf "${YEL}[!]${NC} %s\n" "$*"; }
err(){ printf "${RED}[x]${NC} %s\n" "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

ensure_deps(){
  say "Bağımlılıklar kontrol (curl jq gawk libnotify-bin dconf gnome-extensions)..."
  if have apt; then
    sudo apt update -y >/dev/null 2>&1 || true
    sudo apt install -y curl jq gawk libnotify-bin dconf-cli >/dev/null 2>&1 || true
  fi
  for b in curl jq awk dconf; do have "$b" || { err "Eksik: $b"; exit 1; }; done
}

APP_ID="cal-ticker-v3"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_HOME="$DATA_HOME/$APP_ID"
BIN_HOME="$HOME/.local/bin"
CONF_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cal-ticker-v3.conf"
CACHE_DIR="$HOME/.cache/$APP_ID"
LOG_DIR="$DATA_HOME/$APP_ID"
LOG_FILE="$LOG_DIR/log.txt"

DCONF_BASE="/org/gnome/shell/extensions/desktop-widgets"
W_KEY="widgets/cal-ticker"
E_KEY="$W_KEY/elements/command"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="cal-ticker.service"
TIMER_NAME="cal-ticker.timer"

WRAP_UPDATE="$BIN_HOME/cal-ticker-update"
WRAP_SHOW="$BIN_HOME/cal-ticker-show"
WRAP_MENU="$BIN_HOME/cal-ticker"

mkdir -p "$APP_HOME" "$CACHE_DIR" "$LOG_DIR" "$BIN_HOME" "$SYSTEMD_USER_DIR"
