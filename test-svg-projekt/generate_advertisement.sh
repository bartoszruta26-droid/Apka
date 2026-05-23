#!/bin/bash
# Szybkie generowanie tła reklamy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-advertisement_background.svg}"
COLORS="${2:-#667eea,#764ba2}"

echo "📢 Generowanie tła reklamy..."
python3 "$SCRIPT_DIR/src/generator_svg.py" advertisement \
    --output "$OUTPUT" \
    --colors "$COLORS"

echo "Gotowe! Plik: $OUTPUT"
