# win-to_ols

Une collection d’outils Windows pour convertir des images, créer et fusionner des PDF, ajouter un filigrane et extraire des images de vidéos.

Chaque outil est indépendant. Cinq d’entre eux s’installent dans le menu **clic droit → Envoyer vers** de l’Explorateur Windows. Les autres utilisent un lanceur `.bat` associé à un script Bash.

## Outils disponibles

| Outil | Fonction | Utilisation |
|---|---|---|
| [WinImgToJpg](WinImgToJpg/) | Convertir une ou plusieurs images en JPEG, qualité 90 par défaut. | Envoyer vers |
| [WinImagesToPDF](WinImagesToPDF/) | Assembler des images dans un PDF, avec un tri naturel des noms : `page2` avant `page10`. | Envoyer vers |
| [WinMergePDFs](WinMergePDFs/) | Fusionner plusieurs PDF dans l’ordre naturel des noms, sans recompression des images. | Envoyer vers |
| [WinLogoToImg](WinLogoToImg/) | Centrer un logo ou filigrane sur une image et exporter le résultat en PNG et JPG. | Envoyer vers |
| [WinWebpVideoToMp4](WinWebpVideoToMp4/) | Convertir des WebP animés en MP4 H.264 en tenant compte de la durée des images. | Envoyer vers |
| [WinCropImages](WinCropImages/) | Recadrer les images d’un dossier selon des coordonnées exprimées en pourcentages. | Lanceur .bat + Git Bash |
| [WinMirrorImages](WinMirrorImages/) | Créer une copie des images avec un miroir horizontal. | Lanceur .bat + Git Bash |
| [WinVideoToImages](WinVideoToImages/) | Extraire toutes les images d’une vidéo et enregistrer les informations FFprobe. | Lanceur .bat + Git Bash |
| [WinLastVideoFrameToImage](WinLastVideoFrameToImage/) | Extraire la dernière image d’une vidéo au format PNG. | Lanceur .bat + Git Bash |
| [WinWebpToMp4](WinWebpToMp4/) | Ancien traitement des WebP animés : extraction et recomposition d’images PNG. | Lanceur .bat + Git Bash |

Pour obtenir directement un MP4 à partir d’un WebP animé, utiliser **WinWebpVideoToMp4**. Le script principal actuel de `WinWebpToMp4` prépare des images PNG ; son nom correspond à un ancien flux de conversion.

## Prérequis

Les programmes tiers ne sont pas inclus dans ce dépôt. Installer ceux dont l’outil choisi a besoin.

| Prérequis | Outils concernés |
|---|---|
| Windows 10 ou 11 et Windows PowerShell 5.1 | Outils avec installation dans « Envoyer vers ». |
| ImageMagick 7, commande `magick.exe` | Conversion et traitement des images, création des PDF et lecture des WebP animés. |
| qpdf, commande `qpdf.exe` | WinMergePDFs. |
| FFmpeg, commandes `ffmpeg.exe` et `ffprobe.exe` | Conversion en MP4 et extraction d’images de vidéos ; FFprobe est utilisé par WinVideoToImages. |
| Git Bash | Outils utilisant les scripts `.sh`. |
| libwebp, commande `webpmux.exe` | Facultatif pour WinWebpVideoToMp4, qui l’utilise pour lire les durées exactes des images ; requis par l’ancien WinWebpToMp4. |

Pour les outils PowerShell, ajouter les exécutables au `PATH` facilite leur détection. Les scripts cherchent aussi dans plusieurs emplacements d’installation courants. Certains anciens lanceurs Bash utilisent des chemins fixes : voir la section correspondante ci-dessous.

## Installation dans « Envoyer vers »

Cette procédure concerne **WinImgToJpg**, **WinImagesToPDF**, **WinMergePDFs**, **WinLogoToImg** et **WinWebpVideoToMp4**.

1. Cloner le dépôt ou télécharger et extraire son archive.
2. Installer les prérequis de l’outil choisi.
3. Ouvrir le dossier de cet outil et lancer `Installer.bat`.
4. Dans l’Explorateur Windows, sélectionner les fichiers à traiter.
5. Faire **clic droit → Envoyer vers**, puis choisir l’outil.

Sous Windows 11, le menu « Envoyer vers » peut se trouver dans **Afficher plus d’options**. L’installation des scripts se fait pour l’utilisateur courant, sans droit administrateur.

L’installateur copie le programme dans `%LOCALAPPDATA%\NomDeLOutil` et ajoute une entrée dans le dossier Windows « Envoyer vers ». Chaque outil possède son propre installateur : il n’y a pas d’installation globale.

**Après une mise à jour des sources, relancer `Installer.bat` pour mettre à jour la copie exécutée par « Envoyer vers ».**

Pour retirer un outil du menu, lancer son `Desinstaller.bat`.

## Exemples d’utilisation

### Convertir des images en JPG

Sélectionner les images, puis **Envoyer vers → WinImgToJpg - Convertir en JPG**.

Les résultats sont créés à côté des originaux. La transparence est remplacée par un fond blanc. Un fichier JPEG source reçoit le suffixe `_q90` pour éviter de réécrire l’original.

### Créer ou fusionner des PDF

- **WinImagesToPDF** : sélectionner des images, ou envoyer un dossier pour prendre toutes ses images en charge.
- **WinMergePDFs** : sélectionner au moins deux PDF, ou envoyer un dossier contenant les PDF à fusionner.

Les fichiers sont triés par leur nom, avec un ordre naturel : `page2` précède `page10`. Pour une sélection très importante, envoyer le dossier ou utiliser la sélection proposée par le lanceur permet d’éviter la limite de longueur des commandes Windows.

