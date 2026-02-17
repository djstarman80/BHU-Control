# Script de Limpieza para BHU Control App
# Elimina archivos y carpetas generados que no son necesarios

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Limpiando proyecto BHU Control App" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Lista de elementos a eliminar
$itemsToClean = @(
    "build",
    ".dart_tool",
    ".idea",
    "*.iml",
    ".flutter-plugins*",
    ".packages",
    ".metadata",
    "android/.gradle",
    "android/app/build",
    "ios/Flutter/Generated.xcconfig",
    "ios/Pods",
    "test_bcu.dart",
    "xml_output.txt"
)

$deletedCount = 0
$totalSize = 0

foreach ($item in $itemsToClean) {
    $paths = Get-ChildItem -Path $item -ErrorAction SilentlyContinue -Force
    
    foreach ($path in $paths) {
        try {
            $size = 0
            if ($path.PSIsContainer) {
                $size = (Get-ChildItem $path.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            } else {
                $size = $path.Length
            }
            
            Remove-Item $path.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $deletedCount++
            $totalSize += $size
            
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host "  [ELIMINADO] $($path.Name) ($sizeMB MB)" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] No se pudo eliminar: $($path.Name)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  Limpieza completada!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Elementos eliminados: $deletedCount" -ForegroundColor White
Write-Host "Espacio liberado: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
