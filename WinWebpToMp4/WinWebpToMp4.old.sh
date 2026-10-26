#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

FFMPEG="/c/Program Files/ffmpeg/bin/ffmpeg.exe"
WEBMUX="/c/Program Files/libwebp-1.4.0-win-x64/bin/webpmux.exe"
TMP="$(mktemp -d)"
FPS=25

process_webp(){
  local infile="$1"
  local outfile="${infile%.*}.mp4"
  echo "Processing '$infile' → '$outfile'"

  info=$("$WEBMUX" -info "$infile")
  frames=$(echo "$info" | grep -oP "Number of frames: \K\d+" || echo 0)
  if [[ $frames -le 0 ]]; then
    echo "⚠️ Aucun frame animé détecté dans $infile"
    return
  fi

  rm -f "$TMP"/frame_*.png
  for i in $(seq -f '%02g' 1 "$frames"); do
    "$WEBMUX" -get frame "$i" "$infile" -o "$TMP/frame_$i.png"
    convert "$TMP/frame_$i.png" "$TMP/frame_$i.png"
  done

  "$FFMPEG" -framerate "$FPS" -pattern_type glob -i "$TMP/frame_*.png" \
    -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
    "$outfile"
  echo "✅ Fini : $outfile"
}

main(){
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <file.webp|directory>"
    exit 1
  fi
  path="$1"
  if [[ -f "$path" && "${path##*.}" == "webp" ]]; then
    process_webp "$path"
  elif [[ -d "$path" ]]; then
    while IFS= read -r -d '' wp; do
      process_webp "$wp"
    done < <(find "$path" -maxdepth 1 -type f -iname '*.webp' -print0)
  else
    echo "❌ '$path' n’est ni un fichier .webp ni un dossier."
    exit 1
  fi
}

main "$@"
