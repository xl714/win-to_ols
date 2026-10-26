@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "WINLOGO_ERROR_LOG=%TEMP%\WinLogoToImg-error.log"
set "WINLOGO_LOG=%LOCALAPPDATA%\WinLogoToImg\WinLogoToImg.log"
set "WINLOGO_FALLBACK_LOG=%TEMP%\WinLogoToImg\WinLogoToImg.log"

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0WinLogoToImg.ps1" %* 2>"%WINLOGO_ERROR_LOG%"
set "WINLOGO_EXIT_CODE=%ERRORLEVEL%"
echo.
echo WinLogoToImg - diagnostic - code de sortie : %WINLOGO_EXIT_CODE%
if not "%WINLOGO_EXIT_CODE%"=="0" if exist "%WINLOGO_ERROR_LOG%" type "%WINLOGO_ERROR_LOG%"
echo.
echo Dernieres lignes du journal :
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "$path = $env:WINLOGO_LOG; if (-not (Test-Path -LiteralPath $path)) { $path = $env:WINLOGO_FALLBACK_LOG }; if (Test-Path -LiteralPath $path) { Write-Output $path; Get-Content -LiteralPath $path -Encoding UTF8 -Tail 30 } else { Write-Output 'Journal indisponible.' }"
echo.
pause
exit /b %WINLOGO_EXIT_CODE%
