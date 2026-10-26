@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "APP_DIR=%LOCALAPPDATA%\WinLogoToImg"
set "SENDTO_FILE=%APPDATA%\Microsoft\Windows\SendTo\WinLogoToImg - Ajouter un logo.bat"
set "SENDTO_LINK=%APPDATA%\Microsoft\Windows\SendTo\WinLogoToImg - Ajouter un logo.lnk"

if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"
if exist "%SENDTO_LINK%" del /Q "%SENDTO_LINK%"
if exist "%APP_DIR%\WinLogoToImg.ps1" del /Q "%APP_DIR%\WinLogoToImg.ps1"
if exist "%APP_DIR%\WinLogoToImg.bat" del /Q "%APP_DIR%\WinLogoToImg.bat"
if exist "%APP_DIR%\Diagnostic.bat" del /Q "%APP_DIR%\Diagnostic.bat"
if exist "%APP_DIR%\WinLogoToImg.log" del /Q "%APP_DIR%\WinLogoToImg.log"
if exist "%APP_DIR%\WinLogoToImg.log.1" del /Q "%APP_DIR%\WinLogoToImg.log.1"
rem Suppression uniquement si le dossier est vide ; aucun autre fichier n'est efface.
if exist "%APP_DIR%" rmdir "%APP_DIR%" 2>nul

echo.
echo WinLogoToImg a ete desinstalle.
echo Le dossier source et les images creees sont conserves.
echo.
if /I not "%~1"=="/quiet" pause
exit /b 0
