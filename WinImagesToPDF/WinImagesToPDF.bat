@echo off
setlocal EnableExtensions

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0WinImagesToPDF.ps1" %*
exit /b %ERRORLEVEL%
