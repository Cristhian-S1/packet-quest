Follow-up pass on the Godot project in `game/` (Packet Quest: La Red Rota). The design docs in `docs/` were corrected after an independent review. Update the implementation to match, then re-run the full validation.

## Doc corrections to apply in code
1. Damage: every enemy projectile, enemy/boss contact, boss attack and hazard deals exactly 1 HP to Byte (`03-mecanicas.md`, `05-enemigos-y-jefes.md`).
2. Ground baseline is y = 304 (tile row 19, 16 px grid), not 312. Align level geometry to the 16 px grid.
3. Level 1-1 is 2720 px wide; the boss is a separate scene `RouterBoss.tscn` reached through the door at x = 2720. Camera limits must match.
4. Checkpoints at x = 1760 (mid-level), at the puzzle entrance (x = 2240) and at the boss arena start (dying in the boss restarts the boss, not the level).
5. The 96 px gap in S2 must be crossable with jump + dash (base dash 72 px) but NOT with a plain jump. Verify with the movement numbers.
6. Router arena: floor top at y = 304, the two floating chip platforms' top at y = 256 (reachable with the ~60 px jump).
7. Ping weapon damage is 1.3 (if weapon data exists).
8. Upgrade kinds: "Más vida" and "Dash extendido" are PERMANENT.

## Visual bugs seen in real screenshots (640x360)
9. Main menu: the two-line title "PACKET / QUEST" overlaps the subtitle "LA RED ROTA". Reduce title size or reflow so nothing overlaps.
10. Router boss HP bar is a huge solid magenta block (~320x28) covering the antennas and the telegraph circle. Make it a thin bar (≈ 6 px tall) with a dark background, outline and phase markers at the 50 % threshold, placed at the top of the screen under the HUD line, not over the boss.

## Also
- Read `logs/opencode-code-review.md` if it exists and fix every valid issue it lists (skip ones that are wrong, and say why).
- Keep all existing tests passing; add a test that asserts damage = 1 per enemy bullet hit, and one that checks the boss restart checkpoint.

## Validation (mandatory)
Godot: `C:/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`
1. `--headless --path game --import`
2. `--headless --path game --quit` (no SCRIPT ERROR / Parse Error)
3. `--headless --path game -s res://tests/test_runner.gd` (all PASS, exit 0)
4. `--headless --path game --quit-after 300` (no runtime errors)

End with a concise report: what changed, test output, remaining limitations.
