@echo off
setlocal EnableExtensions

REM ============================================================================
REM ANCIEN MODE (conserve pour compatibilite).
REM Ce fichier n'a plus besoin d'etre copie dans les dossiers d'images :
REM lance Installer.bat une fois, puis selectionne les images dans
REM l'Explorateur et fais clic droit > Envoyer vers >
REM "WinImagesToPDF - Convertir en PDF".
REM
REM Si tu double-cliques quand meme sur une copie de ce fichier, il convertit
REM toutes les images du dossier courant, comme avant (sans Git Bash).
REM ============================================================================

set "INSTALLED_APP=%LOCALAPPDATA%\WinImagesToPDF\WinImagesToPDF.bat"
set "REPO_APP=C:\projects\scripts\WinImagesToPDF\WinImagesToPDF.bat"

if exist "%INSTALLED_APP%" (
    call "%INSTALLED_APP%" "%cd%"
) else if exist "%REPO_APP%" (
    call "%REPO_APP%" "%cd%"
) else (
    echo WinImagesToPDF est introuvable.
    echo Lance Installer.bat depuis C:\projects\scripts\WinImagesToPDF d'abord.
)

pause
