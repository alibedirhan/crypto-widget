# Sorun Giderme

Yaygın sorunlar ve çözümleri.

---

## Widget Görünmüyor

**Conky'yi kontrol edin:**
```bash
# Çalışıyor mu?
ps aux | grep conky

# Yeniden başlat
pkill -xf "conky -c $HOME/.config/conky/cal-ticker.conf"
conky -c ~/.config/conky/cal-ticker.conf &
```

**Bağımlılıkları kontrol edin:**
```bash
cal-ticker
# Menüden [7] Doğrula
```

**Timer durumu:**
```bash
systemctl --user status cal-ticker.timer

# Kapalıysa aç
systemctl --user enable --now cal-ticker.timer
```

---

## Fiyatlar Güncellenmiyor

**Manuel güncelleme deneyin:**
```bash
cal-ticker-update
cal-ticker-show
```

**Cache'i kontrol edin:**
```bash
ls -la ~/.cache/cal-ticker-v3/render.txt
cat ~/.cache/cal-ticker-v3/render.txt
```

**Timer'ı yeniden başlatın:**
```bash
systemctl --user restart cal-ticker.timer
```

---

## Altın Fiyatı "—" Gösteriyor

**Cache'i temizleyin:**
```bash
rm -f ~/.cache/cal-ticker-v3/xau.txt
rm -f ~/.cache/cal-ticker-v3/usdtry.txt
cal-ticker-update
```

**Kaynağı değiştirin:**
```bash
cal-ticker
# [3] Kaynakları Seç
# Altın: goldprice veya yahoo deneyin
```

Manuel config:
```bash
nano ~/.config/cal-ticker-v3.conf
# GOLD_SOURCE=goldprice
```

---

## API Timeout Hataları

**İnternet bağlantısını test edin:**
```bash
curl -s "https://data-api.binance.vision/api/v3/ticker/24hr?symbol=BTCUSDT" | jq
```

**Alternatif kaynak kullanın:**
```bash
cal-ticker
# [3] Kaynakları Seç
# Kripto: coingecko veya coinbase deneyin
```

**Güncelleme aralığını artırın:**
```bash
cal-ticker
# [11] Güncelleme Aralığı → 60 saniye
```

---

## Conky Sorunları

### Panel Opak

```bash
# Opaklığı ayarla
cal-ticker
# [12] Görsel Seçenekler
# Panel opaklık: 40 (önerilen, 0=şeffaf)
```

Manuel:
```bash
nano ~/.config/conky/cal-ticker.conf
# own_window_argb_value = 40
```

### Yanlış Konum

```bash
nano ~/.config/conky/cal-ticker.conf

# Konum değiştir:
# alignment = 'top_right'  (veya top_left, bottom_right, vb.)

# Boşluk ayarla:
# gap_x = 16
# gap_y = 40
```

### Font Sorunu

```bash
# Noto Sans Mono kur
sudo apt install fonts-noto

# Alternatif font kullan
nano ~/.config/conky/cal-ticker.conf
# font = 'Ubuntu Mono:size=18'
```

---

## GNOME Extension Sorunları

### Extension Aktif Olmuyor

```bash
# Yüklü mü?
gnome-extensions list | grep -i widget

# Etkinleştir
gnome-extensions enable azclock@azclock.gitlab.com

# GNOME Shell'i yenile (Alt+F2, 'r', Enter)
```

### Widget Görünmüyor

```bash
# Backend'i extension'a geç
cal-ticker
# [10] Backend: Extension

# dconf kontrol
dconf read /org/gnome/shell/extensions/desktop-widgets/widgets/cal-ticker/enabled
```

---

## Multi-Monitor

### Widget Yanlış Monitörde (Conky)

```bash
nano ~/.config/conky/cal-ticker.conf

# Monitor ekle (0, 1, 2...)
xinerama_head = 0
```

---

## Log İnceleme

