#!/usr/bin/env bash
set -euo pipefail

FONTS_DIR="App/Resources/Fonts"
mkdir -p "$FONTS_DIR"

RAW_BASE="https://raw.githubusercontent.com/google/fonts/main"

declare -A FONT_URLS=(
  ["Quicksand.ttf"]="$RAW_BASE/ofl/quicksand/Quicksand%5Bwght%5D.ttf"
  ["PlayfairDisplay.ttf"]="$RAW_BASE/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf"
  ["PlayfairDisplay-Italic.ttf"]="$RAW_BASE/ofl/playfairdisplay/PlayfairDisplay-Italic%5Bwght%5D.ttf"
  ["GreatVibes-Regular.ttf"]="$RAW_BASE/ofl/greatvibes/GreatVibes-Regular.ttf"
)

declare -A LICENSE_URLS=(
  ["Quicksand-OFL.txt"]="$RAW_BASE/ofl/quicksand/OFL.txt"
  ["PlayfairDisplay-OFL.txt"]="$RAW_BASE/ofl/playfairdisplay/OFL.txt"
  ["GreatVibes-OFL.txt"]="$RAW_BASE/ofl/greatvibes/OFL.txt"
)

MIN_FONT_BYTES=40960

download() {
  local dest="$1"
  local url="$2"
  echo "Downloading $dest"
  curl -fsSL "$url" -o "$FONTS_DIR/$dest"
}

for name in "${!FONT_URLS[@]}"; do
  download "$name" "${FONT_URLS[$name]}"
done

for name in "${!LICENSE_URLS[@]}"; do
  download "$name" "${LICENSE_URLS[$name]}"
done

echo "Verifying downloaded fonts"
for name in "${!FONT_URLS[@]}"; do
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
for name in "${!LICENSE_URLS[@]}"; do
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
