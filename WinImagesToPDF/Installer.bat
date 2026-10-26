@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinImagesToPDF"
set "SENDTO_DIR=%APPDATA%\Microsoft\Windows\SendTo"
set "SENDTO_FILE=%SENDTO_DIR%\WinImagesToPDF - Convertir en PDF.bat"

if not exist "%~dp0WinImagesToPDF.ps1" (
    echo ERREUR : WinImagesToPDF.ps1 est introuvable dans ce dossier.
    pause
    exit /b 1
)

if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImagesToPDF.ps1" "%APP_DIR%\WinImagesToPDF.ps1" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImagesToPDF.bat" "%APP_DIR%\WinImagesToPDF.bat" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinImagesToPDF-SendTo.bat" "%SENDTO_FILE%" >nul
if errorlevel 1 goto :copy_error

echo.
echo WinImagesToPDF est installe.
echo.
echo Utilisation : selectionne les images dans l'Explorateur,
echo puis clic droit ^> Envoyer vers ^> WinImagesToPDF - Convertir en PDF.
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
echo ERREUR : impossible d'installer WinImagesToPDF.
echo Verifie les droits d'ecriture dans AppData, puis recommence.
pause
exit /b 1
