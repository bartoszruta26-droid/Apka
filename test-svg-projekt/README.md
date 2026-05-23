# 🎨 SVG Graphics Generator & Converter

Narzędzie do generowania tła certyfikatów/reklam oraz konwersji grafiki rastrowej (JPG/PNG) na SVG.

## ✨ Funkcje

- **Generator tła certyfikatu**: Ozdobne ramki, wzory, elementy dekoracyjne
- **Generator tła reklamy**: Nowoczesne gradienty, abstrakcyjne kształty
- **Konwerter JPG→SVG**: Osadzanie obrazków lub prosta wektoryzacja
- **Placeholder SVG**: Tworzenie plików zastępczych

## 🚀 Szybki start

```bash
# Instalacja zależności
pip install svgwrite pillow

# Generowanie tła certyfikatu
./generate_certificate.sh certificate.svg "#1a5f7a" circles

# Generowanie tła reklamy
./generate_advertisement.sh ad.svg "#667eea,#764ba2"

# Konwersja obrazka
./convert_image.sh image.jpg image.svg
```

## 📖 Pełna dokumentacja

Zobacz [docs/USAGE.md](docs/USAGE.md) dla szczegółowej instrukcji.

## 📁 Struktura projektu

```
svg-graphics-tool/
├── src/
│   └── generator_svg.py    # Główny moduł Python
├── output/                  # Katalog wyjściowy
├── samples/                 # Przykłady
├── docs/
│   └── USAGE.md            # Dokumentacja
├── generate_certificate.sh  # Skrypt certyfikat
├── generate_advertisement.sh # Skrypt reklama
├── convert_image.sh         # Skrypt konwersji
└── README.md
```

## 🔧 Przykłady użycia API Python

```python
from src.generator_svg import (
    SVGCertificateBackground,
    SVGAdvertisementBackground,
    JPGToSVGConverter
)

# Certyfikat
cert = SVGCertificateBackground(1920, 1080)
cert.generate("cert.svg", border_color="#8B4513", pattern_type="geometric")

# Reklama
ad = SVGAdvertisementBackground(1920, 1080)
ad.generate("ad.svg", gradient_colors=["#ff6b6b", "#4ecdc4"])

# Konwersja
converter = JPGToSVGConverter()
converter.convert_to_base64_embedded("image.jpg", "image.svg")
```

## 📄 Licencja

MIT License
