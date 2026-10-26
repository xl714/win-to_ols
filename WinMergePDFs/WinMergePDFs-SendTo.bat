@echo off
setlocal EnableExtensions

echo Fusion des PDF en cours...
call "%LOCALAPPDATA%\WinMergePDFs\WinMergePDFs.bat" %*
exit /b %ERRORLEVEL%
