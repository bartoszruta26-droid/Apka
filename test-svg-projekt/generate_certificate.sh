#!/bin/bash
# Szybkie generowanie tła certyfikatu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-certificate_background.svg}"
COLOR="${2:-#1a5f7a}"
PATTERN="${3:-circles}"

echo "📜 Generowanie tła certyfikatu..."
python3 "$SCRIPT_DIR/src/generator_svg.py" certificate \
    --output "$OUTPUT" \
    --color "$COLOR" \
    --pattern "$PATTERN"

echo "Gotowe! Plik: $OUTPUT"
