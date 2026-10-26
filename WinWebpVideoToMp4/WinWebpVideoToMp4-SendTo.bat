@echo off
setlocal EnableExtensions

call "%LOCALAPPDATA%\WinWebpVideoToMp4\WinWebpVideoToMp4.bat" %*
exit /b %ERRORLEVEL%
