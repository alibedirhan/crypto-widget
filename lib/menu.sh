#!/usr/bin/env bash
set -euo pipefail

banner(){
  clear
  echo -e "${BOLD}${CYAN}"
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                    CAL Desktop Ticker v3                      ║
╚═══════════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

status_bar(){
  config_load 2>/dev/null || true
  local timer_status="❌"
  local backend_status="?"
  local last_update="Bilinmiyor"
  
  if systemctl --user is-active "$TIMER_NAME" &>/dev/null; then
    timer_status="✓"
    local interval=$(grep "OnUnitActiveSec=" "$HOME/.config/systemd/user/cal-ticker.timer" 2>/dev/null | cut -d'=' -f2 | sed 's/s//' || echo "?")
    timer_status="✓ ${interval}sn"
  fi
  
  if pgrep -f "conky.*cal-ticker" >/dev/null 2>&1; then
    backend_status="Conky"
  elif [[ -n "$(dget "$W_KEY/enabled" 2>/dev/null)" ]]; then
    backend_status="Extension"
  else
    backend_status="Yok"
  fi
  
  if [[ -f "$CACHE_DIR/render.txt" ]]; then
    last_update=$(date -r "$CACHE_DIR/render.txt" "+%H:%M:%S" 2>/dev/null || echo "Bilinmiyor")
  fi
  
  echo -e "${BOLD}  Timer: ${timer_status} │ Backend: ${backend_status} │ Son: ${last_update}${NC}"
  echo
}

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
  say "Bağımlılık kontrolü…"
  for b in curl jq awk dconf; do
    have "$b" && say "  ✓ $b" || warn "  ✗ $b eksik"
  done
  echo
  
  if systemctl --user is-enabled "$TIMER_NAME" &>/dev/null; then
    say "Timer: ENABLED"
  else
    warn "Timer: DISABLED"
  fi
  
  if [[ -s "$CACHE_DIR/render.txt" ]]; then
    say "Cache hazır:"
    echo
    sed -n '1,8p' "$CACHE_DIR/render.txt"
  else
    warn "Cache boş"
  fi
}

uninstall_all(){
  timer_disable
  widget_uninstall
  pkill -f "conky -c $HOME/.config/conky/cal-ticker.conf" 2>/dev/null || true
  rm -f "$HOME/.config/autostart/cal-ticker-conky.desktop" 2>/dev/null || true
  rm -f "$HOME/.config/conky/cal-ticker.conf" 2>/dev/null || true
  rm -f "$HOME/.local/bin/cal-ticker" "$HOME/.local/bin/cal-ticker-update" "$HOME/.local/bin/cal-ticker-show"
  rm -rf "$APP_HOME" "$CACHE_DIR" "$LOG_DIR"
  rm -f "$CONF_FILE"
  say "Uygulama tamamen kaldırıldı."
}

_timer_file(){ echo "$HOME/.config/systemd/user/cal-ticker.timer"; }
_conky_cfg(){ echo "$HOME/.config/conky/cal-ticker.conf"; }

_set_timer_interval(){
  local sec="$1"
  local t="$(_timer_file)"
  if [[ -f "$t" ]]; then
    sed -i "s/^OnUnitActiveSec=.*/OnUnitActiveSec=${sec}s/" "$t"
    systemctl --user daemon-reload
    systemctl --user restart cal-ticker.timer
    say "Timer aralığı ${sec}s olarak ayarlandı."
  else
    warn "Timer dosyası yok: $t"
  fi
}

_set_conky_interval_for(){
  local sec="$1" ref=3
  (( sec >= 60 )) && ref=10
  (( sec >= 30 && sec < 60 )) && ref=5
  local c="$(_conky_cfg)"
  if [[ -f "$c" ]]; then
    sed -i "s/update_interval = [0-9]\+,/update_interval = ${ref},/" "$c"
    sed -i "s/execpi [0-9]\+/execpi ${ref}/" "$c"
    pkill -xf "conky -c $c" 2>/dev/null || true
    nohup conky -c "$c" >/dev/null 2>&1 &
    say "Conky okuma periyodu ${ref}s olarak ayarlandı."
  fi
}

