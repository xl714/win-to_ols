@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinMergePDFs"
set "SENDTO_DIR=%APPDATA%\Microsoft\Windows\SendTo"
set "SENDTO_FILE=%SENDTO_DIR%\WinMergePDFs - Fusionner les PDF.bat"

if not exist "%~dp0WinMergePDFs.ps1" (
    echo ERREUR : WinMergePDFs.ps1 est introuvable dans ce dossier.
    pause
    exit /b 1
)

if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinMergePDFs.ps1" "%APP_DIR%\WinMergePDFs.ps1" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinMergePDFs.bat" "%APP_DIR%\WinMergePDFs.bat" >nul
if errorlevel 1 goto :copy_error

copy /Y "%~dp0WinMergePDFs-SendTo.bat" "%SENDTO_FILE%" >nul
if errorlevel 1 goto :copy_error

echo.
echo WinMergePDFs est installe.
echo.
echo Utilisation : selectionne au moins deux PDF dans l'Explorateur,
echo puis clic droit ^> Envoyer vers ^> WinMergePDFs - Fusionner les PDF.
echo.

where qpdf.exe >nul 2>nul
if errorlevel 1 (
    echo ATTENTION : qpdf.exe n'est pas visible dans le PATH.
    echo Le script cherchera aussi qpdf dans les dossiers d'installation habituels.
    echo Si la fusion echoue, installe qpdf avec : winget install --id QPDF.QPDF -e
    echo.
)

pause
exit /b 0

:copy_error
echo.
echo ERREUR : impossible d'installer WinMergePDFs.
echo Verifie les droits d'ecriture dans AppData, puis recommence.
pause
exit /b 1
