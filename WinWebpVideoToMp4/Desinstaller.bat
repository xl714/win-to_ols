@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinWebpVideoToMp4"
set "SENDTO_FILE=%APPDATA%\Microsoft\Windows\SendTo\WinWebpVideoToMp4 - Convertir en MP4.bat"

if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"
if exist "%APP_DIR%" rmdir /S /Q "%APP_DIR%"

echo.
echo WinWebpVideoToMp4 a ete desinstalle.
echo.
pause
