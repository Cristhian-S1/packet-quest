#!/bin/bash
# uso: run-oc.sh <nombre> <directorio> ; lanza opencode con el prompt logs/prompt-oc-<nombre>.md
N=$1; D=$2; L=/c/Users/alumnos.LAPTOP-LGABPBVS/Downloads/videogame/logs
cd "$D" && timeout 3600 opencode run -m opencode-go/deepseek-v4-pro --auto --title "pq-$N" --archived "$(cat $L/prompt-oc-$N.md)" > $L/opencode-$N.raw 2>&1
rc=$?; sed 's/\x1b\[[0-9;]*m//g' $L/opencode-$N.raw | grep -vE "^\s*$|^→ Read|^✱" > $L/opencode-$N.md; echo "EXIT=$rc"; tail -15 $L/opencode-$N.md
