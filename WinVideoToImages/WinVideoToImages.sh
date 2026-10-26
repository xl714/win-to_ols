#!/usr/bin/env bash

set -e

# 1. Récupère le chemin de la vidéo en paramètre
videofilepath="$1"

# Check if a directory argument is provided
if [[ -z "$videofilepath" ]]; then
  echo "Usage: $0 /chemin/vers/la/vidéo"
  exit 1
fi

# 2. Extrait le répertoire de la vidéo
videodir="$(dirname "$videofilepath")"

# 3. Extrait le nom du fichier vidéo
filename="$(basename "$videofilepath")"

# 4. Génère filenamecode : remplace espaces par -, enlève accents et caractères spéciaux, ajoute _frame-images
filenamecode="$filename"
filenamecode="${filenamecode%.*}"                          # enlève extension
filenamecode="$(echo "$filenamecode" | iconv -f utf-8 -t ascii//TRANSLIT)" # enlève accents
filenamecode="$(echo "$filenamecode" | tr ' ' '-' | tr -cd 'A-Za-z0-9_-')" # espaces → -, garde alphanum et _-
filenamecode="${filenamecode}_frame-images"

# 5. Crée le répertoire workdir si non existant
workdir="$videodir/$filenamecode"
mkdir -p "$workdir"

# 6. Affiche infos et enregistre dans ffprobe.txt
echo "Vidéo: $videofilepath"
echo "Répertoire de la vidéo: $videodir"
echo "Nom du fichier: $filename"
echo "Dossier d'extraction: $workdir"
echo
echo "== Infos ffprobe =="
/c/Program\ Files/ffmpeg/bin/ffprobe.exe "$videofilepath" 2>&1 | tee "$workdir/ffprobe.txt"

echo
echo "Extraction des images en cours..."

# 7. Extrait toutes les images
/c/Program\ Files/ffmpeg/bin/ffmpeg.exe -i "$videofilepath" "$workdir/frame_%05d.png"

echo
echo "Terminé ! Images extraites dans : $workdir"
