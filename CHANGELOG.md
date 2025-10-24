# Changelog

## [3.0.0] - 2025-10-24

İlk stabil sürüm.

### Eklenenler

**Temel Özellikler:**
- BTC, ETH, GOLD fiyat gösterimi
- 24 saatlik değişim yüzdesi (↑/↓)
- BTC sparkline grafik
- TL karşılıkları (opsiyonel)
- Fiyat alarmları

**Backend:**
- Conky backend (yarı saydam panel)
- GNOME Desktop Widgets backend
- Backend değiştirme özelliği

**Veri Kaynakları:**
- Kripto: Binance, CoinGecko, Coinbase
- Altın: Yahoo Finance, GoldPrice.org
- Kur: ExchangeRate.host, TCMB

**Sistem:**
- Systemd timer entegrasyonu
- Cache mekanizması (TTL destekli)
- Otomatik güncelleme (15/30/60 saniye)
- İnteraktif menü sistemi
- Masaüstü bildirimleri
- Log sistemi

**Komutlar:**
- `cal-ticker` - Ana menü
- `cal-ticker-update` - Manuel güncelleme
- `cal-ticker-show` - Veri gösterimi

**Dokümantasyon:**
- README (TR/EN)
- Kurulum rehberi
- Sorun giderme rehberi
- Katkı rehberi

### Teknik Detaylar

- Modüler yapı (lib/ klasörü)
- Bash 4+ uyumlu
- Ubuntu 24.04 LTS / GNOME 46
- Wayland ve X11 desteği
- Minimal kaynak kullanımı (<10MB RAM)

### Güvenlik

- Sadece public API kullanımı
- Yerel veri işleme
- Credential saklanmaz

---

## Yapılacaklar (Roadmap)

- [ ] Preset temalar (Minimal/Compact/Info)
- [ ] Gram altın fiyatı
- [ ] Health check komutu
- [ ] Log rotasyonu
- [ ] .desktop launcher
- [ ] i18n desteği
- [ ] DEB paketi

---

Not: Bu ilk public release. Önceki versiyonlar dahili testlerdi.