menu_set_interval(){
  echo
  echo "Güncelleme Aralığı:"
  echo "  [1] 15 saniye (default)"
  echo "  [2] 30 saniye"
  echo "  [3] 60 saniye"
  echo "  [4] Özel"
  echo
  read -rp "Seçim [default: 1]: " k
  k="${k:-1}"
  local sec=15
  case "$k" in
    1) sec=15 ;;
    2) sec=30 ;;
    3) sec=60 ;;
    4) read -rp "Saniye cinsinden [default: 15]: " sec; sec="${sec:-15}"; [[ "$sec" =~ ^[0-9]+$ ]] || { warn "Geçersiz"; return; } ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  _set_timer_interval "$sec"
  _set_conky_interval_for "$sec"
  say "Güncelleme aralığı ${sec}s olarak ayarlandı."
}

_conky_has_updated_line(){
  grep -q 'Güncellendi:' "$(_conky_cfg)" 2>/dev/null
}

_toggle_updated_line(){
  local onoff="$1" c="$(_conky_cfg)"
  [[ -f "$c" ]] || return 0
  if [[ "$onoff" == "1" ]]; then
    if ! _conky_has_updated_line; then
      sed -i '/conky.text = \[\[/,/\]\];/ s/\]\];/\n${execi 3 date -r $HOME\/.cache\/cal-ticker-v3\/render.txt "+Güncellendi:  %H:%M:%S"}\n]];/' "$c"
    fi
  else
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
  sed -i "s/^SHOW_SPARKLINE=.*/SHOW_SPARKLINE=${onoff}/" "$CONF_FILE"
  if [[ -f "$c" ]]; then
    if [[ "$onoff" == "1" ]]; then
      sed -i 's/sed -n "1,3p"/sed -n "1,4p"/' "$c" 2>/dev/null || true
    else
      sed -i 's/sed -n "1,4p"/sed -n "1,3p"/' "$c" 2>/dev/null || true
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
  config_load 2>/dev/null || true
  local cur_sp="${SHOW_SPARKLINE:-1}"
  local cur_try="${SHOW_TRY:-0}"
  local cur_upd=0
  _conky_has_updated_line && cur_upd=1
  
  local cur_opac="40"
  if [[ -f "$(_conky_cfg)" ]]; then
    cur_opac=$(grep -oP 'own_window_argb_value = \K[0-9]+' "$(_conky_cfg)" 2>/dev/null || echo "40")
  fi

  echo
  echo "Sparkline (1/0) [mevcut: $cur_sp, default: 1]"
  read -rp "> " sp
  sp="${sp:-$cur_sp}"
  
  echo "TL karşılığı (1/0) [mevcut: $cur_try, default: 0]"
  read -rp "> " tr
  tr="${tr:-$cur_try}"
  
  echo "Panel opaklık 0–255 (0=şeffaf) [mevcut: $cur_opac, default: 40]"
  read -rp "> " op
  op="${op:-$cur_opac}"
  
  echo "'Güncellendi' satırı (1/0) [mevcut: $cur_upd, default: 1]"
  read -rp "> " up
  up="${up:-$cur_upd}"

  [[ "$sp" =~ ^[01]$ ]] || { warn "Sparkline değeri geçersiz"; return; }
  [[ "$tr" =~ ^[01]$ ]] || { warn "TL değeri geçersiz"; return; }
  [[ "$op" =~ ^[0-9]+$ ]] || { warn "Opaklık geçersiz"; return; }
  [[ "$up" =~ ^[01]$ ]] || { warn "Güncellendi değeri geçersiz"; return; }

  _set_sparkline "$sp"
  _set_try "$tr"
  _set_conky_opacity "$op"
  _toggle_updated_line "$up"

  set +e
  render_once 2>/dev/null
  set -e
  
  say "Görsel ayarlar güncellendi."
}

