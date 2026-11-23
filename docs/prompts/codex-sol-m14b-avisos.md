# Codex (gpt-6.2-sol) — M14 parte B: avisos sonoros de enemigos y tema por jefe

Worktree del repo Packet Quest (Godot 4.7.2, GDScript tipado). Lee `logs/codex-terra-auditoria-gdd.md` y las secciones
"Decisiones M12" y "Decisiones M13" de `game/IMPLEMENTACION.md`. En paralelo otra rama (M14 parte A) toca Opciones,
controles, niveles (progreso), puzles (pistas) y docs 03/16: no toques esos ficheros.

## Tareas
1. **Avisos sonoros de enemigos comunes** (P1, `docs/05-enemigos-y-jefes.md:5`, `docs/03-mecanicas.md` §Accesibilidad
   "avisos con forma y sonido, no solo color"): al entrar en su estado de aviso, Pop-up (y blindado), Gusano (y
   blindado), Spyware, Troyano y Bot DDoS emiten un SFX de aviso propio por tipo, siempre igual, generado con el
   `SfxSynth`/`SfxCatalog` de M12. Que no suene si el enemigo está fuera de la pantalla (cámara + margen 32 px), y
   limita simultáneos (si 5 enemigos avisan en el mismo frame, como máximo 2 voces de aviso común; los avisos de jefe
   tienen prioridad). Comprueba también que cada aviso visual (M13) tenga forma, no solo color.
2. **Tema propio por jefe** (`docs/09-arte-y-audio.md:37`): hoy los 5 jefes comparten composición. Crea 5 temas de jefe
   originales en `MusicCatalog` (motivo distinto, tempo 130–150, Malwarex con 4 secciones que cambian por fase si es
   barato; si no, uno solo) y que cada jefe llame a su id. Mantén caché y render en hilo; mide que no haya tirón.
   Actualiza `docs/09-arte-y-audio.md` y exporta los 5 a `docs/audio/` como WAV (sustituye `music_boss.wav`).

## Herramientas
- **godot-mcp** (servidor `godot`) para ejecutar `game/` y leer errores.
- **Skills de GodotPrompter** en `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
  (`audio-system`, `godot-optimization`, `godot-testing`, `godot-code-review`).

## Método (obligatorio)
- TDD: amplía `tests/test_audio.gd`: cada tipo de enemigo emite su id de aviso al entrar en aviso, no fuera de pantalla,
  límite de voces, cada jefe pide su tema, temas distintos entre sí (bytes distintos), bucle sin clic.
- Suite verde (`bash tools/run-tests.sh --integration` → `RESULTADO: N/N PASS` + `PASS integration`) y
  `bash tools/run-e2e.sh` → `PASS e2e`.
- Commits pequeños. Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones M14B".
- Todo temporizador de juego cuenta con `delta`/fotogramas, nunca con el reloj real.
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree. No borres directorios con rm -rf.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript.

## Entrega
Respuesta final: commits, salida literal de suite y e2e, decisiones y pendientes.
