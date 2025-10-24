# CAL Desktop Ticker v3

Ubuntu 24.04 için hafif masaüstü kripto ve altın fiyat göstergesi.

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?style=flat-square&logo=ubuntu)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)

[English](README_EN.md) | [Kurulum](#kurulum) | [Kullanım](#kullanım)

---

## Nedir?

Masaüstünüzde Bitcoin, Ethereum ve Altın fiyatlarını gösteren şeffaf bir widget. Wayland ve X11'de çalışır.

```
BTC  :  67,234 ↑ 2.3%
ETH  :   3,891 ↑ 1.8%
GOLD :   2,047
BTC 24h: ▁▃▆█▇
Güncellendi: 14:32:15
```

## Özellikler

- BTC ve ETH fiyatları (Binance API)
- Altın fiyatı (Yahoo Finance / GoldPrice.org)
- 24 saatlik değişim yüzdesi
- BTC için ASCII grafik (sparkline)
- TL karşılıkları (opsiyonel)
- Conky veya GNOME Extension backend
- Otomatik güncelleme (15/30/60 saniye)
- Fiyat alarmları

## Gereksinimler

- Ubuntu 24.04 LTS (GNOME 46)
- curl, jq, gawk, libnotify-bin, dconf-cli
- Conky (kurulum sırasında yüklenir)

## Kurulum

```bash
cd ~/Desktop
git clone https://github.com/alibedirhan/crypto-widget.git
cd crypto-widget
chmod +x install.sh
./install.sh
```

Kurulum bitti. Widget sağ üstte görünecek.

## Kullanım

### Ana Menü

```bash
cal-ticker
```

Menüden yapabilecekleriniz:
- Tam kurulum (Conky setup)
- Fiyat alarmı ayarlama
- Veri kaynaklarını değiştirme
- Güncelleme aralığı ayarlama
- Görünüm özellikleri (sparkline, TL, opaklık)
- Backend değiştirme (Conky/Extension)

### Hızlı Komutlar

```bash
cal-ticker-update    # Manuel güncelleme
cal-ticker-show      # Mevcut verileri göster
cal-ticker          # Menü
```

## Yapılandırma

Config dosyası: `~/.config/cal-ticker-v3.conf`

```bash
# Görünüm
USE_PANGO=0              # 0: Conky, 1: Extension
SHOW_TRY=0               # TL göster
SHOW_SPARKLINE=1         # BTC grafiği

# Kaynaklar
CRYPTO_SOURCE=binance    # binance | coingecko | coinbase
GOLD_SOURCE=goldprice    # goldprice | yahoo
FX_SOURCE=exchangerate   # exchangerate | tcmb

# Cache süresi (saniye)
XAU_TTL=300
FX_TTL=600

# Log
LOG_ENABLE=1
```

### Güncelleme Aralığı

Menüden [11] Güncelleme Aralığı:
- 15 saniye (varsayılan)
- 30 saniye
- 60 saniye  
- Özel değer

### Fiyat Alarmları

Menüden [2] Eşik/Alarm Ayarla:

```bash
ALERT_BTC_ABOVE=70000
ALERT_BTC_BELOW=60000
```

Eşik geçildiğinde bildirim alırsınız.

## Backend Seçenekleri

### Conky (Önerilen)

Wayland ve X11'de stabil. Gerçekten şeffaf panel.

```bash
cal-ticker
# [10] Backend: Conky
```

Config: `~/.config/conky/cal-ticker.conf`

### GNOME Desktop Widgets

Native GNOME entegrasyonu, renkli oklar.

[Desktop Widgets uzantısı](https://extensions.gnome.org/extension/1303/desktop-widgets/) gerekli.

```bash
cal-ticker
# [10] Backend: Extension
```

Not: Multi-monitor kurulumlarında Conky daha iyi çalışıyor.

## Sorun Giderme

### Widget Görünmüyor

```bash
# Bağımlılıkları kontrol et
cal-ticker
# [7] Doğrula

# Conky'yi yeniden başlat
pkill -xf "conky -c $HOME/.config/conky/cal-ticker.conf"
conky -c ~/.config/conky/cal-ticker.conf &

# Timer'ı kontrol et
systemctl --user status cal-ticker.timer
```

### Altın Fiyatı "—" Gösteriyor

```bash
# Cache'i temizle
rm -f ~/.cache/cal-ticker-v3/xau.txt ~/.cache/cal-ticker-v3/usdtry.txt

# Kaynağı değiştir
cal-ticker
# [3] Kaynakları Seç → Altın: goldprice

# Manuel güncelle
cal-ticker-update
```

### API Timeout

Kaynak değiştirin veya güncelleme aralığını artırın.

Daha fazla sorun giderme: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Dosya Yapısı

```
~/.local/share/cal-ticker-v3/     # Uygulama
~/.config/cal-ticker-v3.conf       # Config
~/.cache/cal-ticker-v3/            # Cache
~/.config/systemd/user/            # Timer
~/.config/conky/cal-ticker.conf    # Conky
~/.local/bin/cal-ticker*           # Komutlar
```

## Kaldırma

```bash
cal-ticker
# [8] Kaldır (TAM SİL)
```

veya:

```bash
./uninstall.sh
```

Kaynak klasörünüz (proje dizini) korunur.

## Katkıda Bulunma

Pull request'ler kabul edilir. Lütfen [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına bakın.

1. Fork edin
2. Branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit yapın (`git commit -m 'Yeni özellik eklendi'`)
4. Push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

## Yapılacaklar

- [ ] Preset temalar
- [ ] Gram altın fiyatı
- [ ] Health check komutu
- [ ] Log rotasyonu
- [ ] .desktop launcher
- [ ] DEB paketi

## Lisans

MIT License - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Teşekkürler

Veri sağlayıcıları: Binance, Yahoo Finance, GoldPrice.org, ExchangeRate.host

---

**Sorularınız için:** [GitHub Issues](https://github.com/alibedirhan/crypto-widget/issues)

Projeyi beğendiyseniz yıldız vermeyi unutmayın!
