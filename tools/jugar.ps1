# Abre Packet Quest desde el menú principal.
# Uso:  .\tools\jugar.ps1          -> continúa la partida guardada
#       .\tools\jugar.ps1 -Nuevo   -> borra el guardado y empieza desde cero
param([switch]$Nuevo)

$godotDir = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
$consola = Join-Path $godotDir "Godot_v4.7.2-stable_win64_console.exe"
$godot = Join-Path $godotDir "Godot_v4.7.2-stable_win64.exe"
$proyecto = Join-Path $PSScriptRoot "..\game" | Resolve-Path

if ($Nuevo) {
    $save = "$env:APPDATA\Godot\app_userdata\Packet Quest- La Red Rota\save.json"
    if (Test-Path $save) { Remove-Item $save; Write-Host "Partida borrada: empiezas desde cero." }
}

# Reimporta para registrar clases nuevas tras un git pull o una fusión (evita "Identifier not declared").
Write-Host "Actualizando la caché del proyecto..."
& $consola --headless --path $proyecto --import | Out-Null

& $godot --path $proyecto
