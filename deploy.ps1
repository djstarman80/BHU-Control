# Script de Despliegue Automático para BHU Control Web

 = "C:\Users\Usuario\OneDrive\Projectos\bhu_control_app"
 = "C:\Users\Usuario\OneDrive\Projectos\BHU\test\BHU-Control"
 = "https://github.com/djstarman80/BHU-Control.git"

Write-Host "?? Iniciando proceso de despliegue..." -ForegroundColor Cyan

# 1. Compilar la versión web
Write-Host "?? Compilando aplicación Flutter Web..." -ForegroundColor Yellow
Set-Location 
& flutter build web --release --base-href "/BHU-Control/" --no-tree-shake-icons

if ( -ne 0) {
    Write-Host "? Error en la compilación. Abortando." -ForegroundColor Red
    exit 
}

# 2. Preparar carpeta de despliegue
Write-Host "?? Sincronizando archivos con el repositorio de despliegue..." -ForegroundColor Yellow
if (!(Test-Path )) {
    New-Item -ItemType Directory -Force -Path 
}

Set-Location 

# Inicializar Git si no existe
if (!(Test-Path ".git")) {
    & git init
    & git remote add origin 
    & git checkout -b gh-pages
} else {
    & git checkout gh-pages
}

# Limpiar archivos viejos (excepto .git)
Get-ChildItem -Path  -Exclude ".git" | Remove-Item -Recurse -Force

# Copiar nuevo build
Copy-Item -Path "\build\web\*" -Destination  -Recurse -Force

# 3. Subir a GitHub
Write-Host "?? Subiendo cambios a GitHub Pages..." -ForegroundColor Yellow
& git add .
 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
& git commit -m "Update web deployment: "
& git push origin gh-pages --force

Write-Host "? ¡Despliegue completado con éxito!" -ForegroundColor Green
Write-Host "?? URL: https://djstarman80.github.io/BHU-Control/" -ForegroundColor Blue
