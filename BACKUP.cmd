@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo    BHU Control App - Backup
echo ============================================
echo.
echo Seleccione tipo de backup:
echo   [1] Codigo fuente (proyecto limpio)
echo   [2] Completo (carpeta padre Android)
echo.

if "%1"=="" (
    echo Usage: BACKUP.cmd [1^|2]
    echo.
    pause
    exit /b 1
)

set "opcion=%1"

if "%opcion%"=="1" goto :codigo_fuente
if "%opcion%"=="2" goto :completo

echo.
echo Opcion invalida
echo.
pause
exit /b 1

:codigo_fuente
echo.
echo === BACKUP DE CODIGO FUENTE ===
echo.

cd /d "%~dp0"

for /f %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm'"') do set "timestamp=%%a"

set "backupname=bhu_control_app_src_%timestamp%"

if not exist backups mkdir backups

set "excludes=backups,build,.idea,windows"
powershell -Command "$exclude = '%excludes%' -split ','; $items = Get-ChildItem -Path '.' -Directory | Where-Object { $exclude -notcontains $_.Name }; Compress-Archive -Path $items -DestinationPath 'backups\%backupname%.zip' -Force"

for %%I in (backups\%backupname%.zip) do set "size=%%~zI"

echo.
echo ============================================
echo    BACKUP COMPLETADO
echo ============================================
echo.
echo Tipo: Codigo fuente
echo Archivo: backups\%backupname%.zip
echo Tamano: %size% bytes
echo.
pause
goto :fin

:completo
echo.
echo === BACKUP COMPLETO ===
echo.

cd /d "%~dp0"

for /f %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm'"') do set "timestamp=%%a"

set "backupname=bhu_control_app_full_%timestamp%"

if not exist backups mkdir backups

set "source_dir=%~dp0"

echo Comprimiendo carpeta bhu_control_app con compresion maxima...
powershell -Command "$items = Get-ChildItem -Path '%source_dir%' -Exclude 'nul','backups'; Compress-Archive -Path $items -DestinationPath 'backups\%backupname%.zip' -CompressionLevel Optimal -Force"

for %%I in (backups\%backupname%.zip) do set "size=%%~zI"

echo.
echo ============================================
echo    BACKUP COMPLETADO
echo ============================================
echo.
echo Tipo: Completo
echo Archivo: backups\%backupname%.zip
echo Tamano: %size% bytes
echo.
pause

:fin
endlocal
