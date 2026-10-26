WinImagesToPDF
==============

But
---
Combiner une ou plusieurs images en un seul PDF (une image par page), depuis
le menu Windows "Envoyer vers". Plus besoin de copier un .bat dans chaque
dossier d'images, et plus besoin de Git Bash.

Prerequis
---------
- Windows 10 ou Windows 11
- ImageMagick 7 avec la commande magick.exe

Installation
------------
1. Laisse tous les fichiers de ce dossier ensemble.
2. Double-clique sur Installer.bat.
3. Aucun droit administrateur n'est necessaire.

Utilisation
-----------
1. Selectionne une ou plusieurs images dans l'Explorateur Windows.
2. Clic droit > Envoyer vers > WinImagesToPDF - Convertir en PDF.
3. Sous Windows 11, "Envoyer vers" peut se trouver dans
   "Afficher plus d'options".

Tu peux aussi :
- Double-cliquer sur WinImagesToPDF.bat : une boite de selection d'images
  s'ouvre.
- Envoyer un DOSSIER vers WinImagesToPDF : toutes les images du dossier
  sont converties (equivalent de l'ancien convert_images_to_pdf.bat).

Comportement
------------
- Le PDF est cree dans le dossier de la premiere image.
- Nom du PDF = nom de la premiere image. Exemple : scan1.jpg -> scan1.pdf.
- Si le PDF existe deja : "scan1 (1).pdf", puis "scan1 (2).pdf", etc.
  L'original n'est jamais ecrase.
- Ordre des pages : tri "naturel" comme l'Explorateur Windows
  (page2 avant page10), quel que soit l'ordre de selection.
- Formats acceptes : jpg, jpeg, png, webp, avif, heic/heif, gif, bmp,
  tif/tiff, jxl, ico. Les autres fichiers selectionnes sont ignores et
  listes dans le message final.
- La transparence devient blanche, l'orientation EXIF est appliquee.
- Pour une image animee ou multi-page, seule la premiere image est gardee.
- Une boite de dialogue resume le resultat (nom du PDF, ordre des pages,
  fichiers ignores).

Limite connue
-------------
Si tu selectionnes enormement de fichiers d'un coup (plusieurs centaines),
Windows peut tronquer la ligne de commande du menu "Envoyer vers".
Dans ce cas, envoie plutot le DOSSIER vers WinImagesToPDF, ou double-clique
sur WinImagesToPDF.bat et choisis les images dans la boite de dialogue.

Lancement manuel
----------------
Depuis un terminal :

  "%LOCALAPPDATA%\WinImagesToPDF\WinImagesToPDF.bat" "C:\Images\page1.jpg" "C:\Images\page2.jpg"

ou pour un dossier entier :

  "%LOCALAPPDATA%\WinImagesToPDF\WinImagesToPDF.bat" "C:\Images"

Option -NoDialog : affiche le resultat dans la console au lieu d'une boite
de dialogue (pratique pour les scripts).

Reglages
--------
Les reglages se trouvent au debut de WinImagesToPDF.ps1 :
- $Quality            : qualite JPEG des images integrees au PDF (90)
- $BackgroundColor    : couleur remplacant la transparence (white)
- $ShowSuccessMessage : $false pour ne rien afficher si tout va bien
- $OverwriteExisting  : $true pour ecraser le PDF existant au lieu de
                        creer "nom (1).pdf"

Anciens fichiers
----------------
- convert_images_to_pdf.bat : ancien mode (copie dans le dossier d'images
  + double-clic). Conserve pour compatibilite, il utilise maintenant la
  version installee et n'a plus besoin de Git Bash.
- WinImagesToPDF.sh : obsolete, n'est plus utilise.

Desinstallation
---------------
Double-clique sur Desinstaller.bat.
