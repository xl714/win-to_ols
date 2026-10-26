#!/usr/bin/env bash
set -euo pipefail

# Chemins vers outils
FFMPEG="/c/Program Files/ffmpeg/bin/ffmpeg.exe"
WEBMUX="/c/Program Files/libwebp-1.4.0-win-x64/bin/webpmux.exe"
MAGICK="/c/Program Files/ImageMagick-7.1.1-Q16-HDRI/magick.exe"
TMP="$(mktemp -d)"
FPS=25

# Convertit un chemin Windows en chemin MSYS (/c/Users/...)
to_unix() {
  cygpath -u "$1"
}

process_webp() {
  local win_in="$1"
  local unix_in base dir_unix outdir
  unix_in="$(to_unix "$win_in")"
  base="$(basename "${win_in%.*}")"
  dir_unix="$(dirname "$unix_in")"
  outdir="$dir_unix/${base}_fullframes"

  # 1) obtenir le nombre de frames
  local frames
  frames=$("$WEBMUX" -info "$win_in" | awk -F': ' '/Number of frames/ {print $2+0}')
  if [ "$frames" -le 0 ]; then
    echo "⚠️ Aucun frame animé détecté dans $win_in"
    return
  fi

  # 2) extraction des frames partielles en .webp
  rm -rf "$TMP" && mkdir -p "$TMP"
  for ((i=1; i<=frames; i++)); do
    printf -v num "%02d" "$i"
    "$WEBMUX" -get frame "$i" "$win_in" -o "$TMP/frame_${num}.webp"
  done

  # 3) création du dossier de sortie
  mkdir -p "$outdir"
  echo "→ Export full frames dans : $(cygpath -w "$outdir")"

  # 4) recomposition progressive et conversion en PNG sans transparence
  local prev=""
  for ((i=1; i<=frames; i++)); do
    printf -v num "%02d" "$i"
    local chunk="$TMP/frame_${num}.webp"
    local outpng="$outdir/frame_${num}.png"

    if [ "$i" -eq 1 ]; then
      # première frame : image pleine
      "$MAGICK" convert "$chunk" -background white -alpha remove "$outpng"
    else
      # composite “over” pour reconstituer la toile complète
      "$MAGICK" composite "$chunk" "$prev" -alpha off "$outpng"
    fi

    prev="$outpng"
  done

  echo "✅ Frames complètes prêtes dans : $(cygpath -w "$outdir")"
}

main() {
  if [ $# -ne 1 ]; then
    echo "Usage : $0 <fichier.webp|répertoire>"
    exit 1
  fi
  local path="$1"
  if [ -f "$path" ] && [[ "${path##*.}" == "webp" ]]; then
    process_webp "$path"
  elif [ -d "$path" ]; then
    find "$path" -maxdepth 1 -type f -iname '*.webp' -print0 | \
    while IFS= read -r -d '' f; do
      process_webp "$f"
    done
  else
    echo "❌ $path n’est ni un .webp ni un dossier."
    exit 1
  fi
}

main "$@"
