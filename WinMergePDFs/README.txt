WinMergePDFs
============

But
---
Fusionner plusieurs PDF en un seul, dans l'ordre alphanumerique des noms de
fichiers, depuis le menu Windows "Envoyer vers".

Prerequis
---------
- Windows 10 ou Windows 11
- qpdf (outil gratuit en ligne de commande). Pour l'installer :

    winget install --id QPDF.QPDF -e

  ou telecharge le zip sur https://github.com/qpdf/qpdf/releases et
  decompresse-le dans %LOCALAPPDATA%\Programs (par exemple
  %LOCALAPPDATA%\Programs\qpdf-12.4.1-msvc64\bin\qpdf.exe).
  Le script cherche qpdf dans le PATH, dans Program Files, dans
  %LOCALAPPDATA%\Programs et a cote de lui-meme (dossier qpdf*\bin).

Installation
------------
1. Laisse tous les fichiers de ce dossier ensemble.
2. Double-clique sur Installer.bat.
3. Aucun droit administrateur n'est necessaire.

Utilisation
-----------
1. Selectionne au moins deux PDF dans l'Explorateur Windows.
2. Clic droit > Envoyer vers > WinMergePDFs - Fusionner les PDF.
3. Sous Windows 11, "Envoyer vers" peut se trouver dans
   "Afficher plus d'options".

Tu peux aussi :
- Double-cliquer sur WinMergePDFs.bat : une boite de selection de PDF
  s'ouvre.
- Envoyer un DOSSIER vers WinMergePDFs : tous les PDF du dossier (sans
  les sous-dossiers) sont fusionnes.

Comportement
------------
- Le PDF est cree dans le dossier du premier PDF (apres tri).
- Nom du PDF = nom du premier PDF + " - fusion".
  Exemple : facture1.pdf + facture2.pdf -> "facture1 - fusion.pdf".
- Si ce nom existe deja : "facture1 - fusion (1).pdf", puis "(2)", etc.
  Aucun fichier existant n'est jamais ecrase.
- Ordre des fichiers : tri "naturel" comme l'Explorateur Windows
  (doc2 avant doc10), quel que soit l'ordre de selection.
- Seuls les fichiers .pdf sont pris en compte. Les autres fichiers
  selectionnes sont ignores et listes dans le message final.
- Les pages sont copiees telles quelles (texte, images, liens dans la
  page), sans recompression ni perte de qualite. Les signets (bookmarks)
  des PDF d'origine ne sont pas conserves.
- Un PDF protege par un mot de passe d'ouverture fait echouer la fusion ;
  le message d'erreur de qpdf est alors affiche.
- Un PDF legerement abime est repare a la volee : le PDF est cree et les
  avertissements de qpdf sont affiches.
- Une boite de dialogue resume le resultat (nom du PDF, nombre de pages,
  ordre des fichiers, fichiers ignores).

Limite connue
-------------
Si tu selectionnes enormement de fichiers d'un coup (plusieurs centaines),
Windows peut tronquer la ligne de commande du menu "Envoyer vers".
Dans ce cas, envoie plutot le DOSSIER vers WinMergePDFs, ou double-clique
sur WinMergePDFs.bat et choisis les PDF dans la boite de dialogue.

Lancement manuel
----------------
Depuis un terminal :

  "%LOCALAPPDATA%\WinMergePDFs\WinMergePDFs.bat" "C:\Docs\partie1.pdf" "C:\Docs\partie2.pdf"

ou pour un dossier entier :

  "%LOCALAPPDATA%\WinMergePDFs\WinMergePDFs.bat" "C:\Docs"

Option -NoDialog : affiche le resultat dans la console au lieu d'une boite
de dialogue (pratique pour les scripts).

Reglages
--------
Les reglages se trouvent au debut de WinMergePDFs.ps1 :
- $OutputSuffix       : suffixe ajoute au nom du premier PDF (" - fusion")
- $ShowSuccessMessage : $false pour ne rien afficher si tout va bien
- $OverwriteExisting  : $true pour ecraser un PDF "- fusion" existant au
                        lieu de creer "nom (1).pdf" (un PDF d'entree n'est
                        jamais ecrase, quel que soit ce reglage)

Desinstallation
---------------
Double-clique sur Desinstaller.bat.
