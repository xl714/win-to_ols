@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinWebpVideoToMp4"
set "SENDTO_DIR=%APPDATA%\Microsoft\Windows\SendTo"
set "SENDTO_FILE=%SENDTO_DIR%\WinWebpVideoToMp4 - Convertir en MP4.bat"

if not exist "%~dp0WinWebpVideoToMp4.ps1" (
    echo ERREUR : WinWebpVideoToMp4.ps1 est introuvable dans ce dossier.
    pause
    exit /b 1
)

if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinWebpVideoToMp4.ps1" "%APP_DIR%\WinWebpVideoToMp4.ps1" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinWebpVideoToMp4.bat" "%APP_DIR%\WinWebpVideoToMp4.bat" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinWebpVideoToMp4-SendTo.bat" "%SENDTO_FILE%" >nul
if errorlevel 1 goto :copy_error

echo.
echo WinWebpVideoToMp4 est installe.
echo.
echo Utilisation : clic droit sur un ou plusieurs WebP animes,
echo puis Envoyer vers ^> WinWebpVideoToMp4 - Convertir en MP4.
echo.

where magick.exe >nul 2>nul
if errorlevel 1 (
    echo ATTENTION : magick.exe n'est pas visible dans le PATH.
    echo Le script cherchera aussi ImageMagick dans les dossiers d'installation habituels.
    echo Si la conversion echoue, installe ImageMagick 7 avec l'option d'ajout au PATH.
    echo.
)

where ffmpeg.exe >nul 2>nul
if errorlevel 1 (
    if not exist "%ProgramFiles%\ffmpeg\bin\ffmpeg.exe" (
        echo ATTENTION : ffmpeg.exe n'est pas visible dans le PATH.
        echo Le script cherchera aussi ffmpeg dans les dossiers d'installation habituels.
        echo Si la conversion echoue, installe ffmpeg dans "C:\Program Files\ffmpeg\bin".
        echo.
    )
)

pause
exit /b 0

:copy_error
echo.
echo ERREUR : impossible d'installer WinWebpVideoToMp4.
echo Verifie les droits d'ecriture dans AppData, puis recommence.
pause
exit /b 1
