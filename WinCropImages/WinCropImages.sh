#!/usr/bin/env bash

# 1) Arguments : répertoire + x1% y1% x2% y2%
dir="${1:-.}"
x1_pct="$2"; y1_pct="$3"; x2_pct="$4"; y2_pct="$5"

# 2) Vérifs basiques
if [[ ! -d "$dir" ]]; then
  echo "Erreur : '$dir' n'est pas un répertoire."
  exit 1
fi
for v in "$x1_pct" "$y1_pct" "$x2_pct" "$y2_pct"; do
  if ! [[ $v =~ ^[0-9]+$ ]] || (( v<0 || v>100 )); then
    echo "Chaque coord doit être un entier 0–100 (en %)."
    exit 1
  fi
done

# 3) Calculer largeur/hauteur en %  
width_pct=$(( x2_pct - x1_pct ))
height_pct=$(( y2_pct - y1_pct ))
if (( width_pct<=0 || height_pct<=0 )); then
  echo "Erreur : x2 doit être > x1 et y2 > y1."
  exit 1
fi

# 4) Crée le dossier cropped
mkdir -p "$dir/cropped"

# 5) Boucle et crop en %  
shopt -s nullglob
for ext in png jpg jpeg webp; do
  for file in "$dir"/*."$ext"; do
    [[ -f "$file" ]] || continue
    base="${file##*/}"; base="${base%.*}"
    out="$dir/cropped/${base}_cropped_${x1_pct}x${y1_pct}_${width_pct}x${height_pct}pct.${ext}"

    magick "$file" \
      -crop "${width_pct}%x${height_pct}%+${x1_pct}%+${y1_pct}%" +repage \
      "$out"

    echo "Cropped: $file → $out"
  done
done
