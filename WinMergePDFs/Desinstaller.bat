@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinMergePDFs"
set "SENDTO_FILE=%APPDATA%\Microsoft\Windows\SendTo\WinMergePDFs - Fusionner les PDF.bat"

if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"
if exist "%APP_DIR%" rmdir /S /Q "%APP_DIR%"

echo.
echo WinMergePDFs a ete desinstalle.
echo.
pause
