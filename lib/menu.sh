#!/usr/bin/env bash
set -euo pipefail

# core.sh / utils.sh fonksiyonları varsayılır: say, warn, have, ensure_deps, etc.
# config.sh fonksiyonları varsayılır: config_ensure, config_load, config_edit_thresholds, config_edit_sources
# cache.sh: render_once
# widget.sh: widget_uninstall, timer_enable, timer_disable, TIMER_NAME
# backend.sh: backend_use_conky, backend_use_extension

banner(){
  clear
  echo -e "${BOLD}${CYAN}"
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                        CAL Desktop Ticker v3                  ║
║                GNOME Desktop / Conky • Cache Mode             ║
╚═══════════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

# Wrapper'ları güvence altına al (install.sh de yazar; burada eksikse tamamlarız)
make_wrappers(){
  mkdir -p "$HOME/.local/bin"
  WRAP_MENU="$HOME/.local/bin/cal-ticker"
  WRAP_UPDATE="$HOME/.local/bin/cal-ticker-update"
  WRAP_SHOW="$HOME/.local/bin/cal-ticker-show"

  if [[ ! -x "$WRAP_MENU" ]]; then
    cat > "$WRAP_MENU" <<EOF
#!/usr/bin/env bash
bash "$APP_HOME/ticker.sh" "\$@"
EOF
    chmod +x "$WRAP_MENU"
  fi

  if [[ ! -x "$WRAP_UPDATE" ]]; then
    cat > "$WRAP_UPDATE" <<EOF
#!/usr/bin/env bash
bash "$APP_HOME/ticker.sh" --update-once
EOF
    chmod +x "$WRAP_UPDATE"
  fi

  if [[ ! -x "$WRAP_SHOW" ]]; then
    cat > "$WRAP_SHOW" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
FILE="$HOME/.cache/cal-ticker-v3/render.txt"
if [[ -s "$FILE" ]]; then sed -n '1,10p' "$FILE"; else echo -e "BTC  : —\nETH  : —\nGOLD : —"; fi
EOF
    chmod +x "$WRAP_SHOW"
  fi
}

verify_report(){
  say "Bağımlılık kontrolü…"; for b in curl jq awk dconf; do have "$b" && say "OK: $b" || warn "Eksik: $b"; done
  if systemctl --user is-enabled "$TIMER_NAME" &>/dev/null; then say "Timer ENABLED"; else warn "Timer disabled"; fi
  if [[ -s "$CACHE_DIR/render.txt" ]]; then
    say "Cache hazır: $CACHE_DIR/render.txt"
    sed -n '1,8p' "$CACHE_DIR/render.txt"
  else
    warn "Cache boş"
  fi
}

uninstall_all(){
  timer_disable
  widget_uninstall
  # Conky kapat + autostart temizle
  pkill -f "conky -c $HOME/.config/conky/cal-ticker.conf" 2>/dev/null || true
  rm -f "$HOME/.config/autostart/cal-ticker-conky.desktop" 2>/dev/null || true
  rm -f "$HOME/.config/conky/cal-ticker.conf" 2>/dev/null || true

  # Wrapperlar + uygulama + durum dosyaları
  rm -f "$HOME/.local/bin/cal-ticker" "$HOME/.local/bin/cal-ticker-update" "$HOME/.local/bin/cal-ticker-show"
  rm -rf "$APP_HOME" "$CACHE_DIR" "$LOG_DIR"
  rm -f "$CONF_FILE"
  say "Uygulama, config, cache, log, wrapperlar tamamen silindi."
}

# -----------------------------
# YENİ: Güncelleme Aralığı Menüsü
# -----------------------------
_timer_file(){ echo "$HOME/.config/systemd/user/cal-ticker.timer"; }
_conky_cfg(){ echo "$HOME/.config/conky/cal-ticker.conf"; }

_set_timer_interval(){
  local sec="$1"
  local t="$(_timer_file)"
  if [[ -f "$t" ]]; then
    sed -i "s/^OnUnitActiveSec=.*/OnUnitActiveSec=${sec}s/" "$t"
    systemctl --user daemon-reload
    systemctl --user restart cal-ticker.timer
    say "Timer aralığı ${sec}s oldu."
  else
    warn "Timer dosyası yok: $t"
  fi
}

_set_conky_interval_for(){
  # sec >=60 → 10; >=30 → 5; aksi → 3
  local sec="$1" ref=3
  (( sec >= 60 )) && ref=10
  (( sec >= 30 && sec < 60 )) && ref=5
  local c="$(_conky_cfg)"
  if [[ -f "$c" ]]; then
    sed -i "s/update_interval = [0-9]\+,/update_interval = ${ref},/" "$c"
    sed -i "s/execpi [0-9]\+/execpi ${ref}/" "$c"
    pkill -xf "conky -c $c" 2>/dev/null || true
    nohup conky -c "$c" >/dev/null 2>&1 &
    say "Conky okuma periyodu ≈${ref}s olarak ayarlandı."
  fi
}

menu_set_interval(){
  echo
  echo "Güncelleme aralığı: 1) 15 sn  2) 30 sn  3) 60 sn  4) Özel"
  read -rp "Seçim: " k
  local sec=15
  case "$k" in
    1|"") sec=15 ;;
    2) sec=30 ;;
    3) sec=60 ;;
    4) read -rp "Saniye: " sec; [[ "$sec" =~ ^[0-9]+$ ]] || { warn "Geçersiz"; return; } ;;
    *) warn "Geçersiz"; return ;;
  esac
  _set_timer_interval "$sec"
  _set_conky_interval_for "$sec"
  say "Aralık güncellendi."
}

