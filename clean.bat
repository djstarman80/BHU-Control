@echo off
echo =========================================
echo   Limpiando proyecto BHU Control App
echo =========================================
echo.
echo Eliminando archivos generados...
echo.

:: Eliminar carpetas principales
if exist build rmdir /S /Q build 2>nul
if exist .dart_tool rmdir /S /Q .dart_tool 2>nul
if exist .idea rmdir /S /Q .idea 2>nul
if exist android\.gradle rmdir /S /Q android\.gradle 2>nul
if exist android\app\build rmdir /S /Q android\app\build 2>nul
if exist ios\Pods rmdir /S /Q ios\Pods 2>nul

:: Eliminar archivos sueltos
del /F /Q *.iml 2>nul
del /F /Q .flutter-plugins* 2>nul
del /F /Q .packages 2>nul
del /F /Q .metadata 2>nul
del /F /Q test_bcu.dart 2>nul
del /F /Q xml_output.txt 2>nul

echo.
echo =========================================
echo   Limpieza completada!
echo =========================================
echo.
pause
