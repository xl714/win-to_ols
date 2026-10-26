@echo off
setlocal EnableExtensions

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0WinWebpVideoToMp4.ps1" %*
exit /b %ERRORLEVEL%