### Ajouter un logo ou un filigrane

1. Sélectionner **exactement deux images** : le parent et le logo.
2. Choisir **Envoyer vers → WinLogoToImg - Ajouter un logo**.
3. Une fenêtre montre l’image ayant le moins de pixels :
   - **Entrée / y / Y** : cette image est le logo ;
   - **n / N** : l’autre image est le logo ;
   - **Échap** : annuler.
4. Le logo conserve ses proportions, prend **2/3 de la largeur du parent** et est centré horizontalement et verticalement.

Pour un parent `photo.jpg`, deux fichiers sont créés dans son dossier :

```text
photo_wtrked.png
photo_wtrked.jpg
```

Le PNG conserve la transparence ; le JPG utilise un fond blanc pour les zones encore transparentes. Si un nom existe déjà, les deux exports reçoivent un numéro, par exemple `photo_wtrked (1).png` et `photo_wtrked (1).jpg`.

La taille du parent est conservée. Un logo très haut peut dépasser du cadre : les parties qui dépassent sont coupées tout en gardant la largeur demandée de 2/3.

### Convertir un WebP animé en MP4

Sélectionner un ou plusieurs WebP animés, puis **Envoyer vers → WinWebpVideoToMp4 - Convertir en MP4**.

Le résultat est un MP4 H.264 placé à côté du WebP. Un WebP contenant une seule image est refusé. Si `webpmux.exe` est absent, le script utilise les durées données par ImageMagick, avec un arrondi au centième de seconde.

### Lancer les outils depuis un terminal

Exemples à exécuter depuis la racine du dépôt, dans PowerShell :

```powershell
.\WinImgToJpg\WinImgToJpg.bat "C:\Images\photo.png"
.\WinImagesToPDF\WinImagesToPDF.bat -NoDialog "C:\Images"
.\WinMergePDFs\WinMergePDFs.bat -NoDialog "C:\Documents\partie1.pdf" "C:\Documents\partie2.pdf"
.\WinLogoToImg\WinLogoToImg.bat "C:\Images\photo.jpg" "C:\Images\logo.png"
```

## Outils utilisant Git Bash

Ces outils n’ont pas d’installateur « Envoyer vers ». Leurs lanceurs `.bat` appellent un script `.sh` et utilisent soit le dossier courant, soit une sélection de fichier dans la console.

**Avant de les utiliser**, adapter les chemins fixes dans les lanceurs et scripts : emplacement de Git Bash, du script `.sh` et, selon l’outil, de FFmpeg, ImageMagick ou libwebp. Plusieurs lanceurs conservent un chemin vers `C:/projects/scripts/<outil>` ; ce chemin doit correspondre à l’emplacement réel du dossier concerné après le clonage.

| Outil | Lanceur | Résultat |
|---|---|---|
| WinCropImages | `crop_images.bat` | Images recadrées dans le sous-dossier `cropped`. Régler d’abord `x1`, `y1`, `x2`, `y2` entre 0 et 100, avec `x2 > x1` et `y2 > y1` ; les valeurs présentes dans le lanceur doivent être adaptées. |
| WinMirrorImages | `mirror_images.bat` | Copies avec miroir horizontal dans `mirrored`. |
| WinVideoToImages | `convert_video_to_images.bat` | Images `frame_00001.png`, etc., et fichier `ffprobe.txt`, dans un dossier portant le suffixe `_frame-images`. |
| WinLastVideoFrameToImage | `_win_last_video_frame_to_image.bat` | Image PNG portant le suffixe `_last-frame`. |
| WinWebpToMp4 | `win_webp_to_mp4.bat` | Images PNG recomposées dans un dossier portant le suffixe `_fullframes`. |

Les anciens fichiers `WinImagesToPDF.sh` et `WinWebpToMp4.old.sh` sont conservés dans le dépôt ; les parcours actuels à privilégier sont décrits plus haut.

## Réglages et dépannage

Les réglages de qualité, de fond et de messages se trouvent au début des scripts PowerShell. Avec les réglages par défaut, les cinq outils disposant d’un installateur conservent les originaux et choisissent un nouveau nom si une sortie existe déjà.

En cas de programme tiers introuvable, vérifier sa présence dans le `PATH` ou dans les emplacements recherchés par le script. Les formats comme HEIC, AVIF ou JPEG XL dépendent des capacités de l’installation ImageMagick utilisée.

Pour **WinLogoToImg**, `Diagnostic.bat` lance le traitement avec une console visible, affiche le code de sortie et les dernières lignes du journal :

```powershell
.\WinLogoToImg\Diagnostic.bat "C:\Images\photo.jpg" "C:\Images\logo.png"
```

Son journal principal est `%LOCALAPPDATA%\WinLogoToImg\WinLogoToImg.log`, avec un repli dans `%TEMP%\WinLogoToImg\WinLogoToImg.log`. Les erreurs précoces de PowerShell sont conservées dans `%TEMP%\WinLogoToImg-error.log`.

Les journaux peuvent contenir les noms et chemins des fichiers traités : vérifier leur contenu avant de les partager et les garder hors du dépôt, avec les médias de travail et configurations locales.

## Documentation par outil

- [WinImgToJpg — installation, formats et réglages](WinImgToJpg/README.txt)
- [WinImagesToPDF — création de PDF et ordre des pages](WinImagesToPDF/README.txt)
- [WinMergePDFs — fusion et prérequis qpdf](WinMergePDFs/README.txt)
- [WinLogoToImg — choix du logo, exports et diagnostic](WinLogoToImg/README.txt)
- [WinWebpVideoToMp4 — conversion, durées et qualité vidéo](WinWebpVideoToMp4/README.txt)
