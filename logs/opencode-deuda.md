# Deuda técnica — pq-ayx

Revisión de `logs/opencode-code-review.md`, puntos 3, 5, 6, 7, 8 y 9.

| Punto | Vigente | Qué hice |
|-------|---------|----------|
| 3 · `Hitbox` nunca instanciada | sí | Eliminé `scripts/components/hitbox.gd` (clase muerta; los enemigos reciben daño por raycast). |
| 5 · `boss_defeated`/`puzzle_solved` sin listener | no | Ya resuelto: `audio_manager.gd:29-30` conecta ambas señales. |
| 6 · `player.died` sin listener | sí | Eliminé `signal died` y su `died.emit()`; el HUD usa `Events.player_died`. |
| 7 · `InteractArea` sin uso | sí | Eliminé el bloque `interact_area`; `interact()` ya busca por grupo + distancia. |
| 8 · `enemy_base.collision_mask = 8` inerte | sí | Puse `collision_mask = 0` (el enemigo no detecta nada por física; el daño es por raycast). |
| 9 · `VisibleOnScreenNotifier2D` sin conectar | no | Ya resuelto: `projectile.gd` usa culling manual (`cull_rect`) y no tiene notifier. |

Verificación: `bash tools/run-tests.sh --integration` → `RESULTADO: 21/21 PASS` + `PASS integration`;
`bash tools/run-e2e.sh` → `PASS e2e`.
