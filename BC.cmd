@echo off
chcp 65001 >nul
setlocal

echo ============================================
echo    BHU Control App - Backup del Proyecto
echo ============================================
echo.

cd /d "%~dp0"

:: Configurar nombre del backup usando PowerShell (alternativa moderna a wmic)
for /f %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm'"') do set "timestamp=%%a"

set "backupname=bhu_control_app_backup_%timestamp%"

echo [1/3] Creando directorio de backup...
if not exist backups mkdir backups
echo        OK
echo.

echo [2/3] Comprimiendo archivos...
set "excludes=backups,build,.idea,windows"
powershell -Command "$exclude = '%excludes%' -split ','; $items = Get-ChildItem -Path '.' -Directory | Where-Object { $exclude -notcontains $_.Name }; Compress-Archive -Path $items -DestinationPath 'backups\%backupname%.zip' -Force"
if %errorlevel% neq 0 (
    echo ERROR: Fallo al comprimir archivos
    pause
    exit /b 1
)
echo        OK
echo.

echo [3/3] Obteniendo tamanio del backup...
for %%I in (backups\%backupname%.zip) do set "size=%%~zI"
echo        Backup: %backupname%.zip (%size% bytes)
echo.

echo ============================================
echo    BACKUP COMPLETADO
echo ============================================
echo.
echo Ubicacion:
echo    backups\%backupname%.zip
echo.
echo Para restaurar:
echo 1. Extraer el archivo .zip
echo 2. Copiar los archivos sobre el proyecto
echo.
pause
endlocal