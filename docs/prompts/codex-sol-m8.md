Eres el desarrollador principal de "Packet Quest: La Red Rota" (Godot 4.7.2, GDScript con tipos estáticos).
Trabajas en el worktree actual (rama `feat/m8-wifi`). El juego está en `game/`. Responde y comenta en español.

## Tarea
Implementa el hito M8 completo según `docs/13-m8-mundo-wifi.md` (es la especificación vinculante; léela entera
primero). Contexto adicional: `docs/03-mecanicas.md`, `docs/05-enemigos-y-jefes.md`, `docs/06-puzles.md`,
`docs/08-arquitectura-tecnica.md`, `game/README.md`, `game/IMPLEMENTACION.md`. Mapa del código: `graphify-out/GRAPH_REPORT.md`.

Sigue los patrones existentes: `scripts/bosses/router_boss.gd` (fases, tarjeta, pausa 2,4 s),
`scripts/enemies/enemy_base.gd`, `scripts/puzzles/` (RoutePuzzle), `scripts/objects/`, `PQStyle`, pools de proyectiles.

## Herramientas que debes usar
1. **godot-mcp** (servidor MCP `godot`, ya configurado): úsalo para ejecutar el proyecto (`game/`), leer la salida de
   depuración y detectar errores en tiempo de ejecución, además de las pruebas headless.
2. **Skills de GodotPrompter** (markdown, léelas antes de escribir el código correspondiente):
   `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
   — en especial `2d-essentials`, `physics-system`, `player-controller`, `component-system`, `gdscript-patterns`,
   `godot-testing`, `godot-optimization` y `godot-code-review` (aplica su checklist a tu diff antes de terminar).
3. **Pruebas**: `bash tools/run-tests.sh --integration` (reimporta y ejecuta). Godot:
   `C:\Users\alumnos.LAPTOP-LGABPBVS\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Método (obligatorio)
- TDD: para cada unidad de la sección 6 escribe primero la prueba, ejecútala y comprueba que falla, después implementa.
- Haz commits pequeños por bloque (GameState por mundos; WaveZone + CoveragePlatform; Spyware; CableGrid + puzle;
  Reina Wi-Fi; nivel 2-1 y mapa; README/capturas). Mensajes de commit en español con prefijo `feat(m8):`/`test(m8):`.
- No rompas M0–M7: la suite completa debe quedar en verde al final (`RESULTADO: N/N PASS` + `PASS integration`).
- Ejecuta 300 frames del nivel 2-1 y del jefe en headless sin errores. Genera `docs/capturas/level2.png` y `boss2.png`
  (puedes reutilizar el método de captura que haya en el repo o usar godot-mcp).
- No toques `docs/13-m8-mundo-wifi.md`. Si la especificación es imposible o contradictoria en algún punto, toma la
  decisión más pequeña que la cumpla y anótala en `game/IMPLEMENTACION.md` bajo "Decisiones M8".
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree.

## Entrega
Al terminar, escribe en tu respuesta final: commits creados, resultado literal de la última ejecución de pruebas,
decisiones tomadas, y lo que quede pendiente.
