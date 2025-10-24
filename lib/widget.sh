#!/usr/bin/env bash
set -euo pipefail

find_uuid(){
  local uuid=""
  if command -v gnome-extensions >/dev/null 2>&1; then
    for id in $(gnome-extensions list 2>/dev/null || true); do
      case "$id" in *desktop*widget*|*desktop*clock*|*azclock*) uuid="$id"; break;; esac
    done
  fi
  echo "$uuid"
}

enable_extension_if_present(){
  local uuid; uuid="$(find_uuid)"
  if [[ -n "$uuid" ]]; then
    gnome-extensions enable "$uuid" 2>/dev/null || true
    say "Uzantı etkin: $uuid"
  else
    warn "Desktop Widgets uzantısı bulunamadı. (Yüklü olmalı; script dconf ile ayarı basar.)"
  fi
}

# Default minimal (sağ-üst, şeffaf, küçük) + cache komutu
widget_apply_minimal(){
  enable_extension_if_present

  local DEF_ANCHOR="'Top Right'"
  local DEF_PADDING=6
  local DEF_BG=false
  local DEF_OPAC="'0.0'"
  local DEF_FONT="'Ubuntu Mono'"
  local DEF_SIZE=18
  local DEF_INTERVAL=5000  # ms

  dset "$W_KEY/enabled" "true"
  dset "$W_KEY/anchor-point" "$DEF_ANCHOR"
  dset "$W_KEY/spacing" "$DEF_PADDING"
  dset "$W_KEY/vertical-layout" "true"
  dset "$W_KEY/enable-background" "$DEF_BG"
  dset "$W_KEY/background-opacity" "$DEF_OPAC"

  dset "$E_KEY/type" "'command'"
  dset "$E_KEY/enabled" "true"
  dset "$E_KEY/command" "'$WRAP_SHOW'"
  dset "$E_KEY/interval" "$DEF_INTERVAL"
  dset "$E_KEY/use-markup" "true"
  dset "$E_KEY/line-alignment" "'Left'"
  dset "$E_KEY/font-family" "$DEF_FONT"
  dset "$E_KEY/font-size" "$DEF_SIZE"

  say "Widget (minimal, sağ-üst, şeffaf, küçük) ve cache komutu uygulandı."
}

timer_enable(){
  cat > "$SYSTEMD_USER_DIR/$SERVICE_NAME" <<EOF
[Unit]
Description=CAL Ticker v3 updater (user) - writes cache
[Service]
Type=oneshot
ExecStart=$WRAP_UPDATE
EOF
  cat > "$SYSTEMD_USER_DIR/$TIMER_NAME" <<EOF
[Unit]
Description=CAL Ticker v3 updater timer (user)
[Timer]
OnBootSec=10s
OnUnitActiveSec=15s
AccuracySec=1s
Unit=$SERVICE_NAME
[Install]
WantedBy=timers.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now "$TIMER_NAME"
  say "Timer etkin (15s)."
}

timer_disable(){
  systemctl --user disable --now "$TIMER_NAME" 2>/dev/null || true
  rm -f "$SYSTEMD_USER_DIR/$TIMER_NAME" "$SYSTEMD_USER_DIR/$SERVICE_NAME"
  systemctl --user daemon-reload
  say "Timer kapatıldı ve temizlendi."
}

widget_uninstall(){
  dconf reset -f "$DCONF_BASE/$E_KEY/" 2>/dev/null || true
  dconf reset -f "$DCONF_BASE/$W_KEY/" 2>/dev/null || true
  say "Widget dconf profili temizlendi."
}
