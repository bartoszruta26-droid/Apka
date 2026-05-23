#!/bin/bash
#===============================================================================
# SVG Graphics Generator & Converter
# =============================================================================
# Skrypt do generowania tła certyfikatów/reklam oraz konwersji JPG na SVG
# Wersja w 100% Bash - minimalizuje użycie Pythona
#
# Autor: Template Generator
# Wersja: 2.0.0
#===============================================================================

set -e

# Kolory domyślne
DEFAULT_BORDER_COLOR="#1a5f7a"
DEFAULT_BG_COLOR_START="#fefefe"
DEFAULT_BG_COLOR_END="#f5f9fa"
DEFAULT_WIDTH=1920
DEFAULT_HEIGHT=1080

#-------------------------------------------------------------------------------
# Funkcje pomocnicze
#-------------------------------------------------------------------------------

show_help() {
    cat << EOF
SVG Graphics Generator & Converter - wersja Bash
================================================

UŻYCIE:
    $0 <komenda> [opcje]

KOMENDY:
    certificate   Generuje tło certyfikatu
    advertisement Generuje tło reklamy/banera
    jpg2svg       Konwertuje JPG/PNG na SVG
    help          Pokazuje tę pomoc

OPCJE DLA CERTIFICATE:
    -w, --width <px>        Szerokość (domyślnie: $DEFAULT_WIDTH)
    -h, --height <px>       Wysokość (domyślnie: $DEFAULT_HEIGHT)
    -c, --color <kolor>     Kolor ramki (domyślnie: $DEFAULT_BORDER_COLOR)
    -p, --pattern <typ>     Wzór: circles|lines|geometric (domyślnie: circles)
    -o, --output <plik>     Plik wyjściowy (domyślnie: certificate.svg)
    --no-corners            Bez ozdobnych rogów

OPCJE DLA ADVERTISEMENT:
    -w, --width <px>        Szerokość (domyślnie: $DEFAULT_WIDTH)
    -h, --height <px>       Wysokość (domyślnie: $DEFAULT_HEIGHT)
    -g, --gradient <kolory> Kolory gradientu oddzielone przecinkiem
    -d, --direction <kier>  Kierunek: horizontal|vertical|diagonal
    -s, --shapes            Dodaj abstrakcyjne kształty
    -n, --grid              Dodaj siatkę overlay
    -o, --output <plik>     Plik wyjściowy (domyślnie: advertisement.svg)

OPCJE DLA JPG2SVG:
    -i, --input <plik>      Plik wejściowy JPG/PNG (wymagane)
    -o, --output <plik>     Plik wyjściowy SVG (domyślnie: input.svg)
    -m, --mode <tryb>       Tryb: embed|vectorize (domyślnie: embed)
                            embed = osadzenie base64 (zachowuje jakość)
                            vectorize = prosta wektoryzacja czarno-biała
    -t, --threshold <0-255> Próg binaryzacji dla trybu vectorize (domyślnie: 128)

PRZYKŁADY:
    # Generuj tło certyfikatu
    $0 certificate -o moj_certyfikat.svg

    # Generuj tło certyfikatu z customowymi ustawieniami
    $0 certificate -w 2480 -h 3508 -c "#gold" -p geometric

    # Generuj tło reklamy
    $0 advertisement -w 1920 -h 1080 -g "#667eea,#764ba2" -s

    # Konwertuj JPG na SVG (osadzenie)
    $0 jpg2svg -i obrazek.jpg -o wynik.svg

    # Konwertuj JPG na SVG (wektoryzacja)
    $0 jpg2svg -i logo.jpg -o logo.svg -m vectorize -t 128

EOF
}

error_exit() {
    echo "❌ BŁĄD: $1" >&2
    exit 1
}

warn() {
    echo "⚠️  UWAGA: $1" >&2
}

info() {
    echo "ℹ️  INFO: $1"
}

#-------------------------------------------------------------------------------
# Generator tła certyfikatu
#-------------------------------------------------------------------------------

