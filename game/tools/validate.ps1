param(
    [string]$Godot = 'C:/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
$gamePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$logPath = Join-Path $gamePath 'validation'
$checks = @(
    @{ Name = '01-import'; Args = @('--headless', '--path', $gamePath, '--import') },
    @{ Name = '02-startup'; Args = @('--headless', '--path', $gamePath, '--quit') },
    @{ Name = '03-tests'; Args = @('--headless', '--path', $gamePath, '-s', 'res://tests/test_runner.gd') },
    @{ Name = '04-runtime'; Args = @('--headless', '--path', $gamePath, '--quit-after', '300') },
    @{ Name = '05-integration'; Args = @('--headless', '--path', $gamePath, '-s', 'res://tests/test_integration.gd') }
)

foreach ($check in $checks) {
    $arguments = $check.Args
    $output = & $Godot @arguments 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $logPath ($check.Name + '.log'))
    $output | ForEach-Object { Write-Output $_ }
    if ($code -ne 0 -or ($output -join "`n") -match '(SCRIPT ERROR|Parse Error|ERROR:|WARNING:|FAIL)') {
        throw "Validación $($check.Name) falló (exit=$code)."
    }
    Write-Output "VALIDADO $($check.Name): exit=0"
}
