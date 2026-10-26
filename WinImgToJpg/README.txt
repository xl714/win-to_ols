WinImgToJpg
===========

But
---
Convertir une ou plusieurs images en JPEG qualite 90, dans le meme dossier que
les fichiers sources, depuis le menu Windows "Envoyer vers".

Prerequis
---------
- Windows 10 ou Windows 11
- ImageMagick 7 avec la commande magick.exe

Ton installation actuelle d'ImageMagick devrait normalement convenir puisque
ton ancien script utilise deja la commande "magick".

Installation
------------
1. Laisse tous les fichiers de ce dossier ensemble.
2. Double-clique sur Installer.bat.
3. Aucun droit administrateur n'est necessaire.

Utilisation
-----------
1. Selectionne une ou plusieurs images dans l'Explorateur Windows.
2. Clic droit > Envoyer vers > WinImgToJpg - Convertir en JPG.
3. Sous Windows 11, "Envoyer vers" peut se trouver dans
   "Afficher plus d'options".

Exemples de noms
----------------
- photo.png       -> photo.jpg
- photo.webp      -> photo.jpg
- photo.avif      -> photo.jpg
- photo.jpg       -> photo_q90.jpg, afin de ne jamais detruire l'original
- si photo.jpg existe deja : photo (1).jpg, puis photo (2).jpg, etc.

Comportement
------------
- Qualite JPEG : 90
- La transparence devient blanche, car JPEG ne gere pas la transparence.
- L'orientation EXIF est appliquee automatiquement.
- Pour une image animee ou multi-page, seule la premiere image est convertie.
- Tous les formats lisibles par ton installation d'ImageMagick sont acceptes.
  WEBP et AVIF sont habituellement pris en charge. HEIC/HEIF depend des
  bibliotheques incluses dans la version d'ImageMagick installee.
- Tu peux selectionner plusieurs fichiers en une seule fois.

Lancement manuel
----------------
Depuis un terminal :

  "%LOCALAPPDATA%\WinImgToJpg\WinImgToJpg.bat" "C:\Images\photo.webp"

Tu peux aussi double-cliquer sur WinImgToJpg.bat dans ce dossier : une boite de
selection d'images s'ouvrira.

Reglages
--------
Les reglages se trouvent au debut de WinImgToJpg.ps1 :
- $Quality
- $BackgroundColor
- $ShowSuccessMessage
- $OverwriteExisting

Desinstallation
---------------
Double-clique sur Desinstaller.bat.
