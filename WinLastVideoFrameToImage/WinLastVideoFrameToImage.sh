#!/usr/bin/env bash

set -e

# 1. Récupère le chemin de la vidéo en paramètre
videofilepath="$1"

# Vérifie si un argument est fourni
if [[ -z "$videofilepath" ]]; then
  echo "Usage: $0 /chemin/vers/la/vidéo"
  exit 1
fi

# 2. Extrait le répertoire et le nom du fichier
videodir="$(dirname "$videofilepath")"
filename="$(basename "$videofilepath")"

# 3. Crée un nom de fichier de sortie propre
filenamecode="${filename%.*}"
filenamecode="$(echo "$filenamecode" | iconv -f utf-8 -t ascii//TRANSLIT)"
filenamecode="$(echo "$filenamecode" | tr ' ' '-' | tr -cd 'A-Za-z0-9_-')"
outputpath="$videodir/${filenamecode}_last-frame.png"

# 4. Affiche infos
echo "Vidéo: $videofilepath"
echo "Extraction du dernier frame → $outputpath"
echo

# 5. Utilise ffmpeg pour extraire la dernière image
/c/Program\ Files/ffmpeg/bin/ffmpeg.exe -sseof -1 -i "$videofilepath" -update 1 -q:v 1 "$outputpath"

echo
echo "✅ Dernière frame extraite avec succès : $outputpath"