# -----------------------------
# YENİ: Görsel Seçenekler Menüsü
# -----------------------------
_conky_has_updated_line(){
  grep -q 'Güncellendi:' "$(_conky_cfg)" 2>/dev/null
}

_toggle_updated_line(){
  local onoff="$1" c="$(_conky_cfg)"
  [[ -f "$c" ]] || return 0
  if [[ "$onoff" == "1" ]]; then
    # yoksa ekle
    if ! _conky_has_updated_line; then
      # ]] öncesine ekle
      sed -i '/conky.text = \[\[/,/\]\];/ s/\]\];/\n${execi 3 date -r $HOME\/.cache\/cal-ticker-v3\/render.txt "+Güncellendi:  %H:%M:%S"}\n]];/' "$c"
    fi
  else
    # varsa kaldır
    sed -i '/Güncellendi:/d' "$c"
  fi
  pkill -xf "conky -c $c" 2>/dev/null || true
  nohup conky -c "$c" >/dev/null 2>&1 &
}

_set_conky_opacity(){
  local val="$1" c="$(_conky_cfg)"
  [[ -f "$c" ]] || return 0
  sed -i "s/own_window_argb_value = [0-9]\+,/own_window_argb_value = ${val},/" "$c"
  pkill -xf "conky -c $c" 2>/dev/null || true
  nohup conky -c "$c" >/dev/null 2>&1 &
}

_set_sparkline(){
  local onoff="$1" c="$(_conky_cfg)"
  # config’te anahtar
  sed -i "s/^SHOW_SPARKLINE=.*/SHOW_SPARKLINE=${onoff}/" "$CONF_FILE"
  # Conky’de 1..3p -> 1..4p geçişi
  if [[ -f "$c" ]]; then
    if [[ "$onoff" == "1" ]]; then
      sed -i 's/sed -n "1,3p"/sed -n "1,4p"/' "$c" 2>/dev/null || true
    else
      sed -i 's/sed -n "1,4p"/sed -n "1,3p"/' "$c" 2>/dev/null || true
      # Güncellendi satırı varsa aynı kalsın
    fi
    pkill -xf "conky -c $c" 2>/dev/null || true
    nohup conky -c "$c" >/dev/null 2>&1 &
  fi
}

_set_try(){
  local onoff="$1"
  sed -i "s/^SHOW_TRY=.*/SHOW_TRY=${onoff}/" "$CONF_FILE"
}

menu_visual_options(){
  config_load
  local cur_sp="${SHOW_SPARKLINE:-1}"
  local cur_try="${SHOW_TRY:-0}"
  local cur_upd=0
  _conky_has_updated_line && cur_upd=1
  local cur_opac="$(grep -oE 'own_window_argb_value = [0-9]+' "$(_conky_cfg)" 2>/dev/null | awk '{print $4}' || echo 40)"

  echo
  echo "Sparkline (1/0) [mevcut: $cur_sp]"; read -rp "> " sp; sp="${sp:-$cur_sp}"
  echo "TL karşılığı (1/0) [mevcut: $cur_try]"; read -rp "> " tr; tr="${tr:-$cur_try}"
  echo "Panel opaklık 0–255 (0 şeffaf) [mevcut: $cur_opac]"; read -rp "> " op; op="${op:-$cur_opac}"
  echo "'Güncellendi' satırı (1/0) [mevcut: $cur_upd]"; read -rp "> " up; up="${up:-$cur_upd}"

  [[ "$sp" =~ ^[01]$ ]] || { warn "Sparkline değeri geçersiz"; return; }
  [[ "$tr" =~ ^[01]$ ]] || { warn "TL değeri geçersiz"; return; }
  [[ "$op" =~ ^[0-9]+$ ]] || { warn "Opaklık geçersiz"; return; }
  [[ "$up" =~ ^[01]$ ]] || { warn "Güncellendi değeri geçersiz"; return; }

  _set_sparkline "$sp"
  _set_try "$tr"
  _set_conky_opacity "$op"
  _toggle_updated_line "$up"

  render_once || true
  say "Görsel seçenekler güncellendi."
}

