@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "APP_DIR=%LOCALAPPDATA%\WinLogoToImg"
set "SENDTO_DIR=%APPDATA%\Microsoft\Windows\SendTo"
set "SENDTO_FILE=%SENDTO_DIR%\WinLogoToImg - Ajouter un logo.bat"
set "SENDTO_LINK=%SENDTO_DIR%\WinLogoToImg - Ajouter un logo.lnk"

if not exist "%~dp0WinLogoToImg.ps1" goto :missing_file
if not exist "%~dp0WinLogoToImg.bat" goto :missing_file
if not exist "%~dp0WinLogoToImg-SendTo.bat" goto :missing_file
if not exist "%~dp0Diagnostic.bat" goto :missing_file

if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if errorlevel 1 goto :install_error
if not exist "%SENDTO_DIR%" mkdir "%SENDTO_DIR%"
if errorlevel 1 goto :install_error

copy /Y "%~dp0WinLogoToImg.ps1" "%APP_DIR%\WinLogoToImg.ps1" >nul
if errorlevel 1 goto :install_error
copy /Y "%~dp0WinLogoToImg.bat" "%APP_DIR%\WinLogoToImg.bat" >nul
if errorlevel 1 goto :install_error
copy /Y "%~dp0Diagnostic.bat" "%APP_DIR%\Diagnostic.bat" >nul
if errorlevel 1 goto :install_error
if not exist "%APP_DIR%\Diagnostic.bat" goto :install_error
rem Le raccourci garde le chemin absolu du programme installe, sans dependre
rem de LOCALAPPDATA au moment de son lancement depuis l'Explorateur.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $shell = New-Object -ComObject WScript.Shell; $link = $shell.CreateShortcut($env:SENDTO_LINK); $link.TargetPath = Join-Path $env:APP_DIR 'WinLogoToImg.bat'; $link.WorkingDirectory = $env:APP_DIR; $link.WindowStyle = 1; $link.Description = 'Ajouter un logo et enregistrer en PNG et JPG'; $link.Save()"
if errorlevel 1 goto :install_error
if not exist "%SENDTO_LINK%" goto :install_error
rem Migration de l'ancienne entree, uniquement apres creation du raccourci.
if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"

echo.
echo WinLogoToImg 1.1 est installe.
echo Selectionne 2 images, puis clic droit ^> Envoyer vers ^> WinLogoToImg - Ajouter un logo.
echo Sous Windows 11, utilise si besoin "Afficher plus d'options".
echo.
if /I not "%~1"=="/quiet" pause
exit /b 0

:missing_file
echo ERREUR : un fichier de WinLogoToImg est manquant. Garde tous les fichiers ensemble.
if /I not "%~1"=="/quiet" pause
exit /b 1

:install_error
echo ERREUR : impossible d'installer WinLogoToImg. Verifie les droits d'ecriture dans AppData.
if /I not "%~1"=="/quiet" pause
exit /b 1