menu_home(){
  while :; do
    banner
    status_bar
    echo -e "${BOLD}${CYAN}┌─ 🏠 ANA SAYFA ─────────────────────────────────────────────┐${NC}"
    echo
    echo -e "${BOLD}  HIZLI İŞLEMLER${NC}"
    echo -e "    ${GRN}[1]${NC} 🚀 Hızlı Kurulum"
    echo -e "        Tek tıkla varsayılan ayarlarla başlat"
    echo
    echo -e "    ${GRN}[2]${NC} 🔄 Şimdi Güncelle"
    echo -e "        Fiyatları hemen yenile"
    echo
    echo -e "${BOLD}  DURUM BİLGİSİ${NC}"
    echo -e "    ${GRN}[3]${NC} 📊 Detaylı Durum"
    echo -e "        Sistem kontrolü ve cache bilgisi"
    echo
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${YEL}[B]${NC} Ana Menü    ${YEL}[Q]${NC} Çıkış"
    echo
    read -rp "Seçim: " choice
    
    case "$choice" in
      1)
        sed -i 's/^USE_PANGO=.*/USE_PANGO=0/' "$CONF_FILE" || true
        sed -i 's/^GOLD_SOURCE=.*/GOLD_SOURCE=goldprice/' "$CONF_FILE" || true
        sed -i 's/^SHOW_SPARKLINE=.*/SHOW_SPARKLINE=1/' "$CONF_FILE" || true
        rm -f "$CACHE_DIR/xau.txt" "$CACHE_DIR/usdtry.txt" 2>/dev/null || true
        
        set +e
        render_once 2>/dev/null
        set -e
        
        backend_use_conky
        timer_enable
        say "Hızlı kurulum tamamlandı!"
        read -rp "Devam için Enter..." _
        ;;
      2)
        set +e
        render_once 2>/dev/null
        local ret=$?
        set -e
        
        if (( ret == 0 )); then
          say "Cache güncellendi."
        else
          warn "Güncelleme başarısız (API bağlantı sorunu olabilir)"
        fi
        read -rp "Devam için Enter..." _
        ;;
      3)
        verify_report
        read -rp "Devam için Enter..." _
        ;;
      [Bb])
        return
        ;;
      [Qq])
        clear
        exit 0
        ;;
      *)
        warn "Geçersiz seçim"
        sleep 1
        ;;
    esac
  done
}

menu_settings(){
  while :; do
    banner
    status_bar
    echo -e "${BOLD}${CYAN}┌─ ⚙️  AYARLAR ──────────────────────────────────────────────┐${NC}"
    echo
    echo -e "    ${GRN}[1]${NC} 🔔 Eşik/Alarm Ayarları"
    echo -e "        Bitcoin ve Ethereum fiyat alarmları"
    echo
    echo -e "    ${GRN}[2]${NC} 📡 Veri Kaynakları"
    echo -e "        API seçimi (Binance/Coingecko/Coinbase)"
    echo
    echo -e "    ${GRN}[3]${NC} ⏱️  Güncelleme Aralığı"
    echo -e "        Timer periyodu (15sn/30sn/1dk/özel)"
    echo
    echo -e "    ${GRN}[4]${NC} 📝 Log Ayarları"
    echo -e "        Loglama açık/kapalı"
    echo
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${YEL}[B]${NC} Ana Menü    ${YEL}[Q]${NC} Çıkış"
    echo
    read -rp "Seçim: " choice
    
    case "$choice" in
      1)
        config_edit_thresholds
        read -rp "Devam için Enter..." _
        ;;
      2)
        config_edit_sources
        read -rp "Devam için Enter..." _
        ;;
      3)
        menu_set_interval
        read -rp "Devam için Enter..." _
        ;;
      4)
        config_load 2>/dev/null || true
        local cur_l="${LOG_ENABLE:-1}"
        echo
        echo "Log Ayarları:"
        echo "  [1] Açık (default)"
        echo "  [2] Kapalı"
        echo
        read -rp "Seçim [mevcut: $cur_l, default: 1]: " lg
        lg="${lg:-$cur_l}"
        case "$lg" in
          1) sed -i "s|^LOG_ENABLE=.*|LOG_ENABLE=1|" "$CONF_FILE"; say "Log açıldı." ;;
          2) sed -i "s|^LOG_ENABLE=.*|LOG_ENABLE=0|" "$CONF_FILE"; say "Log kapatıldı." ;;
          *) warn "Geçersiz seçim" ;;
        esac
        read -rp "Devam için Enter..." _
        ;;
      [Bb])
        return
        ;;
      [Qq])
        clear
        exit 0
        ;;
      *)
        warn "Geçersiz seçim"
        sleep 1
        ;;
    esac
  done
}

