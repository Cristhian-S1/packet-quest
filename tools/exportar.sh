#!/bin/bash
# Genera build/windows/PacketQuest.exe (un solo archivo, .pck incrustado).
# Requiere las plantillas de exportación 4.7.2 en %APPDATA%/Godot/export_templates/4.7.2.stable
set -e
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")/../game"
mkdir -p ../build/windows
"$G" --headless --path . --import > /dev/null 2>&1
"$G" --headless --path . --export-release "Windows Desktop" ../build/windows/PacketQuest.exe
ls -la ../build/windows/PacketQuest.exe
