#!/usr/bin/env bash
# Builds the Linux and Windows executables into export/.
set -euo pipefail
cd "$(dirname "$0")"
GODOT="${GODOT:-flatpak run org.godotengine.Godot}"
mkdir -p export/linux export/windows
$GODOT --headless --path . --export-release "Linux" export/linux/AngryHerds.x86_64
$GODOT --headless --path . --export-release "Windows" export/windows/AngryHerds.exe
echo "Built export/linux/AngryHerds.x86_64 and export/windows/AngryHerds.exe"
