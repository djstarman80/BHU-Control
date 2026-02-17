@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo    BHU Control App - Restaurar Backup
echo ============================================
echo.

cd /d "%~dp0"

:: Verificar si existen backups
if not exist backups (
    echo ERROR: No existe la carpeta 'backups'
    echo Crea un backup primero con: backup.bat
    pause
    exit /b 1
)

:: Contar backups disponibles
set count=0
for %%f in (backups\*.zip) do (
    set /a count+=1
)

if %count% equ 0 (
    echo ERROR: No hay backups disponibles en la carpeta 'backups'
    pause
    exit /b 1
)

echo [INFO] Backups disponibles:
echo.
for %%f in (backups\*.zip) do (
    set /a num+=1
    echo   [!num!] %%~nxf
)
echo.
echo   [0] Cancelar
echo.

set /p "selection=Ingresa el numero del backup a restaurar: "

if "%selection%" equ "0" (
    echo Restauracion cancelada.
    pause
    exit /b 0
)

:: Validar seleccion
set num=0
for %%f in (backups\*.zip) do (
    set /a num+=1
    if "!num!" equ "%selection%" (
        set "backupfile=%%f"
    )
)

if not defined backupfile (
    echo ERROR: Seleccion invalida
    pause
    exit /b 1
)

echo.
echo [INFO] Backup seleccionado: %backupfile%
echo.

:: Confirmar restauracion
set /p "confirm=ADVERTACION: Esto sobrescribira archivos existentes. Continuar? (S/N): "

if /i not "%confirm%" equ "S" (
    echo Restauracion cancelada.
    pause
    exit /b 0
)

echo.
echo [1/3] Extrayendo backup...
powershell -Command "Expand-Archive -Path '%backupfile%' -DestinationPath '.' -Force" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Fallo al extraer el backup
    pause
    exit /b 1
)
echo        OK
echo.

echo [2/3] Eliminando archivos temporales...
if exist __MACOSX rmdir /s /q __MACOSX 2>nul
if exist "._*" del /q "._*" 2>nul
echo        OK
echo.

echo [3/3] Verificando restauracion...
if exist lib (
    echo        OK - Archivos restaurados correctamente
) else (
    echo ERROR: La restauracion parece incompleta
    pause
    exit /b 1
)
echo.

echo ============================================
echo    RESTAURACION COMPLETADA
echo ============================================
echo.
echo El backup ha sido restaurado exitosamente.
echo.
echo NOTA: Ejecuta 'flutter pub get' para actualizar
echo       las dependencias antes de compilar.
echo.
pause
endlocal
