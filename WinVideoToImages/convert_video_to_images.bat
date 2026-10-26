@echo off
setlocal enabledelayedexpansion

:: Prérequis :
:: - FFmpeg dans C:\Program Files\ffmpeg\bin\ffmpeg.exe
:: - ImageMagick dans C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe
:: - WinVideoToImages.sh dans C:/projects/scripts/WinVideoToImages/

REM 1) Lister les fichiers vidéos du dossier courant
set i=0
for %%f in (*.mp4 *.avi *.mov *.mkv *.webp) do (
    set /a i+=1
    set "file[!i!]=%%f"
    echo [!i!] %%f
)
if %i%==0 (
    echo Aucune vidéo trouvee dans le dossier courant.
    pause
    exit /b
)

REM 2) Demander l'index
set /p idx=Entrez l'index de la video a decouper en images :
if not defined file[%idx%] (
    echo Index invalide.
    pause
    exit /b
)

set "selectedfile=!file[%idx%]!"
set "videofilepath=%cd%\!selectedfile!"

REM 3) Extraire l'extension et le nom de base
for %%F in ("!selectedfile!") do (
    set "ext=%%~xF"
    set "base=%%~nF"
)

REM 4) Si c'est un WebP animé, convertir en GIF coalescé
if /I "!ext!"==".webp" (
    echo WebP anime detecte, conversion en GIF coalesce...
    "C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe" "!videofilepath!" -coalesce "%cd%\!base!.gif"
    set "videofilepath=%cd%\!base!.gif"
)

REM 5) Appeler le script Bash pour extraire les images
"C:\Program Files\Git\bin\bash.exe" "C:/projects/scripts/WinVideoToImages/WinVideoToImages.sh" "%videofilepath%"

pause
