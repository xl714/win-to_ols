WinWebpVideoToMp4
=================

But
---
Convertir un ou plusieurs WebP animes ("videos" .webp) en MP4 H.264, dans le
meme dossier que les fichiers sources, depuis le menu Windows "Envoyer vers".

Prerequis
---------
- Windows 10 ou Windows 11
- ImageMagick 7 avec la commande magick.exe (extraction des frames)
- ffmpeg (assemblage du MP4), par exemple dans "C:\Program Files\ffmpeg\bin"
- Optionnel : libwebp (webpmux.exe) pour des durees de frames exactes ;
  sans lui, les durees viennent d'ImageMagick, arrondies au centieme de
  seconde (une animation 30 fps peut alors etre lue ~10 % trop vite).

Ton installation actuelle convient : ffmpeg, ImageMagick et libwebp sont
deja presents sur cette machine.

Installation
------------
1. Laisse tous les fichiers de ce dossier ensemble.
2. Double-clique sur Installer.bat.
3. Aucun droit administrateur n'est necessaire.

Utilisation
-----------
1. Selectionne un ou plusieurs fichiers .webp animes dans l'Explorateur.
2. Clic droit > Envoyer vers > WinWebpVideoToMp4 - Convertir en MP4.
3. Sous Windows 11, "Envoyer vers" peut se trouver dans
   "Afficher plus d'options".

Exemples de noms
----------------
- clip.webp                    -> clip.mp4
- si clip.mp4 existe deja      -> clip (1).mp4, puis clip (2).mp4, etc.

Comportement
------------
- Video H.264 (CRF 18), pixels yuv420p, dimensions arrondies au pair :
  compatible avec les lecteurs, navigateurs et messageries courants.
- La duree de chaque frame de l'animation est respectee (delais variables
  inclus), le MP4 dure donc comme l'animation d'origine.
- La transparence devient blanche, car le MP4 n'a pas de transparence.
- Le MP4 ne boucle pas : la lecture en boucle depend du lecteur.
- Un .webp non anime (image fixe) est signale en echec, rien n'est cree.
- Tu peux selectionner plusieurs fichiers en une seule fois.

Lancement manuel
----------------
Depuis un terminal :

  "%LOCALAPPDATA%\WinWebpVideoToMp4\WinWebpVideoToMp4.bat" "C:\Videos\clip.webp"

Tu peux aussi double-cliquer sur WinWebpVideoToMp4.bat dans ce dossier : une
boite de selection de fichiers s'ouvrira.

Pour un usage en script sans boites de dialogue (messages en console) :

  set WINWEBPVIDEOTOMP4_SILENT=1

Reglages
--------
Les reglages se trouvent au debut de WinWebpVideoToMp4.ps1 :
- $Crf (qualite video)
- $Preset (vitesse d'encodage)
- $BackgroundColor
- $ShowSuccessMessage
- $OverwriteExisting
- $DefaultFrameDurationMs

Desinstallation
---------------
Double-clique sur Desinstaller.bat.