generate_certificate_background() {
    local width=$DEFAULT_WIDTH
    local height=$DEFAULT_HEIGHT
    local border_color=$DEFAULT_BORDER_COLOR
    local pattern_type="circles"
    local output_file="certificate.svg"
    local with_corners=true

    # Parsowanie argumentów
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w|--width) width="$2"; shift 2 ;;
            -h|--height) height="$2"; shift 2 ;;
            -c|--color) border_color="$2"; shift 2 ;;
            -p|--pattern) pattern_type="$2"; shift 2 ;;
            -o|--output) output_file="$2"; shift 2 ;;
            --no-corners) with_corners=false; shift ;;
            *) error_exit "Nieznana opcja: $1" ;;
        esac
    done

    # Upewnij się że ma rozszerzenie .svg
    [[ "$output_file" != *.svg ]] && output_file="${output_file}.svg"

    info "Generowanie tła certyfikatu: ${width}x${height}px"

    # Rozpoczęcie pliku SVG
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${width}px" 
     height="${height}px" 
     viewBox="0 0 ${width} ${height}">
  <defs>
    <!-- Gradient tła -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:${DEFAULT_BG_COLOR_START};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${DEFAULT_BG_COLOR_END};stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Tło z gradientem -->
  <rect x="0" y="0" width="${width}" height="${height}" fill="url(#bgGradient)" />
  
EOF

    # Dodaj wzór w tle
    case $pattern_type in
        circles)
            echo "  <!-- Wzór kółek -->" >> "$output_file"
            local radius=60
            local spacing=120
            local circle_radius=$((radius * 4 / 10))
            for ((x=-radius; x<width+radius; x+=spacing)); do
                for ((y=-radius; y<height+radius; y+=spacing)); do
                    echo "  <circle cx=\"$x\" cy=\"$y\" r=\"$circle_radius\" fill=\"$border_color\" opacity=\"0.05\" />" >> "$output_file"
                done
            done
            ;;
        lines)
            echo "  <!-- Wzór linii ukośnych -->" >> "$output_file"
            local line_count=30
            for ((i=0; i<line_count; i++)); do
                local offset=$((i * (width + height) / line_count))
                local x2=$((height - offset))
                echo "  <line x1=\"-$offset\" y1=\"0\" x2=\"$x2\" y2=\"$height\" stroke=\"$border_color\" stroke-width=\"1\" opacity=\"0.025\" />" >> "$output_file"
            done
            ;;
        geometric)
            echo "  <!-- Wzór geometryczny - romby -->" >> "$output_file"
            local diamond_size=40
            local rows=$((height / diamond_size + 2))
            local cols=$((width / diamond_size + 2))
            for ((row=0; row<rows; row++)); do
                for ((col=0; col<cols; col++)); do
                    local cx=$((col * diamond_size + (row % 2) * diamond_size / 2))
                    local cy=$((row * diamond_size * 866 / 1000))
                    local half=$((diamond_size / 2))
                    echo "  <polygon points=\"$cx,$((cy - half)) $((cx + half)),$cy $cx,$((cy + half)) $((cx - half)),$cy\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"0.5\" opacity=\"0.04\" />" >> "$output_file"
                done
            done
            ;;
    esac

    # Dodaj ramkę
    echo "" >> "$output_file"
    echo "  <!-- Ramka zewnętrzna -->" >> "$output_file"
    local border_width=8
    echo "  <rect x=\"$((border_width/2))\" y=\"$((border_width/2))\" width=\"$((width - border_width))\" height=\"$((height - border_width))\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"$border_width\" />" >> "$output_file"
    
    echo "" >> "$output_file"
    echo "  <!-- Ramka wewnętrzna -->" >> "$output_file"
    local inner_width=$((border_width * 4 / 10))
    local offset=$((20 + border_width))
    echo "  <rect x=\"$((offset + inner_width/2))\" y=\"$((offset + inner_width/2))\" width=\"$((width - 2*offset - inner_width))\" height=\"$((height - 2*offset - inner_width))\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"$inner_width\" opacity=\"0.6\" />" >> "$output_file"

    # Dodaj ozdobne rogi
    if [ "$with_corners" = true ]; then
        echo "" >> "$output_file"
        echo "  <!-- Ozdobne elementy w rogach -->" >> "$output_file"
        local corner_size=80
        
        # Lewy górny
        echo "  <path d=\"M $corner_size 0 L 0 0 L 0 $corner_size\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"3\" stroke-linecap=\"round\" />" >> "$output_file"
        echo "  <path d=\"M $corner_size 0 L 0 0 L 0 $corner_size\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"1\" stroke-linecap=\"round\" transform=\"translate(12, 12)\" />" >> "$output_file"
        
        # Prawy górny
        echo "  <path d=\"M $((width - corner_size)) 0 L $width 0 L $width $corner_size\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"3\" stroke-linecap=\"round\" />" >> "$output_file"
        echo "  <path d=\"M $((width - corner_size)) 0 L $width 0 L $width $corner_size\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"1\" stroke-linecap=\"round\" transform=\"translate(-12, 12)\" />" >> "$output_file"
        
        # Lewy dolny
        echo "  <path d=\"M 0 $((height - corner_size)) L 0 $height L $corner_size $height\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"3\" stroke-linecap=\"round\" />" >> "$output_file"
        echo "  <path d=\"M 0 $((height - corner_size)) L 0 $height L $corner_size $height\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"1\" stroke-linecap=\"round\" transform=\"translate(12, -12)\" />" >> "$output_file"
        
        # Prawy dolny
        echo "  <path d=\"M $width $((height - corner_size)) L $width $height L $((width - corner_size)) $height\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"3\" stroke-linecap=\"round\" />" >> "$output_file"
        echo "  <path d=\"M $width $((height - corner_size)) L $width $height L $((width - corner_size)) $height\" fill=\"none\" stroke=\"$border_color\" stroke-width=\"1\" stroke-linecap=\"round\" transform=\"translate(-12, -12)\" />" >> "$output_file"
    fi

    # Zamknij plik SVG
    echo "</svg>" >> "$output_file"

    info "✓ Wygenerowano: $output_file"
}

