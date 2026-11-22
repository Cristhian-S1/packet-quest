You are implementing the vertical-slice prototype of an original 2D game, "Packet Quest: La Red Rota", in Godot 4.7.2 with GDScript.

## Source of truth
Read every file in `docs/` before writing code (they are in Spanish). Priority: `02-plan-desarrollo.md` (scope = milestones M0–M6 and the 12-task breakdown), `03-mecanicas.md` (exact numeric values), `04-niveles.md` (level 1-1 layout), `05-enemigos-y-jefes.md` (Pop-up, Gusano de red, Router Furioso), `06-puzles.md` (Ruta de paquetes), `07-modelos.md` (data models, scenes, signals, state machines, visual specs), `08-arquitectura-tecnica.md` (project settings, folders, autoloads, collision layers, tests), `09-arte-y-audio.md` (palette), `10-qa-y-pruebas.md` (tests).

## Hard requirements
- Create the Godot project in `game/` (so `game/project.godot`). Do not modify `docs/` or `contexto.md`.
- Godot 4.7 syntax only, statically typed GDScript. Renderer: gl_compatibility. Viewport 640x360, window 1280x720, stretch mode viewport, integer scale, nearest filter.
- Define the full InputMap in project.godot (keyboard + joypad) exactly as in `03-mecanicas.md`, and name the 8 collision layers as in `08-arquitectura-tecnica.md`.
- NO external art or audio assets. Draw everything procedurally (`_draw()`, Polygon2D, Line2D, ColorRect) using the palette hex colors. Audio may be silent or synthesized; it must never crash if missing.
- Keep `.tscn` files minimal and valid. Prefer building child nodes in code (`_ready`) over large hand-written scene files, so scenes can't be malformed. Every `.tscn` must load.
- Player: CharacterBody2D with accel/friction, gravity with fall multiplier, variable jump, coyote 0.10 s, jump buffer 0.10 s, dash (72 px, 0.18 s, 0.15 s i-frames, 0.6 s cooldown, 1 air dash), 8-way aim with lock_aim, auto-fire Packet weapon (8/s, 480 px/s, pooled), front-only firewall shield with meter, 3 HP, 1.0 s invulnerability, knockback, pit respawn, checkpoints.
- Enemies: Pop-up and Network Worm with telegraph → active → recovery, only firing when on screen. Enemy bullets pooled.
- Level World1Level1 (3200 px wide) with sections S1–S4, tutorial signs, checkpoint, hidden data core, moving cable platform, then the 3-node route puzzle that opens a door, then transition to the Router Furioso arena.
- Router Furioso: 60 HP, 2 phases (threshold 50 %), attacks A ring / B stampede / C ping laser with the telegraph timings from the doc, 2.4 s invulnerable phase transition that clears enemy bullets and shows a phase-name card, boss HP bar, defeat → data core → save → victory screen.
- UI: Main menu (Jugar, Salir), HUD (signal-bar HP, shield meter, dash cooldown, weapon), Pause menu, "Conexión perdida" death screen with progress bar + retry, Victory screen. UI text in Spanish.
- Autoloads: Events, GameState, SaveManager (user://save.json, schema from 07-modelos.md, corrupted file → defaults), AudioManager.
- Tests: `game/tests/test_runner.gd` (extends SceneTree) running test_health_component, test_route_puzzle, test_boss_phases, test_save_manager, test_scenes_load; exits with quit(0) on success, quit(1) on failure, printing PASS/FAIL per test.
- Write `game/README.md` in Spanish: controls, how to run, how to run tests, project structure.

## Validation (mandatory, iterate until clean)
Godot executable: `C:/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`
1. `<godot> --headless --path game --import` (first run, to build the .godot cache)
2. `<godot> --headless --path game --quit` → must print no SCRIPT ERROR / Parse Error.
3. `<godot> --headless --path game -s res://tests/test_runner.gd` → all tests PASS, exit code 0.
4. Run the main scene briefly headless: `<godot> --headless --path game --quit-after 300` → no runtime errors.
Fix every error and warning you can. Do not stop until all four commands are clean.

## Final report
End with a concise summary: files created, what each milestone covers, exact output of the test run, and any known limitations or deviations from the docs.
