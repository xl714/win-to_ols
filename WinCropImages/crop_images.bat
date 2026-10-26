@echo off
setlocal

REM ← Coordonnées de crop (à ajuster)
set "x1=0"
set "y1=0"
set "x2=200"
set "y2=400"

REM ← Répertoire courant
set "target_dir=%cd%"

REM ← Appel du script Bash avec les 5 arguments
"C:\Program Files\Git\bin\bash.exe" "C:/projects/scripts/WinCropImages/WinCropImages.sh" "%target_dir%" "%x1%" "%y1%" "%x2%" "%y2%"

pause
