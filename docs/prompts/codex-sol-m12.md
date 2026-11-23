# Codex (gpt-6.2-sol) — M12: audio procedural y pulido visual

Worktree del repo Packet Quest (Godot 4.7.2, GDScript tipado). Lee `docs/09-arte-y-audio.md`, `game/README.md` y
`game/IMPLEMENTACION.md`. El juego tiene 5 mundos completos y menú de Opciones con volúmenes de música y efectos
(buses Music/SFX en `AudioManager`).

## Decisión ya tomada (no reabrir)
No hay Aseprite ni artistas: el arte sigue siendo procedural (`_draw` + `PQStyle`) y el audio se **sintetiza por código**
(sin ficheros externos ni descargas). Todo es composición original.

## Tarea
1. **Generador de SFX estilo sfxr** (`scripts/audio/sfx_synth.gd`): parámetros (onda cuadrada/sierra/seno/ruido,
   frecuencia inicial, deslizamiento, ataque/sostenido/caída, vibrato, duty) → `AudioStreamWAV`. Determinista
   (mismos parámetros = mismos bytes). Catálogo `scripts/audio/sfx_catalog.gd` con: salto, dash, disparo por arma
   (packet, triple, ping), impacto, daño a Byte, muerte, núcleo recogido, puzle resuelto, clic y foco de menú, y **un
   aviso propio por tipo de ataque de cada jefe** (los 5), siempre el mismo sonido. Sustituye `SFX_NOTES`/pitch actuales
   manteniendo `AudioManager.play_sfx(id)` y `last_sfx` (las pruebas existentes los usan).
2. **Música chiptune** (`scripts/audio/music_synth.gd` + `music_catalog.gd`): secuenciador de 3–4 canales (pulso
   melodía, pulso armonía, triángulo bajo, ruido percusión) que renderiza un bucle de 8–16 compases a `AudioStreamWAV`
   con `loop_mode` activo. Un tema por mundo (5), uno de jefe (puede variar por mundo con transposición/tempo),
   menú/mapa y créditos. 120–140 BPM. Implementa `AudioManager.play_music(id)` con fundido cruzado corto, sin reiniciar si
   ya suena ese tema, y llámalo desde menú, mapa, cada nivel, cada jefe y créditos. Renderiza en segundo plano o en caché
   para no congelar la carga (>50 ms en el hilo principal es un fallo: mídelo en una prueba).
   En headless no reproduzcas, pero sí registra `last_music` para las pruebas.
3. **Parallax de 3 capas** (cuadrícula lejana, cables/racks, LEDs en primer plano) en los fondos de nivel que aún no lo
   tengan, con `Parallax2D` o capas propias, sin tapar telegrafías ni balas.
4. **Pulido**: partículas o destello breve al recoger núcleo y al vencer un jefe, respetando `reduce_flashes`;
   sacudida respetando `screen_shake`.
5. `assets/CREDITS.md`: indica que música y SFX son originales generados por código.

## Herramientas
- **godot-mcp** (servidor `godot`) para ejecutar `game/` y leer errores; escucha el resultado si puedes generar WAV de
  muestra en `docs/audio/` (exporta 3–4 temas y 6 SFX a `.wav` con un script de herramienta) para que el equipo los oiga.
- **Skills de GodotPrompter** en `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
  (`audio-system`, `2d-essentials`, `godot-optimization`, `godot-testing`, `godot-code-review`).
- Pruebas: `bash tools/run-tests.sh --integration` y `bash tools/run-e2e.sh`.

## Método (obligatorio)
- TDD. `tests/test_audio.gd` (registrado en el runner): determinismo del sintetizador, duración y tasa de cada SFX,
  bucle de música sin clic (primera y última muestra cercanas a 0), cada id del catálogo existe, `play_music` llamado con el
  id correcto en cada escena, volumen 0 = silencio, tiempo de render.
- Commits pequeños por bloque. Suite verde (`RESULTADO: N/N PASS` + `PASS integration`) y `PASS e2e` al final.
- Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones M12".
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript: no dejes `SCRIPT ERROR` ni `ERROR:`.

## Entrega
Respuesta final: commits, salida literal de suite y e2e, decisiones, pendientes.
