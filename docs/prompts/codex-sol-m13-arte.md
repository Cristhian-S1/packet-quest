# Codex (gpt-6.2-sol) — M13: arte procedural y animación

Worktree del repo Packet Quest (Godot 4.7.2, GDScript tipado). Lee `docs/09-arte-y-audio.md` (paleta y dirección:
pixel art retro-techno con neón, placas base, terminales) y `game/README.md`.

## Decisión ya tomada
Sin Aseprite ni ficheros de imagen: el arte sigue siendo `_draw` + `PQStyle`, pero con calidad de juego terminado.
Composición propia y original. **No cambies hitboxes, hurtboxes, colisiones ni tiempos de juego**: solo lo visual.
La lógica de juego no debe leer nada del dibujo.

## Tarea
1. **Byte** (`scripts/player/player.gd::_draw`, hoy un cuadrado con dos patas): sprite pixel 16×16 con más detalle
   (carcasa de paquete, visor, antena/cabecera), y animaciones por estado: reposo (respiración 2 frames), carrera
   (ciclo 4–6 frames), salto/caída (estirar/aplastar), dash (estela y pose), disparo (retroceso del cañón), daño,
   muerte (desintegración en píxeles), escudo. Usa un módulo `scripts/art/byte_art.gd` con funciones estáticas puras
   de dibujo para no inflar `player.gd`.
2. **Enemigos** (Pop-up, Gusano, Spyware, variantes blindadas, Troyano, Bot DDoS): cada uno con animación de
   reposo/movimiento, telegrafía legible antes de atacar y muerte con partículas. Mantén los colores por rol (magenta
   enemigos, rosa balas, rojo aviso).
3. **Jefes** (5): pose idle animada, cambio visual por fase (ya hay `PHASE_COLORS` en algunos), explosión de derrota y
   la animación de "segmento restaurado" coherente en los 5 (ver `docs/04-niveles.md` §Estructura).
4. **Tiles y escenario**: plataformas-chip con borde y pistas de cobre, pequeños LEDs; nada que reduzca el contraste
   de balas y telegrafías (las balas enemigas deben seguir siendo lo más legible de la pantalla).
5. Respeta `GameState.reduce_flashes` (sin parpadeos rápidos ni destellos blancos a pantalla completa) y
   `GameState.screen_shake`.

## Herramientas
- **godot-mcp** (servidor `godot`) para ejecutar `game/`, mirar el resultado y leer errores.
- **Skills de GodotPrompter** en `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
  (`2d-essentials`, `animation-system` o similar, `godot-optimization`, `godot-code-review`).
- Capturas antes/después en `docs/capturas/m13/` (Byte en cada estado, cada enemigo, cada jefe). Usa el método de
  captura que ya hay en el repo (`tests/capture_preview.gd` / `preview_suite.gd`).

## Método (obligatorio)
- TDD donde haya lógica: `tests/test_art.gd` (registrado en el runner) comprueba que el estado de animación sigue al
  estado del jugador/enemigo, que los frames ciclan, que `reduce_flashes` desactiva parpadeos, y que las hitboxes no
  cambiaron (compara tamaños y posiciones con los valores actuales).
- Rendimiento: `tests/test_performance.gd` debe seguir pasando (100 balas a 60 FPS); el dibujo no puede crear nodos por
  frame.
- Commits pequeños por bloque. Suite verde (`bash tools/run-tests.sh --integration` → `RESULTADO: N/N PASS` +
  `PASS integration`) y `bash tools/run-e2e.sh` → `PASS e2e` (el bot no debe notar el cambio).
- Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones M13".
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree. No borres directorios con rm -rf.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript: no dejes `SCRIPT ERROR` ni `ERROR:`.

## Entrega
Respuesta final: commits, salida literal de suite y e2e, rutas de las capturas, decisiones y pendientes.
