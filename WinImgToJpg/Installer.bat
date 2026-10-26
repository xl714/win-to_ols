@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinImgToJpg"
set "SENDTO_DIR=%APPDATA%\Microsoft\Windows\SendTo"
set "SENDTO_FILE=%SENDTO_DIR%\WinImgToJpg - Convertir en JPG.bat"

if not exist "%~dp0WinImgToJpg.ps1" (
    echo ERREUR : WinImgToJpg.ps1 est introuvable dans ce dossier.
    pause
    exit /b 1
)

if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImgToJpg.ps1" "%APP_DIR%\WinImgToJpg.ps1" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImgToJpg.bat" "%APP_DIR%\WinImgToJpg.bat" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImgToJpg-SendTo.bat" "%SENDTO_FILE%" >nul
if errorlevel 1 goto :copy_error

echo.
echo WinImgToJpg est installe.
echo.
echo Utilisation : clic droit sur une ou plusieurs images,
echo puis Envoyer vers ^> WinImgToJpg - Convertir en JPG.
echo.

where magick.exe >nul 2>nul
if errorlevel 1 (
    echo ATTENTION : magick.exe n'est pas visible dans le PATH.
    echo Le script cherchera aussi ImageMagick dans les dossiers d'installation habituels.
    echo Si la conversion echoue, installe ImageMagick 7 avec l'option d'ajout au PATH.
    echo.
)

pause
exit /b 0

:copy_error
echo.
echo ERREUR : impossible d'installer WinImgToJpg.
echo Verifie les droits d'ecriture dans AppData, puis recommence.
pause
exit /b 1
