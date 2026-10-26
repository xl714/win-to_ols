@echo off
setlocal EnableExtensions

set "APP_DIR=%LOCALAPPDATA%\WinImgToJpg"
set "SENDTO_FILE=%APPDATA%\Microsoft\Windows\SendTo\WinImgToJpg - Convertir en JPG.bat"

if exist "%SENDTO_FILE%" del /Q "%SENDTO_FILE%"
if exist "%APP_DIR%" rmdir /S /Q "%APP_DIR%"

echo.
echo WinImgToJpg a ete desinstalle.
echo.
pause