menu_position_settings(){
  config_load 2>/dev/null || true
  local cur_pos="${POSITION:-top_right}"
  local cur_x="${OFFSET_X:-16}"
  local cur_y="${OFFSET_Y:-40}"
  
  echo
  echo "Konum Seçenekleri:"
  echo "  [1] Sol-Üst (top_left)"
  echo "  [2] Orta-Üst (top_center)"
  echo "  [3] Sağ-Üst (top_right) ← default"
  echo "  [4] Sol-Orta (middle_left)"
  echo "  [5] Tam Orta (center)"
  echo "  [6] Sağ-Orta (middle_right)"
  echo "  [7] Sol-Alt (bottom_left)"
  echo "  [8] Orta-Alt (bottom_center)"
  echo "  [9] Sağ-Alt (bottom_right)"
  echo
  read -rp "Seçim [mevcut: $(echo $cur_pos | tr '_' '-'), default: 3]: " pos_choice
  pos_choice="${pos_choice:-3}"
  
  local selected_pos="top_right"
  case "$pos_choice" in
    1) selected_pos="top_left" ;;
    2) selected_pos="top_center" ;;
    3) selected_pos="top_right" ;;
    4) selected_pos="middle_left" ;;
    5) selected_pos="center" ;;
    6) selected_pos="middle_right" ;;
    7) selected_pos="bottom_left" ;;
    8) selected_pos="bottom_center" ;;
    9) selected_pos="bottom_right" ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  
  echo
  echo "X Offset (yatay piksel) [mevcut: $cur_x, default: 16]"
  read -rp "> " x
  x="${x:-$cur_x}"
  [[ "$x" =~ ^[0-9]+$ ]] || { warn "Geçersiz değer"; return; }
  
  echo "Y Offset (dikey piksel) [mevcut: $cur_y, default: 40]"
  read -rp "> " y
  y="${y:-$cur_y}"
  [[ "$y" =~ ^[0-9]+$ ]] || { warn "Geçersiz değer"; return; }
  
  # Config dosyasına yaz
  sed -i "s/^POSITION=.*/POSITION=$selected_pos/" "$CONF_FILE"
  sed -i "s/^OFFSET_X=.*/OFFSET_X=$x/" "$CONF_FILE"
  sed -i "s/^OFFSET_Y=.*/OFFSET_Y=$y/" "$CONF_FILE"
  
  # Conky'yi güncelle ve yeniden başlat
  if declare -F conky_write_config >/dev/null 2>&1; then
    conky_write_config
  fi
  if declare -F conky_restart >/dev/null 2>&1; then
    conky_restart
  fi
  
  say "Konum ayarları güncellendi: $selected_pos (X:$x Y:$y)"
}

