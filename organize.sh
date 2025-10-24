#!/bin/bash
# Proje organizasyon scripti

set -e

echo "CAL Desktop Ticker - Proje Düzenleme"
echo ""

# lib klasörü
if [ ! -d "lib" ]; then
    mkdir -p lib
    echo "✓ lib/ klasörü oluşturuldu"
fi

# Script dosyalarını taşı
for file in api.sh backend.sh cache.sh config.sh core.sh menu.sh utils.sh widget.sh; do
    if [ -f "$file" ] && [ ! -f "lib/$file" ]; then
        mv "$file" "lib/"
        echo "✓ $file → lib/ taşındı"
    fi
done

# unistall.sh typo düzelt
if [ -f "unistall.sh" ] && [ ! -f "uninstall.sh" ]; then
    mv "unistall.sh" "uninstall.sh"
    echo "✓ unistall.sh → uninstall.sh düzeltildi"
fi

# screenshots klasörü
if [ ! -d "screenshots" ]; then
    mkdir -p screenshots
    echo "✓ screenshots/ klasörü oluşturuldu"
fi

echo ""
echo "Proje yapısı:"
echo "  ✓ lib/ klasörü"
echo "  ✓ screenshots/ klasörü"
echo "  ✓ Script dosyaları organize edildi"
echo ""

# Eksik dosyaları kontrol et
missing=()
for file in README.md LICENSE CONTRIBUTING.md CHANGELOG.md .gitignore; do
    if [ ! -f "$file" ]; then
        missing+=("$file")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Eksik dosyalar:"
    for file in "${missing[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Bu dosyaları proje dizinine ekleyin."
else
    echo "Tüm dosyalar mevcut!"
fi

echo ""
echo "Git için hazır. Şimdi yapabilirsiniz:"
echo "  git init"
echo "  git add ."
echo "  git commit -m 'initial commit'"
echo "  git remote add origin https://github.com/alibedirhan/crypto-widget.git"
echo "  git push -u origin main"
