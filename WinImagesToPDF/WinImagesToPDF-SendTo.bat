@echo off
setlocal EnableExtensions

echo Creation du PDF en cours...
call "%LOCALAPPDATA%\WinImagesToPDF\WinImagesToPDF.bat" %*
exit /b %ERRORLEVEL%