menu_main(){
  ensure_deps
  config_ensure
  make_wrappers

  while :; do
    banner
    echo -e "${BOLD}${MAG}Seçenekler:${NC}"
    echo -e "  ${GRN}[1]${NC} Tam Kurulum (Conky • sağ-üst • yarı saydam • sparkline • timer)"
    echo -e "  ${GRN}[2]${NC} Eşik/Alarm Ayarla"
    echo -e "  ${GRN}[3]${NC} Kaynakları Seç (Kripto / Altın / Kur)"
    echo -e "  ${GRN}[4]${NC} Log Toggle (cache/log)"
    echo -e "  ${GRN}[5]${NC} Timer Aç/Kapat"
    echo -e "  ${GRN}[6]${NC} Şimdi Güncelle (cache render üret)"
    echo -e "  ${GRN}[7]${NC} Doğrula"
    echo -e "  ${GRN}[8]${NC} Kaldır (TAM SİL)"
    echo -e "  ${GRN}[9]${NC} Çıkış"
    echo -e "  ${GRN}[10]${NC} Backend: Conky / Extension"
    echo -e "  ${GRN}[11]${NC} Güncelleme Aralığı (15/30/60/Özel)"
    echo -e "  ${GRN}[12]${NC} Görsel Seçenekler (Sparkline/TL/Opaklık/Zaman)"
    echo
    read -rp "Seçiminiz: " ch
    case "$ch" in
      1)
        # Varsayılanları netleştir
        sed -i 's/^USE_PANGO=.*/USE_PANGO=0/' "$CONF_FILE" || true
        sed -i 's/^GOLD_SOURCE=.*/GOLD_SOURCE=goldprice/' "$CONF_FILE" || true
        sed -i 's/^SHOW_SPARKLINE=.*/SHOW_SPARKLINE=1/' "$CONF_FILE" || true
        # İlk render için kritik cache'leri temizle
        rm -f "$CACHE_DIR/xau.txt" "$CACHE_DIR/usdtry.txt" 2>/dev/null || true
        render_once || true
        backend_use_conky
        timer_enable
        say "Tam Kurulum tamamlandı (Conky)."
        read -rp "Devam..." _ ;;
      2) config_edit_thresholds; read -rp "Devam..." _ ;;
      3) config_edit_sources; read -rp "Devam..." _ ;;
      4)
        config_load
        local cur_l="${LOG_ENABLE:-1}"
        echo "Log (1=açık,0=kapalı) [${cur_l}]"; read -rp "> " lg; lg="${lg:-$cur_l}"
        [[ "$lg" =~ ^[01]$ ]] || { warn "Geçersiz"; continue; }
        sed -i "s|^LOG_ENABLE=.*|LOG_ENABLE=$lg|" "$CONF_FILE"
        say "Güncellendi."; read -rp "Devam..." _ ;;
      5)
        echo "1) Aç  2) Kapat"; read -rp "Seçim: " t
        [[ "$t" == "1" ]] && timer_enable || timer_disable
        read -rp "Devam..." _ ;;
      6) render_once; say "Cache güncellendi."; read -rp "Devam..." _ ;;
      7) verify_report; read -rp "Devam..." _ ;;
      8) uninstall_all; read -rp "Bitti. Devam..." _ ;;
      9) clear; exit 0 ;;
      10)
        echo "Backend seçin: 1) Conky  2) GNOME Extension"
        read -rp "Seçim: " b
        if [[ "$b" == "1" ]]; then backend_use_conky; else backend_use_extension; fi
        read -rp "Devam..." _ ;;
      11) menu_set_interval; read -rp "Devam..." _ ;;
      12) menu_visual_options; read -rp "Devam..." _ ;;
      *) echo "Geçersiz seçim"; sleep 0.5 ;;
    esac
  done
}