menu_font_settings(){
  config_load 2>/dev/null || true
  local cur_font="${FONT_FAMILY:-Noto Sans Mono}"
  local cur_size="${FONT_SIZE:-18}"
  
  echo
  echo "Font Ailesi:"
  echo "  [1] Ubuntu Mono"
  echo "  [2] Noto Sans Mono ← default"
  echo "  [3] DejaVu Sans Mono"
  echo "  [4] Roboto Mono"
  echo "  [5] JetBrains Mono"
  echo "  [6] Courier New"
  echo "  [7] Özel (kullanıcı girer)"
  echo
  read -rp "Seçim [mevcut: $cur_font, default: 2]: " font_choice
  font_choice="${font_choice:-2}"
  
  local selected_font="Noto Sans Mono"
  case "$font_choice" in
    1) selected_font="Ubuntu Mono" ;;
    2) selected_font="Noto Sans Mono" ;;
    3) selected_font="DejaVu Sans Mono" ;;
    4) selected_font="Roboto Mono" ;;
    5) selected_font="JetBrains Mono" ;;
    6) selected_font="Courier New" ;;
    7) 
      read -rp "Font adını girin: " custom_font
      [[ -n "$custom_font" ]] && selected_font="$custom_font" || { warn "Boş font adı"; return; }
      ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  
  echo
  echo "Font Boyutu:"
  echo "  [1] Küçük (14pt)"
  echo "  [2] Normal (18pt) ← default"
  echo "  [3] Büyük (22pt)"
  echo "  [4] Çok Büyük (28pt)"
  echo "  [5] Özel (12-32 arası)"
  echo
  read -rp "Seçim [mevcut: $cur_size, default: 2]: " size_choice
  size_choice="${size_choice:-2}"
  
  local selected_size=18
  case "$size_choice" in
    1) selected_size=14 ;;
    2) selected_size=18 ;;
    3) selected_size=22 ;;
    4) selected_size=28 ;;
    5)
      read -rp "Boyut (12-32): " custom_size
      if [[ "$custom_size" =~ ^[0-9]+$ ]] && (( custom_size >= 12 && custom_size <= 32 )); then
        selected_size="$custom_size"
      else
        warn "Geçersiz boyut (12-32 arası olmalı)"
        return
      fi
      ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  
  # Config dosyasına yaz
  sed -i "s/^FONT_FAMILY=.*/FONT_FAMILY=$selected_font/" "$CONF_FILE"
  sed -i "s/^FONT_SIZE=.*/FONT_SIZE=$selected_size/" "$CONF_FILE"
  
  # Conky'yi güncelle ve yeniden başlat
  if declare -F conky_write_config >/dev/null 2>&1; then
    conky_write_config
  fi
  if declare -F conky_restart >/dev/null 2>&1; then
    conky_restart
  fi
  
  say "Font ayarları güncellendi: $selected_font, ${selected_size}pt"
}

