# Codex (gpt-6.2-sol) — M14: huecos de jugabilidad de la auditoría (parte A)

Worktree del repo Packet Quest (Godot 4.7.2, GDScript tipado). Lee `logs/codex-terra-auditoria-gdd.md` (auditoría
diseño frente a juego) y `game/IMPLEMENTACION.md`. En paralelo otra rama (M13) cambia **solo el dibujo** (`_draw`) de
Byte, enemigos y jefes: no toques funciones `_draw` ni ficheros de `scripts/art/` para evitar conflictos.

## Tareas
1. **Remapeo completo de controles** (P1, `docs/03-mecanicas.md` §Accesibilidad): en Opciones, una pantalla "Controles"
   con cada acción de juego (moverse, saltar, disparar, dash, escudo, interactuar, cambiar arma, apuntar arriba, pausa…:
   saca la lista del InputMap de `project.godot`), mostrando tecla y botón de mando. Seleccionar una acción → "Pulsa una
   tecla o botón" → se asigna. Conflictos: si la tecla ya está en otra acción, intercambia y avisa. Escape cancela la
   captura (no se puede asignar Escape salvo a pausa). "Restaurar predeterminados". Persistencia en el guardado
   (`settings.bindings`, valida en `SaveManager` sin romper guardados antiguos) y se aplica al arrancar.
   Los letreros de tutorial que nombran teclas ("J dispara", "Salta y ↑ + K"…) deben mostrar la tecla asignada actual
   (helper `InputLabels.for_action(&"shoot")`).
2. **Bug B1 de la auditoría**: la pantalla de muerte muestra "Progreso del nivel: 0 %" en los mundos 1–4 porque solo
   el nivel 5 actualiza `GameState.boss_progress` (o la variable que use) durante el recorrido. Haz que los 5 niveles
   lo calculen igual (x de Byte respecto a la salida), sin romper el progreso del jefe.
3. **Pistas de puzle tras 60 s** (`docs/06-puzles.md` §Pistas): en los puzles que aún no la tienen (cable, contraseña
   y los demás que la auditoría marque), si pasan 60 s sin resolver, el siguiente elemento correcto parpadea suave una vez
   cada 10 s; con `reduce_flashes` usa un contorno fijo en vez de parpadeo. Un único componente reutilizable
   (`scripts/puzzles/puzzle_hint.gd`) en vez de copiarlo en cada puzle.
4. **Coherencia de docs y economía** (decisión de Claude, aplícala): se mantiene la economía actual (núcleos de los
   niveles + los de jefe que ya existen) y los créditos cuentan recogidos sobre 12. Actualiza `docs/03-mecanicas.md:88`,
   `docs/16-m11-centro-de-datos.md` (~187 y ~202) y `docs/09-arte-y-audio.md` (el tema de jefe lo resolverá la parte B)
   para que describan lo implementado.

## Herramientas
- **godot-mcp** (servidor `godot`) para ejecutar `game/` y leer errores.
- **Skills de GodotPrompter** en `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
  (`input-handling` o similar, `ui-system`/`godot-ui`, `save-load`, `godot-testing`, `godot-code-review`).

## Método (obligatorio)
- TDD: `tests/test_controls.gd` (reasignar, intercambio por conflicto, cancelar con Escape, restaurar, persistir y
  cargar, guardado antiguo sin `bindings` sigue válido, el letrero muestra la tecla nueva), y pruebas para B1 y la pista
  (usa tiempo simulado, no esperes 60 s reales). Regístralas en el runner.
- El fuzz (`tests/test_fuzz.gd`) debe incluir la pantalla de Controles.
- Suite verde (`bash tools/run-tests.sh --integration` → `RESULTADO: N/N PASS` + `PASS integration`) y
  `bash tools/run-e2e.sh` → `PASS e2e` (el bot usa las acciones por defecto; no deben cambiar).
- Commits pequeños por tarea. Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones M14".
- Todo temporizador de juego cuenta con `delta`/fotogramas, nunca con el reloj real (`Time.get_ticks_msec`).
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree. No borres directorios con rm -rf.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript: no dejes `SCRIPT ERROR` ni `ERROR:`.

## Entrega
Respuesta final: commits, salida literal de suite y e2e, decisiones y pendientes.
