# Continuación 3 — e2e completo (bead pq-moy)

Reglas: las de `docs/prompts/codex-terra-e2e-full.md` (léelas; no negociables).

Estado: tu bot llegaba a créditos, pero era no determinista. Causa encontrada por Claude: el hit-stop del HUD
(`scripts/ui/hud.gd`) se medía con `Time.get_ticks_msec`, así que duraba un número de fotogramas distinto según la
carga de CPU. Ya está arreglado (commit "fix: hit-stop por fotogramas", prueba `tests/test_hit_stop.gd`): ahora dura
`ceil(duración*60)` fotogramas. Además se fusionó main (menú de Opciones y M12: audio sintetizado, parallax).

Ahora el e2e es determinista y falla SIEMPRE igual:
`FAIL e2e: mundo 3: no llega al puzle: Byte (1857.151, 279.4243) PV 0`

Tarea:
1. Reajusta el bot para el juego determinista hasta `PASS e2e` hasta créditos. Prefiere estrategia reactiva (leer balas
   y telegrafías) a rutas cronometradas frágiles.
2. Comprueba robustez: `bash tools/run-e2e.sh` 3 veces seguidas con PASS, y además una ejecución con
   `assist_mode` desactivado y otra con `reduce_flashes` activado (no deben cambiar la jugabilidad).
3. No toques `hud.gd` ni el hit-stop. Si ves otra fuente de no determinismo en el JUEGO (no en el bot), anótala en el
   informe con fichero y línea; no la corrijas tú (p. ej. `enemy_base.gd:96` usa `randf()` sin semilla para soltar
   fragmentos; dime si afecta al recorrido).
4. Suite verde (`bash tools/run-tests.sh --integration`). Commits pequeños. Actualiza `logs/codex-terra-e2e-full.md`.
UN Godot propio a la vez; los de otros no cuentan ni se cierran. Sin `bd`, sin push. No borres directorios con rm -rf.
