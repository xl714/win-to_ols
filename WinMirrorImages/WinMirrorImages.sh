#!/usr/bin/env bash

# Répertoire cible passé en argument, ou . par défaut
dir="${1:-.}"

# Vérifie que le répertoire existe
if [[ ! -d "$dir" ]]; then
  echo "Erreur : '$dir' n'est pas un répertoire valide."
  exit 1
fi

# Crée le sous-répertoire "mirrored" s'il n'existe pas
mkdir -p "$dir/mirrored"

# active nullglob pour ne pas boucler sur des littéraux
shopt -s nullglob

# Boucle sur les extensions
for ext in png jpg jpeg webp; do
  for file in "$dir"/*."$ext"; do
    [[ -f "$file" ]] || continue

    filename=$(basename "$file")                  # nom avec extension
    base="${filename%.*}"                         # sans extension
    out="$dir/mirrored/${base}_mirror_h.${ext}"   # chemin de sortie dans mirrored

    magick "$file" -flop "$out"
    echo "Mirrored: $file → $out"
  done
done

