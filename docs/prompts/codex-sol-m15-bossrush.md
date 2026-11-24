# Codex (gpt-6.2-sol) — M15: estadísticas por nivel y modo Boss Rush

Worktree del repo Packet Quest (Godot 4.7.2, GDScript tipado). Lee `game/README.md`, `game/IMPLEMENTACION.md`
(sobre todo las decisiones de M7, M11, M14) y `docs/03-mecanicas.md`.

## Diseño decidido (no reabrir)
### A. Estadísticas por nivel
- Por cada nivel y cada jefe: **mejor tiempo**, **muertes totales**, **veces completado**, y en niveles los núcleos
  recogidos sobre los disponibles. Se guardan en `stats.levels[<id>]` del guardado; los guardados antiguos sin ese campo
  siguen siendo válidos (migración silenciosa en `SaveManager`).
- El tiempo cuenta con `delta` del juego en marcha (no cuenta pausa ni menús; nunca `Time.get_ticks_msec`).
- Se muestran: en el **mapa de la red** al enfocar un nodo de mundo (panel pequeño), y en la **pantalla de victoria**
  ("Nuevo récord" si mejora el tiempo).
- En la pantalla de créditos añade una línea con el tiempo total de la mejor partida (suma de mejores tiempos).

### B. Modo Boss Rush
- Se desbloquea al ver los créditos por primera vez (`unlocked_boss_rush` en el guardado). Antes no aparece.
- Acceso: botón "Boss Rush" en el mapa de la red (solo si está desbloqueado).
- Los 5 jefes seguidos (Router → Reina → Firewall → Troyano → Malwarex) con sus escenas actuales. Byte usa su
  equipamiento y PV máximos actuales; la vida **se conserva** entre jefes y recupera **+1 PV** (sin pasar del máximo)
  al vencer a cada uno. Muerte = fin de la ronda (sin reintento desde el jefe).
- Cronómetro visible en el HUD durante la ronda. Al terminar o morir: pantalla de resultados (jefes vencidos, tiempo,
  mejor marca) con "Reintentar" y "Volver al mapa".
- **No** da núcleos ni cambia la progresión normal ni las estadísticas de los niveles normales (tiene las suyas:
  mejor tiempo y mejor número de jefes vencidos).
- Hacer los jefes reutilizables en este modo sin duplicar su código: un modo/contexto en `GameState` que la victoria del
  jefe consulte para decidir si va al siguiente jefe o a la victoria normal.

## Herramientas
- **godot-mcp** (servidor `godot`) para ejecutar `game/` y leer errores.
- **Skills de GodotPrompter** en `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
  (`save-load`, `hud-system`, `godot-ui`, `scene-organization`, `godot-testing`, `godot-code-review`).

## Método (obligatorio)
- TDD: `tests/test_stats.gd` y `tests/test_boss_rush.gd` (registradas en el runner): migración de guardado antiguo,
  mejor tiempo solo mejora, muertes suman, la pausa no cuenta tiempo, Boss Rush bloqueado antes de créditos y
  desbloqueado después, orden de jefes, +1 PV acotado, muerte termina la ronda, no da núcleos, no toca stats normales.
- El fuzz (`tests/test_fuzz.gd`) debe incluir la pantalla de resultados del Boss Rush.
- Suite verde (`bash tools/run-tests.sh --integration` → `RESULTADO: N/N PASS` + `PASS integration`) y
  `bash tools/run-e2e.sh` → `PASS e2e`. Si el bot llega a créditos, que compruebe además que aparece "Boss Rush" en el
  mapa (amplía `tests/e2e_suite.gd` solo con esa comprobación).
- Commits pequeños. Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones M15". Captura `docs/capturas/bossrush.png`.
- Todo temporizador de juego cuenta con `delta`/fotogramas, nunca con el reloj real.
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree. No borres directorios con rm -rf.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript.

## Entrega
Respuesta final: commits, salida literal de suite y e2e, decisiones y pendientes.
