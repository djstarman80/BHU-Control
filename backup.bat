@echo off
setlocal enabledelayedexpansion

:: Obtener fecha y hora actual
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a-%%b)
set filename=backup-src_!mydate!_!mytime!.zip

echo Creando backup: !filename!
powershell -Command "Compress-Archive -Path 'lib','android','pubspec.yaml','pubspec.lock','README.md' -DestinationPath '!filename!' -Force"
echo Backup creado: !filename!
pause
