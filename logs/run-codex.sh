#!/bin/bash
# uso: run-codex.sh <prompt.md> <directorio> <modelo> <esfuerzo> <nombre>
P=$1; D=$2; M=$3; E=$4; N=$5; L=/c/Users/alumnos.LAPTOP-LGABPBVS/Downloads/videogame/logs
cd "$D" && timeout 7200 codex exec -m "$M" -c model_reasoning_effort="$E" --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -C . -o "$L/codex-$N-final.md" - < "$P" > "$L/codex-$N.raw" 2>&1
echo "EXIT=$?"; git log --oneline -8 | head -8; tail -c 1200 "$L/codex-$N-final.md"
