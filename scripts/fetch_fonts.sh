#!/usr/bin/env bash
set -euo pipefail

FONTS_DIR="App/Resources/Fonts"
mkdir -p "$FONTS_DIR"

RAW_BASE="https://raw.githubusercontent.com/google/fonts/main"

FONT_NAMES=(
  "Quicksand.ttf"
  "PlayfairDisplay.ttf"
  "PlayfairDisplay-Italic.ttf"
  "GreatVibes-Regular.ttf"
)
FONT_URLS=(
  "$RAW_BASE/ofl/quicksand/Quicksand%5Bwght%5D.ttf"
  "$RAW_BASE/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf"
  "$RAW_BASE/ofl/playfairdisplay/PlayfairDisplay-Italic%5Bwght%5D.ttf"
  "$RAW_BASE/ofl/greatvibes/GreatVibes-Regular.ttf"
)

LICENSE_NAMES=(
  "Quicksand-OFL.txt"
  "PlayfairDisplay-OFL.txt"
  "GreatVibes-OFL.txt"
)
LICENSE_URLS=(
  "$RAW_BASE/ofl/quicksand/OFL.txt"
  "$RAW_BASE/ofl/playfairdisplay/OFL.txt"
  "$RAW_BASE/ofl/greatvibes/OFL.txt"
)

MIN_FONT_BYTES=40960

download() {
  local dest="$1"
  local url="$2"
  echo "Downloading $dest"
  curl -fsSL "$url" -o "$FONTS_DIR/$dest"
}

for i in "${!FONT_NAMES[@]}"; do
  download "${FONT_NAMES[$i]}" "${FONT_URLS[$i]}"
done

for i in "${!LICENSE_NAMES[@]}"; do
  download "${LICENSE_NAMES[$i]}" "${LICENSE_URLS[$i]}"
done

echo "Verifying downloaded fonts"
for i in "${!FONT_NAMES[@]}"; do
  name="${FONT_NAMES[$i]}"
  path="$FONTS_DIR/$name"

  if [ ! -f "$path" ]; then
    echo "Missing font file: $path" >&2
    exit 1
  fi

  size=$(wc -c < "$path" | tr -d '[:space:]')
  if [ "$size" -le "$MIN_FONT_BYTES" ]; then
    echo "Font file too small (possible download failure): $path ($size bytes)" >&2
    exit 1
  fi

  file_output=$(file -b "$path")
  case "$file_output" in
    *TrueType*|*OpenType*)
      ;;
    *)
      echo "Font file failed type check: $path ($file_output)" >&2
      exit 1
      ;;
  esac

  echo "OK: $path ($size bytes, $file_output)"
done

echo "Verifying license files"
for i in "${!LICENSE_NAMES[@]}"; do
  name="${LICENSE_NAMES[$i]}"
  path="$FONTS_DIR/$name"

  if [ ! -f "$path" ]; then
    echo "Missing license file: $path" >&2
    exit 1
  fi

  size=$(wc -c < "$path" | tr -d '[:space:]')
  if [ "$size" -le 0 ]; then
    echo "License file is empty: $path" >&2
    exit 1
  fi

  echo "OK: $path ($size bytes)"
done

echo "All fonts and licenses fetched and verified"