menu_color_settings(){
  config_load 2>/dev/null || true
  local cur_bg="${PANEL_COLOR:-000000}"
  local cur_fg="${TEXT_COLOR:-ffffff}"
  local cur_opac="40"
  
  if [[ -f "$(_conky_cfg)" ]]; then
    cur_opac=$(grep -oP 'own_window_argb_value = \K[0-9]+' "$(_conky_cfg)" 2>/dev/null || echo "40")
  fi
  
  echo
  echo "Panel Rengi (hex kod):"
  echo "  [1] Siyah (000000) ← default"
  echo "  [2] Koyu Gri (1a1a1a)"
  echo "  [3] Mavi Ton (0d1117)"
  echo "  [4] Özel (hex gir)"
  echo
  read -rp "Seçim [mevcut: $cur_bg, default: 1]: " bg_choice
  bg_choice="${bg_choice:-1}"
  
  local selected_bg="000000"
  case "$bg_choice" in
    1) selected_bg="000000" ;;
    2) selected_bg="1a1a1a" ;;
    3) selected_bg="0d1117" ;;
    4)
      read -rp "Hex kod (örn: ff5500): " custom_bg
      if [[ "$custom_bg" =~ ^[0-9a-fA-F]{6}$ ]]; then
        selected_bg="$custom_bg"
      else
        warn "Geçersiz hex kod (6 karakter, 0-9 a-f)"
        return
      fi
      ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  
  echo
  echo "Metin Rengi (hex kod):"
  echo "  [1] Beyaz (ffffff) ← default"
  echo "  [2] Açık Gri (e0e0e0)"
  echo "  [3] Yeşil (24d17e)"
  echo "  [4] Mavi (3b8eea)"
  echo "  [5] Özel (hex gir)"
  echo
  read -rp "Seçim [mevcut: $cur_fg, default: 1]: " fg_choice
  fg_choice="${fg_choice:-1}"
  
  local selected_fg="ffffff"
  case "$fg_choice" in
    1) selected_fg="ffffff" ;;
    2) selected_fg="e0e0e0" ;;
    3) selected_fg="24d17e" ;;
    4) selected_fg="3b8eea" ;;
    5)
      read -rp "Hex kod (örn: ff0000): " custom_fg
      if [[ "$custom_fg" =~ ^[0-9a-fA-F]{6}$ ]]; then
        selected_fg="$custom_fg"
      else
        warn "Geçersiz hex kod (6 karakter, 0-9 a-f)"
        return
      fi
      ;;
    *) warn "Geçersiz seçim"; return ;;
  esac
  
  echo
  echo "Panel Şeffaflığı (0-255, 0=tamamen şeffaf, 255=opak)"
  read -rp "[mevcut: $cur_opac, default: 40]: " opac
  opac="${opac:-$cur_opac}"
  
  if ! [[ "$opac" =~ ^[0-9]+$ ]] || (( opac < 0 || opac > 255 )); then
    warn "Geçersiz şeffaflık değeri (0-255 arası)"
    return
  fi
  
  # Config dosyasına yaz
  sed -i "s/^PANEL_COLOR=.*/PANEL_COLOR=$selected_bg/" "$CONF_FILE"
  sed -i "s/^TEXT_COLOR=.*/TEXT_COLOR=$selected_fg/" "$CONF_FILE"
  
  # Conky'yi güncelle ve yeniden başlat
  if declare -F conky_write_config >/dev/null 2>&1; then
    conky_write_config
  fi
  
  # Şeffaflığı ayrıca set et (eski fonksiyonu kullan)
  if declare -F _set_conky_opacity >/dev/null 2>&1; then
    _set_conky_opacity "$opac"
  fi
  
  say "Renk ayarları güncellendi: Panel=#$selected_bg, Metin=#$selected_fg, Şeffaflık=$opac"
}

menu_appearance(){
  while :; do
    banner
    status_bar
    echo -e "${BOLD}${CYAN}┌─ 🎨 GÖRÜNÜM ───────────────────────────────────────────────┐${NC}"
    echo
    echo -e "    ${GRN}[1]${NC} 🎭 Görsel Ayarlar"
    echo -e "        Sparkline, TL, Opaklık, Güncelleme zamanı"
    echo
    echo -e "    ${GRN}[2]${NC} 📍 Konum Ayarları"
    echo -e "        Ekranda konum ve offset ayarları"
    echo
    echo -e "    ${GRN}[3]${NC} 🔤 Font ve Boyut"
    echo -e "        Yazı tipi ve büyüklüğü"
    echo
    echo -e "    ${GRN}[4]${NC} 🎨 Renk ve Tema"
    echo -e "        Panel/metin rengi ve şeffaflık"
    echo
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${YEL}[B]${NC} Ana Menü    ${YEL}[Q]${NC} Çıkış"
    echo
    read -rp "Seçim: " choice
    
    case "$choice" in
      1)
        menu_visual_options
        read -rp "Devam için Enter..." _
        ;;
      2)
        menu_position_settings
        read -rp "Devam için Enter..." _
        ;;
      3)
        menu_font_settings
        read -rp "Devam için Enter..." _
        ;;
      4)
        menu_color_settings
        read -rp "Devam için Enter..." _
        ;;
      [Bb])
        return
        ;;
      [Qq])
        clear
        exit 0
        ;;
      *)
        warn "Geçersiz seçim"
        sleep 1
        ;;
    esac
  done
}