#-------------------------------------------------------------------------------
# Generator tła reklamy
#-------------------------------------------------------------------------------

generate_advertisement_background() {
    local width=$DEFAULT_WIDTH
    local height=$DEFAULT_HEIGHT
    local gradient_colors="#667eea,#764ba2"
    local direction="diagonal"
    local with_shapes=false
    local with_grid=false
    local output_file="advertisement.svg"

    # Parsowanie argumentów
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w|--width) width="$2"; shift 2 ;;
            -h|--height) height="$2"; shift 2 ;;
            -g|--gradient) gradient_colors="$2"; shift 2 ;;
            -d|--direction) direction="$2"; shift 2 ;;
            -s|--shapes) with_shapes=true; shift ;;
            -n|--grid) with_grid=true; shift ;;
            -o|--output) output_file="$2"; shift 2 ;;
            *) error_exit "Nieznana opcja: $1" ;;
        esac
    done

    [[ "$output_file" != *.svg ]] && output_file="${output_file}.svg"

    info "Generowanie tła reklamy: ${width}x${height}px"

    # Parsowanie kolorów gradientu
    IFS=',' read -ra COLORS <<< "$gradient_colors"
    local color1="${COLORS[0]:-#667eea}"
    local color2="${COLORS[1]:-#764ba2}"

    # Ustawienie współrzędnych gradientu
    local x1=0 y1=0 x2=$width y2=$height
    case $direction in
        horizontal) x2=$width; y2=0 ;;
        vertical) x2=0; y2=$height ;;
        diagonal) x2=$width; y2=$height ;;
    esac

    # Rozpoczęcie pliku SVG
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${width}px" 
     height="${height}px" 
     viewBox="0 0 ${width} ${height}">
  <defs>
    <!-- Gradient -->
    <linearGradient id="adGradient" x1="$x1" y1="$y1" x2="$x2" y2="$y2">
      <stop offset="0%" style="stop-color:${color1};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${color2};stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Tło z gradientem -->
  <rect x="0" y="0" width="${width}" height="${height}" fill="url(#adGradient)" />
  
