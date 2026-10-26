WinLogoToImg 1.1
============

But
---
Ajouter un logo / watermark dans une autre image depuis le menu Windows
"Envoyer vers", puis enregistrer le resultat en PNG et en JPG.

Prerequis
---------
- Windows 10 ou Windows 11, Windows PowerShell 5.1.
- ImageMagick 7, comme pour WinImgToJpg.

Installation / mise a jour
-------------------------
Double-clique sur Installer.bat. Aucun droit administrateur n'est necessaire.
Une copie du programme est installee dans %LOCALAPPDATA%\WinLogoToImg.
L'entree "WinLogoToImg - Ajouter un logo" est ajoutee a "Envoyer vers".
Il s'agit d'un raccourci Windows vers le lanceur installe. L'ancienne entree
.bat est remplacee automatiquement lors de la mise a jour.
Apres une modification du script source, relance Installer.bat pour mettre
a jour cette copie.

Utilisation
-----------
1. Selectionne exactement 2 fichiers images dans l'Explorateur Windows.
2. Clic droit > Envoyer vers > WinLogoToImg - Ajouter un logo.
   Sous Windows 11 : "Afficher plus d'options" peut etre necessaire.
3. Une fenetre montre la plus petite image, son nom et ses dimensions.
   - Entree, y ou Y : cette image est le logo / watermark.
   - n ou N : l'autre image est le logo / watermark.
   - Echap, Annuler ou fermeture de la fenetre : aucune image n'est creee.
   Les boutons permettent egalement de repondre a la souris.
4. Le logo est ajoute dans l'autre image, appelee l'image parent.

Calcul et exports
-----------------
- La plus petite image est determinee par largeur x hauteur en pixels,
  et non par la taille du fichier en octets. En cas d'egalite, la premiere
  image transmise par Windows est proposee.
- L'orientation EXIF est appliquee avant de calculer les dimensions.
- La largeur du logo est exactement 2/3 de la largeur du parent, arrondie
  au pixel le plus proche (au moins 1 pixel).
- Les proportions et la transparence du logo sont conservees.
- Le logo est centre horizontalement et verticalement.
- Le parent conserve ses dimensions. Si le logo redimensionne depasse
  sa hauteur, les parties qui depassent sont coupees, tout en conservant
  la largeur demandee de 2/3.
- PNG : transparence conservee.
- JPG : qualite 90 ; les zones encore transparentes deviennent blanches.
- Le logo garde son opacite d'origine, sans transparence supplementaire.
- Les animations et fichiers multipages utilisent uniquement la premiere image.
- Les formats reconnus par l'installation ImageMagick sont acceptes,
  notamment PNG, JPG, WEBP, GIF, BMP et TIFF ; AVIF/HEIC selon cette installation.

Noms et emplacement
-------------------
Pour un parent "photo.jpg", le programme cree :
  photo_wtrked.png
  photo_wtrked.jpg

Les deux exports sont places dans le dossier de l'image parent. Si les deux
images sources sont dans le meme dossier, les exports sont donc a cote.
Les originaux ne sont jamais modifies.
Si l'un de ces noms existe deja, une nouvelle paire est creee :
  photo_wtrked (1).png
  photo_wtrked (1).jpg
puis (2), (3), etc. Aucun resultat existant n'est ecrase.

En cas de probleme
------------------
Une selection de 0, 1 ou plus de 2 fichiers affiche une erreur.
Les dossiers, les fichiers identiques et les images illisibles sont refuses.
Les deux conversions sont preparees avant d'enregistrer la paire finale.
Si une erreur survient, la console reste ouverte jusqu'a une touche.
Le journal detaille est conserve dans :
  %LOCALAPPDATA%\WinLogoToImg\WinLogoToImg.log
Si cet emplacement est inaccessible, le repli est :
  %TEMP%\WinLogoToImg\WinLogoToImg.log
Le journal indique version, arguments, commandes ImageMagick, reponses,
resultats et erreurs completes avec les numeros de ligne.
Au-dela de 1 Mo, le journal precedent est conserve sous WinLogoToImg.log.1.
Une erreur d'ecriture du journal ne bloque jamais la conversion.
Les erreurs tres precoces de PowerShell sont aussi conservees dans :
  %TEMP%\WinLogoToImg-error.log
Ce dernier fichier est remplace au prochain lancement.

Pour un lancement toujours visible, avec code de sortie et les 30 dernieres
lignes du journal, utilise :
  Diagnostic.bat "C:\Images\photo.jpg" "C:\Images\logo.png"
Diagnostic.bat se trouve aussi dans %LOCALAPPDATA%\WinLogoToImg.
Codes de sortie : 0 = succes ou annulation ; 1 = erreur.
L'echec d'une boite de message est journalise et reporte dans la console.

Lancement manuel
----------------
WinLogoToImg.bat "C:\Images\photo.jpg" "C:\Images\logo.png"
Sans exactement deux chemins, le programme affiche la meme erreur.

Reglages
--------
Au debut de WinLogoToImg.ps1 :
  $JpegQuality          : qualite JPG (90 par defaut).
  $JpegBackgroundColor  : fond JPG pour la transparence (white).
  $LogoWidthRatio       : largeur du logo / largeur du parent (2.0 / 3.0).

Desinstallation
---------------
Double-clique sur Desinstaller.bat.
Le dossier source et toutes les images sont conserves.
Installer.bat et Desinstaller.bat acceptent /quiet pour eviter la pause finale.

Fichiers du dossier source
--------------------------
- WinLogoToImg.ps1 : traitement, choix du logo et journal.
- WinLogoToImg.bat : lanceur visible, pause en cas d'erreur.
- WinLogoToImg-SendTo.bat : ancien lanceur de compatibilite.
- Diagnostic.bat : lanceur visible avec diagnostic et pause finale.
- Installer.bat : met a jour la copie installee et le raccourci Envoyer vers.
- Desinstaller.bat : retire cette installation et son journal principal.
- README.txt : ce document.

Le fichier execute par Envoyer vers est la copie installee dans
%LOCALAPPDATA%\WinLogoToImg. Apres une modification des sources,
relance Installer.bat pour appliquer la modification au menu.
