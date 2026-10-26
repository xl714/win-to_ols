@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinImagesToPDF"
set "SENDTO_FILE=%APPDATA%\Microsoft\Windows\SendTo\WinImagesToPDF - Convertir en PDF.bat"

if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"
if exist "%APP_DIR%" rmdir /S /Q "%APP_DIR%"

echo.
echo WinImagesToPDF a ete desinstalle.
echo.
pause
