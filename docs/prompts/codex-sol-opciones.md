# Codex (gpt-6.2-sol) — Menú de Opciones + pendientes de la auditoría del Mundo 1

Estás en un worktree del repo Packet Quest (Godot 4.7.2, GDScript con tipos estáticos). Lee `game/README.md` y
`game/IMPLEMENTACION.md` para ubicarte.

## Tarea A — Menú de Opciones (bead pq-7qg)
El guardado ya tiene `settings` (`SaveManager`, líneas ~12–13 y su validación ~68–74): `screen_shake`, `reduce_flashes`,
`assist_mode` (bool) y `music_volume`, `sfx_volume` (0–1). Falta la interfaz y que el audio los respete.
1. Pantalla `OptionsMenu` (escena + script en `scenes/ui` / `scripts/ui`, reutiliza `screen_base.gd` y `PQStyle`):
   tres interruptores (Sacudida de pantalla, Reducir destellos, Modo asistencia), dos deslizadores de volumen
   (Música, Efectos; pasos de 0,1) y "Volver". Navegable solo con teclado y con mando (foco visible, `ui_left/right`
   cambia los deslizadores). Cada cambio se guarda al momento con `SaveManager`.
2. Accesible desde el menú principal (`scripts/main/main.gd`, botón "Opciones" entre Jugar y Salir) y desde el menú de
   pausa (`PauseMenu`). Al volver, el foco regresa al botón que la abrió; en pausa el juego sigue pausado.
3. `AudioManager` aplica `music_volume`/`sfx_volume` (buses Music/SFX; créalos si no existen en `default_bus_layout.tres`)
   al arrancar y al cambiar. Volumen 0 = silencio (`linear_to_db` con 0 da -inf: trátalo).
4. Comprueba que los tres bool ya afectan al juego (grep: player.gd, hud.gd, jefes). Si alguno no se consulta en algún
   sitio donde debería (p. ej. sacudida de cámara, destellos de daño), conéctalo.
5. Corrige textos desfasados del menú principal: "RED LOCAL / WI-FI" y "PROTOTIPO VERTICAL · M8" ya no son ciertos (hay
   5 mundos).

## Tarea B — Pendientes de la auditoría del Mundo 1 (bead pq-xg6, ver `logs/opencode-audit-w1.md`)
- #3 Pop-up sin animación de aparición: añade una aparición corta (≤0,25 s, escala o alfa) sin cambiar su hitbox ni su daño.
- #8–10 warnings del analizador de GDScript: elimínalos (ejecuta el proyecto y lee la salida).
- #11 el anillo del Router se lanza cada 2,8 s y la spec dice 3 s: ajústalo y actualiza la prueba que lo cubra.
- #12 la guía del cable móvil mide 160 px y la spec dice 64 px: ajústala comprobando que el puzle sigue siendo resoluble.
- #5 y #7 están decididos SIN cambio: no los toques.

## Herramientas que debes usar
1. **godot-mcp** (servidor MCP `godot`): ejecutar el proyecto `game/` y leer errores y warnings en tiempo de ejecución.
2. **Skills de GodotPrompter** (léelas antes de escribir el código correspondiente):
   `C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills\`
   — en especial `ui-system` o similar (mira qué hay), `audio-system`, `gdscript-patterns`, `godot-testing` y
   `godot-code-review` (aplica su checklist a tu diff antes de terminar).
3. **Pruebas**: `bash tools/run-tests.sh --integration`. Godot:
   `C:\Users\alumnos.LAPTOP-LGABPBVS\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Método (obligatorio)
- TDD: prueba primero, ver que falla, luego implementar. Nuevo fichero `game/tests/test_options.gd` registrado en
  `tests/test_runner.gd`: guardar/cargar cada ajuste, deslizador acotado a 0–1, volumen aplicado al bus, abrir y cerrar
  desde menú y pausa (con `Input.parse_input_event` para pulsar botones de UI), y que el fuzz (`tests/test_fuzz.gd`)
  incluya la escena de Opciones.
- Commits pequeños: (1) Opciones + audio, (2) acceso desde menú y pausa, (3) cada arreglo de auditoría.
- La suite completa debe acabar en verde (`RESULTADO: N/N PASS` + `PASS integration`) y `bash tools/run-e2e.sh` en `PASS e2e`
  (si añadir el botón Opciones cambia el orden de foco del menú, adapta `tests/bot/pilot.gd`).
- Captura `docs/capturas/options.png`.
- Decisiones en `game/IMPLEMENTACION.md` bajo "Decisiones Opciones".
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.

## Lecciones (cumplir)
- El runner marca FAIL cualquier error del motor o de GDScript durante una prueba: no dejes `SCRIPT ERROR` ni `ERROR:`.
- `Input.action_press` no pulsa botones de UI; para menús usa `Input.parse_input_event` con un `InputEventAction`.
- El juego tiene exactamente 5 mundos (`SaveManager.WORLD_COUNT`).

## Entrega
En tu respuesta final: commits, resultado literal de la última ejecución de pruebas y de e2e, decisiones y pendientes.