EOF

    # Dodaj abstrakcyjne kształty
    if [ "$with_shapes" = true ]; then
        echo "  <!-- Abstrakcyjne kształty -->" >> "$output_file"
        # Używamy deterministycznych "losowych" wartości dla powtarzalności
        local shapes=("circle" "rect" "polygon")
        local shape_colors=("#ffffff" "#f0f0f0" "#e0e0e0")
        
        for i in {1..10}; do
            local seed=$((i * 42))
            local shape_idx=$((seed % 3))
            local color_idx=$((seed % 3))
            local x=$((seed * 17 % width))
            local y=$((seed * 13 % height))
            local size=$((50 + seed * 11 % 250))
            local shape="${shapes[$shape_idx]}"
            local color="${shape_colors[$color_idx]}"
            
            case $shape in
                circle)
                    local r=$((size / 2))
                    echo "  <circle cx=\"$x\" cy=\"$y\" r=\"$r\" fill=\"$color\" opacity=\"0.1\" />" >> "$output_file"
                    ;;
                rect)
                    local rx=$((size / 10))
                    echo "  <rect x=\"$((x - size/2))\" y=\"$((y - size/2))\" width=\"$size\" height=\"$size\" rx=\"$rx\" fill=\"$color\" opacity=\"0.1\" />" >> "$output_file"
                    ;;
                polygon)
                    local half=$((size / 2))
                    echo "  <polygon points=\"$x,$((y-half)) $((x+half)),$((y+half)) $((x-half)),$((y+half))\" fill=\"$color\" opacity=\"0.1\" />" >> "$output_file"
                    ;;
            esac
        done
    fi

    # Dodaj siatkę
    if [ "$with_grid" = true ]; then
        echo "" >> "$output_file"
        echo "  <!-- Siatka overlay -->" >> "$output_file"
        local cell_size=50
        
        # Linie pionowe
        for ((x=0; x<=width; x+=cell_size)); do
            echo "  <line x1=\"$x\" y1=\"0\" x2=\"$x\" y2=\"$height\" stroke=\"#ffffff\" stroke-width=\"0.5\" opacity=\"0.05\" />" >> "$output_file"
        done
        
        # Linie poziome
        for ((y=0; y<=height; y+=cell_size)); do
            echo "  <line x1=\"0\" y1=\"$y\" x2=\"$width\" y2=\"$y\" stroke=\"#ffffff\" stroke-width=\"0.5\" opacity=\"0.05\" />" >> "$output_file"
        done
    fi

    echo "</svg>" >> "$output_file"

    info "✓ Wygenerowano: $output_file"
}

#-------------------------------------------------------------------------------
# Konwerter JPG na SVG
#-------------------------------------------------------------------------------

convert_jpg_to_svg() {
    local input_file=""
    local output_file=""
    local mode="embed"
    local threshold=128

    # Parsowanie argumentów
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input) input_file="$2"; shift 2 ;;
            -o|--output) output_file="$2"; shift 2 ;;
            -m|--mode) mode="$2"; shift 2 ;;
            -t|--threshold) threshold="$2"; shift 2 ;;
            *) error_exit "Nieznana opcja: $1" ;;
        esac
    done

    # Walidacja
    [ -z "$input_file" ] && error_exit "Brak pliku wejściowego (-i/--input)"
    [ ! -f "$input_file" ] && error_exit "Plik nie istnieje: $input_file"

    # Domyślna nazwa wyjścia
    if [ -z "$output_file" ]; then
        output_file="${input_file%.*}.svg"
    fi
    [[ "$output_file" != *.svg ]] && output_file="${output_file}.svg"

    info "Konwersja: $input_file -> $output_file (tryb: $mode)"

    case $mode in
        embed)
            convert_jpg_embed_base64 "$input_file" "$output_file"
            ;;
        vectorize)
            convert_jpg_vectorize "$input_file" "$output_file" "$threshold"
            ;;
        *)
            error_exit "Nieznany tryb: $mode (dostępne: embed, vectorize)"
            ;;
    esac
}

