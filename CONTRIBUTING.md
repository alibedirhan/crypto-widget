# Katkıda Bulunma

Projeye katkıda bulunmak istiyorsanız teşekkürler! Birkaç basit kural:

## Hata Bildirme

Issue açarken şunları ekleyin:
- Ne oldu?
- Nasıl tekrar oluşur?
- Ne olmasını bekliyordunuz?
- Sistem bilgileri (Ubuntu versiyonu, GNOME versiyonu)
- Log çıktısı varsa (`~/.local/state/cal-ticker-v3/log.txt`)

## Kod Katkısı

1. Projeyi fork edin
2. Yeni branch oluşturun: `git checkout -b feature/yeni-ozellik`
3. Değişiklikleri yapın
4. Test edin
5. Commit yapın: `git commit -m "feat: yeni özellik eklendi"`
6. Push edin: `git push origin feature/yeni-ozellik`
7. Pull Request açın

## Kod Standartları

Bash script'ler için:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Fonksiyonlar: snake_case
my_function() {
  local var="value"
  echo "$var"
}

# Global değişkenler: SCREAMING_SNAKE_CASE
GLOBAL_VAR="value"

# Hata kontrolü
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl not found" >&2
  exit 1
fi
```

Genel kurallar:
- Girinti: 2 boşluk
- Maksimum satır uzunluğu: 100 karakter
- Her fonksiyon arasında 1 boş satır

## Commit Mesajları

Basit format:

```
tip: kısa açıklama

Detaylı açıklama (opsiyonel)
```

Tipler:
- `feat`: Yeni özellik
- `fix`: Hata düzeltme
- `docs`: Dokümantasyon
- `style`: Kod formatı
- `refactor`: Kod yeniden yapılandırma
- `test`: Test ekleme/düzeltme
- `chore`: Build değişiklikleri

Örnekler:
```bash
feat: sparkline grafiği için veri depolama eklendi
fix: binance timeout hatası düzeltildi
docs: kurulum adımları güncellendi
```

## Test

Değişikliklerinizi test edin:

```bash
# Script izinlerini kontrol
chmod +x *.sh lib/*.sh

# Test kurulumu
./install.sh

# Tüm özellikleri test et
cal-ticker

# Logları kontrol et
cat ~/.local/state/cal-ticker-v3/log.txt
```

## Pull Request

PR açarken:
- Başlık: Net ve açıklayıcı
- Açıklama: Ne değişti, neden, nasıl test edildi?
- İlgili issue varsa numarasını ekleyin (#123)
- Ekran görüntüsü ekleyin (görsel değişiklikler için)

## Sorularınız mı var?

GitHub Issue açın veya mevcut issue'larda sorun.

---

## English

Thanks for considering contributing! A few simple rules:

## Reporting Bugs

When opening an issue, include:
- What happened?
- How to reproduce?
- What did you expect?
- System info (Ubuntu version, GNOME version)
- Log output if available (`~/.local/state/cal-ticker-v3/log.txt`)

## Code Contribution

1. Fork the project
2. Create branch: `git checkout -b feature/new-feature`
3. Make changes
4. Test
5. Commit: `git commit -m "feat: add new feature"`
6. Push: `git push origin feature/new-feature`
7. Open Pull Request

## Code Standards

For Bash scripts:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Functions: snake_case
my_function() {
  local var="value"
  echo "$var"
}

# Global variables: SCREAMING_SNAKE_CASE
GLOBAL_VAR="value"

# Error checking
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl not found" >&2
  exit 1
fi
```

General rules:
- Indentation: 2 spaces
- Max line length: 100 characters
- 1 blank line between functions

## Commit Messages

Simple format:

```
type: short description

Detailed description (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Adding/fixing tests
- `chore`: Build changes

Examples:
```bash
feat: add data storage for sparkline chart
fix: fix binance timeout error
docs: update installation steps
```

## Testing

Test your changes:

```bash
# Check script permissions
chmod +x *.sh lib/*.sh

# Test installation
./install.sh

# Test all features
cal-ticker

# Check logs
cat ~/.local/state/cal-ticker-v3/log.txt
```

## Pull Request

When opening PR:
- Title: Clear and descriptive
- Description: What changed, why, how tested?
- Add issue number if related (#123)
- Add screenshot (for visual changes)

## Questions?

Open a GitHub Issue or ask in existing issues.

---

Thanks for contributing!
