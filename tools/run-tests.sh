#!/bin/bash
# Reimporta (actualiza la caché de class_name) y ejecuta las pruebas headless.
G="/c/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")/../game"
timeout 120 "$G" --headless --path . --import >/dev/null 2>&1
timeout 180 "$G" --headless --path . -s res://tests/test_runner.gd 2>&1 | grep -E "PASS|FAIL|RESULT|SCRIPT ERROR|Parse Error|ERROR" | head -30
rc=${PIPESTATUS[0]}
if [ "$1" = "--integration" ]; then
  timeout 240 "$G" --headless --path . -s res://tests/test_integration.gd 2>&1 | grep -E "PASS|FAIL|ERROR" | head -10
  rc2=${PIPESTATUS[0]}; [ $rc2 -ne 0 ] && rc=$rc2
fi
exit $rc
