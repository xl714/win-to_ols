@echo off
setlocal

REM récupère le dossier courant
set "target_dir=%cd%"

REM appelle le script Bash en lui passant le répertoire
"C:\Program Files\Git\bin\bash.exe" "C:/projects/scripts/WinMirrorImages/WinMirrorImages.sh" "%target_dir%"

pause
