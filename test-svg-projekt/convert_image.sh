#!/bin/bash
# Konwersja JPG/PNG na SVG

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
    echo "Użycie: $0 <plik_wejściowy.jpg/png> [plik_wyjściowy.svg] [--vectorize]"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-$(basename "$INPUT" | sed 's/\.[^.]*$/.svg/')}"
VECTORIZE=""

if [ "$3" = "--vectorize" ]; then
    VECTORIZE="--vectorize"
fi

echo "🔄 Konwersja: $INPUT -> $OUTPUT"
python3 "$SCRIPT_DIR/src/generator_svg.py" convert \
    --input "$INPUT" \
    --output "$OUTPUT" \
    $VECTORIZE

echo "Gotowe! Plik: $OUTPUT"
