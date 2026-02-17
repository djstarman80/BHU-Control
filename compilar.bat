@echo off
chcp 65001 >nul
echo ============================================
echo    BHU Control App - Script de Compilacion
echo ============================================
echo.

cd /d "%~dp0"

echo [1/4] Limpiando builds anteriores...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
echo        OK
echo.

echo [2/4] Obteniendo dependencias...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Fallo al obtener dependencias
    pause
    exit /b 1
)
echo        OK
echo.

echo [3/4] Compilando APK Debug...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Fallo al compilar APK
    pause
    exit /b 1
)
echo        OK
echo.

echo [4/4] Instalando APK en dispositivo...
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if %errorlevel% neq 0 (
    echo ERROR: Fallo al instalar APK
    pause
    exit /b 1
)
echo        OK
echo.

echo ============================================
echo    COMPILACION COMPLETADA EXITOSAMENTE
echo ============================================
echo.
pause
