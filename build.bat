@echo off
echo ========================================
echo BHU Control - Build Script para Android
echo ========================================
echo.

REM Verificar si Flutter está instalado
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no está instalado o no está en el PATH
    echo Por favor, instala Flutter desde: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo [1/6] Verificando dependencias...
flutter doctor
echo.

echo [2/6] Limpiando proyecto anterior...
flutter clean
echo.

echo [3/6] Obteniendo dependencias...
flutter pub get
echo.

echo [4/6] Verificando dispositivos conectados...
flutter devices
echo.

echo [5/6] Opciones de compilación:
echo.
echo 1. Ejecutar en emulador/dispositivo
echo 2. Compilar APK Debug
echo 3. Compilar APK Release
echo 4. Compilar App Bundle Release
echo.
set /p option="Selecciona una opción (1-4): "

if "%option%"=="1" (
    echo [6/6] Ejecutando aplicación...
    flutter run
) else if "%option%"=="2" (
    echo [6/6] Compilando APK Debug...
    flutter build apk --debug
    echo APK generado en: build/app/outputs/flutter-apk/app-debug.apk
) else if "%option%"=="3" (
    echo [6/6] Compilando APK Release...
    flutter build apk --release
    echo APK generado en: build/app/outputs/flutter-apk/app-release.apk
) else if "%option%"=="4" (
    echo [6/6] Compilando App Bundle Release...
    flutter build appbundle --release
    echo App Bundle generado en: build/app/outputs/bundle/release/app-release.aab
) else (
    echo [ERROR] Opción no válida
    pause
    exit /b 1
)

echo.
echo ========================================
echo ¡Proceso completado exitosamente!
echo ========================================
pause