menu_system(){
  while :; do
    banner
    status_bar
    echo -e "${BOLD}${CYAN}┌─ 🔧 SİSTEM ────────────────────────────────────────────────┐${NC}"
    echo
    echo -e "    ${GRN}[1]${NC} ⏲️  Timer Yönetimi"
    echo -e "        Otomatik güncelleme aç/kapat"
    echo
    echo -e "    ${GRN}[2]${NC} 🔄 Backend Değiştir"
    echo -e "        Conky ↔ GNOME Extension"
    echo
    echo -e "    ${GRN}[3]${NC} ✅ Sistem Doğrulama"
    echo -e "        Bağımlılık ve durum kontrolü"
    echo
    echo -e "${BOLD}${RED}  ⚠️  TEHLİKELİ BÖLGE${NC}"
    echo -e "    ${RED}[4]${NC} ❌ Uygulamayı Tamamen Kaldır"
    echo
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${YEL}[B]${NC} Ana Menü    ${YEL}[Q]${NC} Çıkış"
    echo
    read -rp "Seçim: " choice
    
    case "$choice" in
      1)
        echo
        echo "Timer Yönetimi:"
        echo "  [1] Aç (default)"
        echo "  [2] Kapat"
        echo
        read -rp "Seçim [default: 1]: " t
        t="${t:-1}"
        case "$t" in
          1) timer_enable ;;
          2) timer_disable ;;
          *) warn "Geçersiz seçim" ;;
        esac
        read -rp "Devam için Enter..." _
        ;;
      2)
        echo
        echo "Backend Seçimi:"
        echo "  [1] Conky (Önerilen, default)"
        echo "  [2] GNOME Extension"
        echo
        read -rp "Seçim [default: 1]: " b
        b="${b:-1}"
        case "$b" in
          1) backend_use_conky ;;
          2) backend_use_extension ;;
          *) warn "Geçersiz seçim" ;;
        esac
        read -rp "Devam için Enter..." _
        ;;
      3)
        verify_report
        read -rp "Devam için Enter..." _
        ;;
      4)
        echo
        warn "UYARI: Tüm veriler silinecek!"
        read -rp "Devam etmek için 'evet' yazın: " confirm
        if [[ "$confirm" == "evet" ]]; then
          uninstall_all
          echo
          say "Uygulama kaldırıldı. Çıkılıyor..."
          sleep 2
          clear
          exit 0
        else
          say "İşlem iptal edildi."
          sleep 1
        fi
        ;;
      [Bb])
        return
        ;;
      [Qq])
        clear
        exit 0
        ;;
      *)
        warn "Geçersiz seçim"
        sleep 1
        ;;
    esac
  done
}

menu_main(){
  ensure_deps
  config_ensure
  make_wrappers

  while :; do
    banner
    status_bar
    echo -e "${BOLD}${CYAN}┌─ ANA MENÜ ─────────────────────────────────────────────────┐${NC}"
    echo
    echo -e "    ${GRN}[1]${NC} 🏠 Ana Sayfa"
    echo -e "        Hızlı işlemler ve durum bilgisi"
    echo
    echo -e "    ${GRN}[2]${NC} ⚙️  Ayarlar"
    echo -e "        Eşik, kaynak, timer ve log ayarları"
    echo
    echo -e "    ${GRN}[3]${NC} 🎨 Görünüm"
    echo -e "        Görsel özelleştirme seçenekleri"
    echo
    echo -e "    ${GRN}[4]${NC} 🔧 Sistem"
    echo -e "        Timer, backend, doğrulama ve kaldırma"
    echo
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${YEL}[H]${NC} Yardım    ${YEL}[Q]${NC} Çıkış"
    echo
    read -rp "Seçim: " choice
    
    case "$choice" in
      1) menu_home ;;
      2) menu_settings ;;
      3) menu_appearance ;;
      4) menu_system ;;
      [Hh])
        echo
        say "CAL Desktop Ticker - Yardım"
        echo
        echo "Bu uygulama Bitcoin, Ethereum ve Altın fiyatlarını"
        echo "masaüstünüzde gösterir."
        echo
        echo "Daha fazla bilgi için:"
        echo "  https://github.com/alibedirhan/crypto-widget"
        echo
        read -rp "Devam için Enter..." _
        ;;
      [Qq])
        clear
        exit 0
        ;;
      *)
        warn "Geçersiz seçim"
        sleep 1
        ;;
    esac
  done
}
