# CAL Desktop Ticker v3.1

**Bitcoin, Ethereum, Gold fiyat takip widget'ı**

## ✨ v3.1 Yenilikleri

- ✅ Kısa sparkline grafiği (18 nokta - daha kompakt)
- ✅ Otomatik config migrasyon
- ✅ Dinamik konum/font/renk desteği (altyapı hazır)
- ✅ Geliştirilmiş hata yakalama

## 🚀 Kurulum

```bash
cd ~/Desktop/Desktop-widget
bash install.sh
```

Kurulum:
- ✅ Conky backend (varsayılan)
- ✅ Sağ-üst köşe
- ✅ 18 nokta sparkline grafik
- ✅ 15 saniye güncelleme
- ✅ Desktop notification alarmlar

## 📋 Özellikler

### Gösterilenler
- **BTC** fiyat + 24h değişim (%)
- **ETH** fiyat + 24h değişim (%)
- **GOLD** fiyat (oz başına USD)
- **Sparkline** grafiği (24h BTC trendi)
- **TL karşılıkları** (opsiyonel)

### Ayarlanabilir
- ⚙️ Veri kaynakları (Binance/Coingecko/Coinbase)
- ⚙️ Güncelleme aralığı (15s/30s/60s)
- ⚙️ Fiyat alarmları (desktop notification)
- ⚙️ Görünüm (sparkline, TL, opacity)
- ⚙️ Backend (Conky/GNOME Extension)

## 🎮 Kullanım

### Menü Açma
```bash
cal-ticker
```

### Manuel Güncelleme
```bash
cal-ticker-update
```

### Durum Görüntüleme
```bash
cal-ticker-show
```

## 📂 Dosya Yapısı

```
~/Desktop/Desktop-widget/              # Kaynak kod
├── ticker.sh                          # Ana script
├── install.sh                         # Kurulum
├── uninstall.sh                       # Kaldırma
└── lib/
    ├── menu.sh                        # Menü sistemi
    ├── config.sh                      # Config yönetimi
    ├── backend.sh                     # Conky/Extension
    ├── cache.sh                       # Render + cache
    ├── api.sh                         # API çağrıları
    ├── widget.sh                      # Timer + widget
    ├── core.sh                        # Değişkenler
    └── utils.sh                       # Helper fonksiyonlar

~/.local/share/cal-ticker-v3/          # Kurulu sistem
~/.config/cal-ticker-v3.conf           # Config dosyası
~/.cache/cal-ticker-v3/                # Cache + render
~/.config/conky/cal-ticker.conf        # Conky config
```

## 🔧 Özelleştirme

### Config Düzenleme
```bash
nano ~/.config/cal-ticker-v3.conf
```

Değiştirilebilir ayarlar:
- `SPARK_POINTS=18` → Grafik uzunluğu
- `SHOW_TRY=1` → TL göster/gizle
- `CRYPTO_SOURCE=binance` → Veri kaynağı
- `ALERT_BTC_ABOVE=111000` → Fiyat alarmları

### Conky Yeniden Başlatma
```bash
pkill -xf "conky.*cal-ticker"
conky -c ~/.config/conky/cal-ticker.conf &
```

## 🐛 Sorun Giderme

### Widget görünmüyor
```bash
# Timer kontrolü
systemctl --user status cal-ticker.timer

# Manuel güncelleme
cal-ticker-update

# Conky kontrolü
pgrep -f "conky.*cal-ticker"
```

### API hatası
```bash
# Config'de veri kaynağını değiştir
sed -i 's/^FX_SOURCE=.*/FX_SOURCE=tcmb/' ~/.config/cal-ticker-v3.conf
```

### Cache problemi
```bash
# Cache temizle
rm -rf ~/.cache/cal-ticker-v3/*
cal-ticker-update
```

## 📝 Sürüm Notları

### v3.1 (25 Ekim 2025)
- Sparkline 40 → 18 noktaya düşürüldü
- Config migrasyon sistemi eklendi
- Backend dinamik hale getirildi
- Render hata yakalama iyileştirildi

### v3.0 (24 Ekim 2025)
- Menü sistemi yenilendi (4 kategori)
- Conky backend eklendi
- Fiyat alarmları eklendi
- Sparkline grafikler eklendi

## 🤝 Katkıda Bulunma

Pull request'ler kabul edilir!

## 📄 Lisans

MIT License - detaylar için LICENSE dosyasına bakın.

---

**Geliştirici:** Ali  
**Tarih:** Ekim 2025  
**Versiyon:** 3.1
