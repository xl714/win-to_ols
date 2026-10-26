@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "WINLOGO_ERROR_LOG=%TEMP%\WinLogoToImg-error.log"

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0WinLogoToImg.ps1" %* 2>"%WINLOGO_ERROR_LOG%"
set "WINLOGO_EXIT_CODE=%ERRORLEVEL%"
if "%WINLOGO_EXIT_CODE%"=="0" exit /b 0

echo.
echo ERREUR : WinLogoToImg n'a pas pu terminer le traitement.
if exist "%WINLOGO_ERROR_LOG%" type "%WINLOGO_ERROR_LOG%"
echo.
echo Journal : "%WINLOGO_ERROR_LOG%"
echo Journal detaille : "%LOCALAPPDATA%\WinLogoToImg\WinLogoToImg.log"
echo Repli du journal : "%TEMP%\WinLogoToImg\WinLogoToImg.log"
echo Cette fenetre reste ouverte pour permettre de lire l'erreur.
pause
exit /b %WINLOGO_EXIT_CODE%