**Log konumu:**
```bash
~/.local/state/cal-ticker-v3/log.txt
```

**Canlı izle:**
```bash
tail -f ~/.local/state/cal-ticker-v3/log.txt
```

**Hataları görüntüle:**
```bash
grep -i error ~/.local/state/cal-ticker-v3/log.txt
```

**Temizle:**
```bash
> ~/.local/state/cal-ticker-v3/log.txt
```

---

## Temiz Kurulum

Hiçbir şey işe yaramadıysa:

```bash
# Tamamen kaldır
cal-ticker
# [8] Kaldır (TAM SİL)

# Yeniden kur
cd ~/Desktop/crypto-widget
./install.sh
```

---

## Hata Bildirme

Sorununuz çözülmediyse GitHub'da issue açın:

**Ekleyin:**
- Sorun açıklaması
- Yeniden oluşturma adımları
- Sistem bilgileri (Ubuntu, GNOME versiyonu)
- Log çıktısı
- Ekran görüntüleri

[GitHub Issues](https://github.com/alibedirhan/crypto-widget/issues)

---

# Troubleshooting (English)

Common issues and solutions.

---

## Widget Not Visible

**Check Conky:**
```bash
# Is it running?
ps aux | grep conky

# Restart
pkill -xf "conky -c $HOME/.config/conky/cal-ticker.conf"
conky -c ~/.config/conky/cal-ticker.conf &
```

**Check dependencies:**
```bash
cal-ticker
# Menu [7] Verify
```

**Timer status:**
```bash
systemctl --user status cal-ticker.timer

# If disabled, enable
systemctl --user enable --now cal-ticker.timer
```

---

## Prices Not Updating

**Try manual update:**
```bash
cal-ticker-update
cal-ticker-show
```

**Check cache:**
```bash
ls -la ~/.cache/cal-ticker-v3/render.txt
cat ~/.cache/cal-ticker-v3/render.txt
```

**Restart timer:**
```bash
systemctl --user restart cal-ticker.timer
```

---

## Gold Shows "—"

**Clear cache:**
```bash
rm -f ~/.cache/cal-ticker-v3/xau.txt
rm -f ~/.cache/cal-ticker-v3/usdtry.txt
cal-ticker-update
```

**Change source:**
```bash
cal-ticker
# [3] Select Sources
# Gold: try goldprice or yahoo
```

Manual config:
```bash
nano ~/.config/cal-ticker-v3.conf
# GOLD_SOURCE=goldprice
```

---

## API Timeouts

**Test internet:**
```bash
curl -s "https://data-api.binance.vision/api/v3/ticker/24hr?symbol=BTCUSDT" | jq
```

**Use alternative source:**
```bash
cal-ticker
# [3] Select Sources
# Crypto: try coingecko or coinbase
```

**Increase interval:**
```bash
cal-ticker
# [11] Update Interval → 60 seconds
```

---

## Conky Issues

### Panel Opaque

```bash
# Adjust opacity
cal-ticker
# [12] Visual Options
# Panel opacity: 40 (recommended, 0=transparent)
```

Manual:
```bash
nano ~/.config/conky/cal-ticker.conf
# own_window_argb_value = 40
```

### Wrong Position

```bash
nano ~/.config/conky/cal-ticker.conf

# Change position:
# alignment = 'top_right'  (or top_left, bottom_right, etc.)

# Adjust spacing:
# gap_x = 16
# gap_y = 40
```

---

## Clean Install

If nothing works:

```bash
# Complete removal
cal-ticker
# [8] Uninstall (COMPLETE REMOVAL)

# Reinstall
cd ~/Desktop/crypto-widget
./install.sh
```

---

## Report Bug

If issue persists, open GitHub issue:

**Include:**
- Problem description
- Steps to reproduce
- System info (Ubuntu, GNOME version)
- Log output
- Screenshots

[GitHub Issues](https://github.com/alibedirhan/crypto-widget/issues)
