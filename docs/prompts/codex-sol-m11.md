Eres el desarrollador principal de "Packet Quest: La Red Rota" (Godot 4.7.2, GDScript con tipos estáticos).
Trabajas en el worktree actual (rama `feat/m11-centro-datos`). El juego está en `game/`. Responde y comenta en español.

## Tarea
Implementa el hito M11 completo según `docs/16-m11-centro-de-datos.md` (es la especificación vinculante; léela entera
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
- Haz commits pequeños por bloque (GameState y mapa a 5 mundos; CloudPlatform; BotDDoS; QosPuzzle + puzle; Malwarex con puzle en combate; créditos y estadísticas; nivel 5-1; README/capturas)
- No rompas M0–M10: la suite completa debe quedar en verde al final (`RESULTADO: N/N PASS` + `PASS integration`).
- Ejecuta 300 frames del nivel 5-1 y del jefe en headless sin errores. Genera `docs/capturas/level5.png`, `boss5.png` y `credits.png`
  (puedes reutilizar el método de captura que haya en el repo o usar godot-mcp).
- No toques `docs/16-m11-centro-de-datos.md`. Si la especificación es imposible o contradictoria en algún punto, toma la
  decisión más pequeña que la cumpla y anótala en `game/IMPLEMENTACION.md` bajo "Decisiones M11".
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree.

## Entrega
Al terminar, escribe en tu respuesta final: commits creados, resultado literal de la última ejecución de pruebas,
decisiones tomadas, y lo que quede pendiente.

## Lecciones de M1–M9 (cumplir)
- La salida de cada nivel debe alcanzarse **caminando**: en M1 la condición x ≥ 2720 era inalcanzable porque un muro
  en x = 2720 frenaba el colisionador de Byte (10 px) en x ≈ 2715. Prueba la salida moviendo a Byte con
  `Input.action_press("move_right")`, nunca teletransportándolo.
- Todo hueco, carril o puerto debe ser alcanzable: el salto de Byte sube ~60 px, el dash recorre 72 px.
- Reutiliza `GameState.WORLDS`, `is_world_playable` y el mapa por mundos que creó M8; no los dupliques.
