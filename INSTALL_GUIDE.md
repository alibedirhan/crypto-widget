# GitHub'a Yükleme

Projeyi GitHub'a yüklemek için basit adımlar.

## Hazırlık

### 1. Dosyaları Düzenle

```bash
cd ~/Desktop/crypto-widget

# lib klasörü oluştur
mkdir -p lib

# Script dosyalarını lib'e taşı
mv api.sh backend.sh cache.sh config.sh core.sh menu.sh utils.sh widget.sh lib/

# unistall.sh typo düzelt
mv unistall.sh uninstall.sh 2>/dev/null || true
```

### 2. Dokümantasyon Ekle

İndirdiğiniz dosyaları proje dizinine kopyalayın:
- README.md
- README_EN.md
- LICENSE
- CONTRIBUTING.md
- CHANGELOG.md
- TROUBLESHOOTING.md
- .gitignore

### 3. Screenshots Klasörü (Opsiyonel)

```bash
mkdir -p screenshots

# Widget çalışırken screenshot al
gnome-screenshot -a

# screenshots/ klasörüne kaydet
mv ~/Pictures/Screenshot*.png screenshots/widget.png
```

## Git

### Init ve Commit

```bash
cd ~/Desktop/crypto-widget

git init
git add .
git commit -m "initial commit"
```

### GitHub'a Push

```bash
git remote add origin https://github.com/alibedirhan/crypto-widget.git
git branch -M main
git push -u origin main
```

**Not:** Repo'da dosya varsa:
```bash
# Force push (mevcut dosyaları siler)
git push -u origin main --force

# veya merge
git pull origin main --allow-unrelated-histories
git push origin main
```

## GitHub Ayarları

### About Bölümü

Repository'de sağ üst "About" ⚙️:

**Description:**
```
Desktop crypto & gold price ticker for Ubuntu 24.04 | Conky & GNOME support
```

**Topics:**
```
ubuntu, crypto, bitcoin, ethereum, gold, desktop-widget, conky, gnome, bash
```

### Settings

Settings → General → Features:
- ✓ Issues
- ✓ Discussions (opsiyonel)
- ✗ Wiki

## Bitti

Projeniz artık: https://github.com/alibedirhan/crypto-widget

### Sonraki Adımlar

1. README'yi gözden geçir
2. Ekran görüntüleri ekle
3. İlk yıldızı ver
4. Issue template oluştur (opsiyonel)
5. Release yayınla (opsiyonel)

## Sorunlar

### "remote: Repository not found"

```bash
git remote -v
git remote set-url origin https://github.com/alibedirhan/crypto-widget.git
```

### "Permission denied"

Personal Access Token kullan:
1. GitHub Settings → Developer settings → Personal access tokens
2. Generate new token
3. Scope: `repo`
4. Token'ı kopyala
5. Push sırasında şifre yerine token kullan

### "Updates were rejected"

```bash
git push -u origin main --force
```

---

# Upload to GitHub (English)

Simple steps to upload project to GitHub.

## Preparation

### 1. Organize Files

```bash
cd ~/Desktop/crypto-widget

# Create lib folder
mkdir -p lib

# Move scripts to lib
mv api.sh backend.sh cache.sh config.sh core.sh menu.sh utils.sh widget.sh lib/

# Fix typo
mv unistall.sh uninstall.sh 2>/dev/null || true
```

### 2. Add Documentation

Copy downloaded files to project directory:
- README.md
- README_EN.md
- LICENSE
- CONTRIBUTING.md
- CHANGELOG.md
- TROUBLESHOOTING.md
- .gitignore

### 3. Screenshots Folder (Optional)

```bash
mkdir -p screenshots

# Take screenshot while widget running
gnome-screenshot -a

# Save to screenshots/
mv ~/Pictures/Screenshot*.png screenshots/widget.png
```

## Git

### Init and Commit

```bash
cd ~/Desktop/crypto-widget

git init
git add .
git commit -m "initial commit"
```

### Push to GitHub

```bash
git remote add origin https://github.com/alibedirhan/crypto-widget.git
git branch -M main
git push -u origin main
```

**Note:** If repo has files:
```bash
# Force push (removes existing files)
git push -u origin main --force

# or merge
git pull origin main --allow-unrelated-histories
git push origin main
```

## GitHub Settings

### About Section

On repository, top right "About" ⚙️:

**Description:**
```
Desktop crypto & gold price ticker for Ubuntu 24.04 | Conky & GNOME support
```

**Topics:**
```
ubuntu, crypto, bitcoin, ethereum, gold, desktop-widget, conky, gnome, bash
```

### Settings

Settings → General → Features:
- ✓ Issues
- ✓ Discussions (optional)
- ✗ Wiki

## Done

Project is now at: https://github.com/alibedirhan/crypto-widget

### Next Steps

1. Review README
2. Add screenshots
3. Give first star
4. Create issue template (optional)
5. Publish release (optional)

## Issues

### "remote: Repository not found"

```bash
git remote -v
git remote set-url origin https://github.com/alibedirhan/crypto-widget.git
```

### "Permission denied"

Use Personal Access Token:
1. GitHub Settings → Developer settings → Personal access tokens
2. Generate new token
3. Scope: `repo`
4. Copy token
5. Use token as password when pushing

### "Updates were rejected"

```bash
git push -u origin main --force
```
