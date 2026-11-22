#!/bin/bash
set -o pipefail
G="/c/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")/../game" || exit 1
timeout 240 "$G" --headless --path . --fixed-fps 60 -s res://tests/test_e2e_runner.gd