convert_jpg_embed_base64() {
    local input_file="$1"
    local output_file="$2"

    # Sprawdź czy ImageMagick jest dostępny
    if command -v convert &> /dev/null; then
        info "Używanie ImageMagick do konwersji..."
        
        # Pobierz wymiary
        local dimensions=$(identify -format "%wx%h" "$input_file" 2>/dev/null)
        local width=$(echo "$dimensions" | cut -dx -f1)
        local height=$(echo "$dimensions" | cut -dx -f2)
        
        # Konwertuj do JPEG i zakoduj base64
        local img_base64=$(convert "$input_file" -quality 95 jpg:- | base64 -w 0)
        
        # Utwórz SVG
        cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${width}px" 
     height="${height}px" 
     viewBox="0 0 ${width} ${height}">
  <image xlink:href="data:image/jpeg;base64,${img_base64}" 
         x="0" y="0" width="${width}" height="${height}" />
</svg>
EOF
        info "✓ Wygenerowano: $output_file (z osadzonym obrazem base64)"
        
    else
        warn "ImageMagick nie znaleziony. Spróbuj: apt install imagemagick"
        
        # Prosta alternatywa - spróbuj直接使用 plik
        if command -v file &> /dev/null; then
            local filetype=$(file -b --mime-type "$input_file")
            info "Wykryto typ pliku: $filetype"
            
            # Spróbuj base64直接使用
            local img_base64=$(base64 -w 0 "$input_file")
            
            # Szacowane wymiary (brak precyzji bez ImageMagick)
            local width=800
            local height=600
            
            cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${width}px" 
     height="${height}px" 
     viewBox="0 0 ${width} ${height}">
  <!-- Uwaga: Wymiary są przybliżone. Zainstaluj ImageMagick dla dokładnych wymiarów. -->
  <image xlink:href="data:${filetype};base64,${img_base64}" 
         x="0" y="0" width="${width}" height="${height}" />
</svg>
EOF
            info "✓ Wygenerowano: $output_file (uwaga: wymiary przybliżone)"
        else
            error_exit "Brak ImageMagick i narzędzia 'file'. Zainstaluj: apt install imagemagick"
        fi
    fi
}

convert_jpg_vectorize() {
    local input_file="$1"
    local output_file="$2"
    local threshold="$3"

    info "Wektoryzacja z progiem: $threshold"

    if command -v convert &> /dev/null; then
        # Konwersja na czarno-biały bitmap
        local temp_bmp=$(mktemp XXXXXX.png)
        
        convert "$input_file" \
            -colorspace Gray \
            -threshold "${threshold}%" \
            -compress none \
            "$temp_bmp" 2>/dev/null || error_exit "Błąd konwersji ImageMagick"
        
        # Pobierz wymiary
        local dimensions=$(identify -format "%wx%h" "$temp_bmp")
        local width=$(echo "$dimensions" | cut -dx -f1)
        local height=$(echo "$dimensions" | cut -dx -f2)
        
        info "Wymiary: ${width}x${height}px"
        
        # Rozpoczęcie SVG
        cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     width="${width}px" 
     height="${height}px" 
     viewBox="0 0 ${width} ${height}">
  <rect x="0" y="0" width="${width}" height="${height}" fill="white" />
  <g fill="black">
EOF
        
        # Odczytaj piksele i generuj prostokąty
        # To jest wolne dla dużych obrazów - lepiej skalować wcześniej
        convert "$temp_bmp" txt:- 2>/dev/null | tail -n +2 | while IFS=' ,-' read x y color rest; do
            if [[ "$color" == "#000000" || "$color" == "black" ]]; then
                echo "    <rect x=\"$x\" y=\"$y\" width=\"1\" height=\"1\" />" >> "$output_file"
            fi
        done
        
        echo "  </g>" >> "$output_file"
        echo "</svg>" >> "$output_file"
        
        rm -f "$temp_bmp"
        
        info "✓ Wygenerowano: $output_file (prosta wektoryzacja)"
        warn "Duże obrazy mogą generować bardzo duże pliki SVG. Rozważ zmniejszenie rozdzielczości."
        
    else
        error_exit "ImageMagick wymagany do wektoryzacji. Zainstaluj: apt install imagemagick"
    fi
}

#-------------------------------------------------------------------------------
# Główny program
#-------------------------------------------------------------------------------

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        certificate)
            generate_certificate_background "$@"
            ;;
        advertisement|ad)
            generate_advertisement_background "$@"
            ;;
        jpg2svg|convert)
            convert_jpg_to_svg "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error_exit "Nieznana komenda: $command. Użyj '$0 help' aby zobaczyć dostępne opcje."
            ;;
    esac
}

main "$@"
