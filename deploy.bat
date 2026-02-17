@echo off
echo ?? Iniciando despliegue automatico...
cd /d C:\Users\Usuario\OneDrive\Projectos\bhu_control_app

echo ?? Compilando Flutter Web...
call flutter build web --release --base-href "/BHU-Control/" --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo ? Error en la compilacion.
    pause
    exit /b %errorlevel%
)

echo ?? Sincronizando archivos...
set DEPLOY_PATH=C:\Users\Usuario\OneDrive\Projectos\BHU\test\BHU-Control
if not exist "%DEPLOY_PATH%" mkdir "%DEPLOY_PATH%"

cd /d "%DEPLOY_PATH%"
if not exist .git (
    git init
    git remote add origin https://github.com/djstarman80/BHU-Control.git
    git checkout -b gh-pages
) else (
    git checkout gh-pages
)

echo ?? Limpiando carpeta...
for /f "tokens=*" %%i in ('dir /b /a-d ^| findstr /v /i ".git"') do del "%%i" /f /q
for /f "tokens=*" %%i in ('dir /b /ad ^| findstr /v /i ".git"') do rd "%%i" /s /q

echo ?? Copiando nuevo build...
xcopy "C:\Users\Usuario\OneDrive\Projectos\bhu_control_app\build\web\*" "%DEPLOY_PATH%" /s /e /y /h

echo ?? Subiendo a GitHub...
git add .
git commit -m "Auto-deploy: %date% %time%"
git push origin gh-pages --force

echo ? Despliegue completado!
echo ?? https://djstarman80.github.io/BHU-Control/
pause
