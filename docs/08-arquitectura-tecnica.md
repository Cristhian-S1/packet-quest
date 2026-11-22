# 08 · Arquitectura técnica

## Motor y configuración

- **Godot 4.7.2 estable**, GDScript con tipado estático (`var x: int`, `-> void`).
- Renderer: **Compatibility** (máxima compatibilidad: PCs de aula y exportación web).
- `display/window/size/viewport_width = 640`, `viewport_height = 360`
- `display/window/size/window_width_override = 1280`, `window_height_override = 720`
- `display/window/stretch/mode = "viewport"`, `stretch/scale_mode = "integer"`
- `rendering/textures/canvas_textures/default_texture_filter = 0` (Nearest)
- Física a 60 Hz.

## Estructura de carpetas

```
game/
├── project.godot
├── icon.svg
├── scenes/
│   ├── main/        Main.tscn (menú), NetworkMap.tscn
│   ├── player/      Player.tscn, PlayerBullet.tscn
│   ├── enemies/     PopUp.tscn, NetworkWorm.tscn, EnemyBullet.tscn
│   ├── bosses/      RouterBoss.tscn
│   ├── puzzles/     RoutePuzzle.tscn, PuzzleNode.tscn
│   ├── levels/      World1Level1.tscn
│   ├── objects/     Checkpoint.tscn, NetworkNode.tscn, Door.tscn, DataCore.tscn
│   └── ui/          HUD.tscn, DeathScreen.tscn, PauseMenu.tscn, VictoryScreen.tscn
├── scripts/
│   ├── autoload/    game_state.gd, save_manager.gd, audio_manager.gd, events.gd
│   ├── components/  health_component.gd, hitbox.gd, hurtbox.gd
│   ├── data/        weapon_data.gd, upgrade_data.gd, boss_phase_data.gd, level_data.gd
│   └── …            (un script junto a cada escena, en scripts/ con la misma ruta)
├── resources/       weapons/*.tres, upgrades/*.tres
├── assets/          sprites/, audio/, fonts/ (vacías en el prototipo)
└── tests/           test_runner.gd + test_*.gd (pruebas headless)
```

## Autoloads (singletons)

| Nombre | Responsabilidad |
|---|---|
| `Events` | Bus de señales global: `player_died`, `boss_defeated(id)`, `puzzle_solved(id)`, `checkpoint_reached(pos)`, `core_collected(id)` |
| `GameState` | Estado de la partida en curso: núcleos, mejoras, checkpoint actual, nivel actual |
| `SaveManager` | Lee y escribe `user://save.json` (modelo en `07-modelos.md`) |
| `AudioManager` | SFX y música; en el prototipo, sonidos sintetizados con `AudioStreamGenerator` o silencio si no hay audio |

## Capas de colisión

| Capa | Nombre | La usa | Detecta (mask) |
|---:|---|---|---|
| 1 | `world` | TileMap, plataformas, puertas | — |
| 2 | `player` | Cuerpo de Byte | world |
| 3 | `enemy` | Hurtbox de enemigos y jefes | player_bullet |
| 4 | `player_bullet` | Balas de Byte | enemy, world |
| 5 | `enemy_bullet` | Balas enemigas | player, shield, world |
| 6 | `interactable` | Nodos de red, puzles, checkpoints | player |
| 7 | `hazard` | Pinchos, vacío, láseres | player |
| 8 | `shield` | Área del escudo | enemy_bullet |

## Patrones de código

- **Composición:** `HealthComponent`, `Hitbox` y `Hurtbox` como nodos reutilizables.
- **Máquina de estados** con un `enum` y `match` en el jugador y los jefes (sencillo de leer para estudiantes).
- **Pools de balas:** sin `queue_free` constante; se reciclan instancias desactivadas.
- **Señales** hacia arriba y llamadas hacia abajo: los hijos emiten señales y los padres llaman métodos.
- **Datos en Resources:** armas, mejoras y fases de jefe son `.tres` editables sin tocar código.
- Sin dependencias externas ni addons obligatorios.

## Pruebas automatizadas

- `tests/test_runner.gd` se ejecuta con `godot --headless --path game -s res://tests/test_runner.gd`.
- Cubre la lógica pura: `HealthComponent`, la comprobación de solución de `RoutePuzzle`, las transiciones de fase del jefe según los PV, y guardar y cargar `SaveManager`.
- Finaliza con `quit(0)` si todo pasa o `quit(1)` si algo falla, para poder usarse en CI.

## Exportación

- Windows Desktop (`.exe`), Linux (x86_64) y Web (HTML5, Compatibility).
- Los presets se definen en `export_presets.cfg` cuando se instalen las plantillas de exportación.
