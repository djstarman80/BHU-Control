@echo off
chcp 65001 >nul
setlocal

echo ============================================
echo    BHU Control App - Backup del Proyecto
echo ============================================
echo.

cd /d "%~dp0"

:: Configurar nombre del backup
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%"

set "backupname=bhu_control_app_backup_%timestamp%"

echo [1/3] Creando directorio de backup...
if not exist backups mkdir backups
echo        OK
echo.

echo [2/3] Comprimiendo archivos...
powershell -Command "Compress-Archive -Path '.' -DestinationPath 'backups\%backupname%.zip' -Force" 2>nul
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
