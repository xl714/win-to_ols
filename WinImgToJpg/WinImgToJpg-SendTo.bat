@echo off
setlocal EnableExtensions

call "%LOCALAPPDATA%\WinImgToJpg\WinImgToJpg.bat" %*
exit /b %ERRORLEVEL%
