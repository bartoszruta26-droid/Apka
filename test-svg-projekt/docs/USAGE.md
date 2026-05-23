# SVG Graphics Generator - Instrukcja użycia

## Wymagania

- Python 3.8+
- svgwrite: `pip install svgwrite`
- Pillow: `pip install pillow` (opcjonalnie, dla konwersji JPG)

## Funkcje

### 1. Generator tła certyfikatu

Tworzy ozdobne tło dla certyfikatów z:
- Gradientowym tłem
- Ozdobnymi ramkami
- Elementami w rogach
- Wyborem wzoru tła (koła, linie, geometria)

**Przykład:**
```bash
python3 src/generator_svg.py certificate \
    --output cert.svg \
    --color "#8B4513" \
    --pattern geometric
```

### 2. Generator tła reklamy

Tworzy nowoczesne tło dla banerów reklamowych z:
- Gradientem w różnych kierunkach
- Abstrakcyjnymi kształtami
- Opcjonalną siatką

**Przykład:**
```bash
python3 src/generator_svg.py advertisement \
    --output ad.svg \
    --colors "#ff6b6b,#4ecdc4,#ffd93d"
```

### 3. Konwerter JPG/PNG na SVG

Dwa tryby konwersji:

**a) Embedded (domyślny):**
- Obrazek jest osadzony w SVG jako base64
- Zachowuje pełną jakość oryginału
- Plik SVG zawiera dane binarne obrazka

```bash
python3 src/generator_svg.py convert \
    --input photo.jpg \
    --output photo.svg
```

**b) Wektoryzacja:**
- Konwertuje na czarno-biały obraz wektorowy
- Dobre dla logo, tekstów, prostych grafik
- Można dostosować próg binaryzacji

```bash
python3 src/generator_svg.py convert \
    --input logo.png \
    --output logo.svg \
    --vectorize \
    --threshold 128
```

### 4. Placeholder SVG

Tworzy plik zastępczy o задanych wymiarach.

```bash
python3 src/generator_svg.py placeholder \
    --width 800 \
    --height 600 \
    --output placeholder.svg
```

## Parametry

### Certificate
- `--width`, `-w`: Szerokość (domyślnie: 1920)
- `--height`, `-h`: Wysokość (domyślnie: 1080)
- `--color`, `-c`: Kolor ramek
- `--pattern`, `-p`: Typ wzoru (circles, lines, geometric)
- `--no-corners`: Bez ozdobnych rogów

### Advertisement
- `--width`, `-w`: Szerokość
- `--height`, `-h`: Wysokość
- `--colors`: Kolory gradientu (oddzielone przecinkiem)
- `--no-shapes`: Bez kształtów
- `--grid`: Dodaj siatkę

### Convert
- `--input`, `-i`: Plik wejściowy (wymagane)
- `--output`, `-o`: Plik wyjściowy
- `--vectorize`, `-v`: Tryb wektoryzacji
- `--threshold`: Próg binaryzacji (0-255)
- `--scale`: Skala redukcji

### Placeholder
- `--width`: Szerokość (wymagane)
- `--height`: Wysokość (wymagane)
- `--output`: Plik wyjściowy
- `--text`: Tekst
- `--bg-color`: Kolor tła
- `--text-color`: Kolor tekstu

## Przykłady gotowych skryptów

W katalogu głównym znajdują się gotowe skrypty bash:
- `generate_certificate.sh` - szybkie generowanie certyfikatu
- `generate_advertisement.sh` - szybkie generowanie reklamy
- `convert_image.sh` - szybka konwersja obrazków
