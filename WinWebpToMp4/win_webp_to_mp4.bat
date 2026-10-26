@echo off
chcp 1252 >nul
setlocal enabledelayedexpansion

REM recupere le repertoire courant
set "target_dir=%cd%"

REM collecte les webp
set count=0
for /f "delims=" %%F in ('dir "%target_dir%\*.webp" /b /a:-d') do (
  set /a count+=1
  set "file[!count!]=%%F"
)

if %count% equ 0 (
  echo Aucun .webp trouve dans %target_dir%
  goto end
)

echo Fichiers webp trouves :
for /L %%i in (1,1,%count%) do (
  echo   [%%i] !file[%%i]!
)

:ask
set "prompt=Entrez l'index (1-%count%) ou [Entree] pour tout traiter : "
set /p "sel=%prompt%"

if "%sel%"=="" goto runall

REM verifie si index numerique valide
for /f "delims=0123456789" %%A in ("%sel%") do (
  echo Index invalide : "%sel%"
  goto ask
)

if %sel% lss 1 goto ask
if %sel% gtr %count% goto ask

set "chosen=!file[%sel%]!"
goto runfile

:runfile
echo Traitement du fichier selectionne :
echo   %chosen%
"C:\Program Files\Git\bin\bash.exe" "C:/projects/scripts/WinWebpToMp4/WinWebpToMp4.sh" "%target_dir%\%chosen%"
goto end

:runall
echo Traitement de tous les .webp dans :
echo   %target_dir%
"C:\Program Files\Git\bin\bash.exe" "C:/projects/scripts/WinWebpToMp4/WinWebpToMp4.sh" "%target_dir%"
goto end

:end
pause
