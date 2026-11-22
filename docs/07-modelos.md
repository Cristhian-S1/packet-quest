# 07 · Modelos

Este documento cubre tres tipos de modelos:
1. **Modelos de datos:** Resources y estructuras de guardado.
2. **Modelos de entidades:** escenas, nodos, propiedades y señales.
3. **Modelos visuales:** silueta, tamaño y animaciones de cada personaje.

## 1 · Modelos de datos (Resources)

```gdscript
# res://scripts/data/weapon_data.gd
class_name WeaponData extends Resource
@export var id: StringName
@export var display_name: String
@export var damage: float = 1.0
@export var fire_rate: float = 8.0         # disparos por segundo
@export var bullet_speed: float = 480.0
@export var spread_count: int = 1
@export var spread_angle_deg: float = 0.0
@export var homing_turn_deg: float = 0.0   # 0 = no teledirigido

# res://scripts/data/upgrade_data.gd
class_name UpgradeData extends Resource
enum Kind { WEAPON, PASSIVE, PERMANENT }
@export var id: StringName
@export var display_name: String
@export var description: String
@export var cost: int = 1
@export var kind: Kind = Kind.PASSIVE

# res://scripts/data/boss_phase_data.gd
class_name BossPhaseData extends Resource
@export var name: String                   # se muestra en la tarjeta de fase
@export var health_threshold: float = 1.0  # empieza cuando PV/PV_max <= este valor
@export var attack_sequence: Array[StringName] = []
@export var recovery_multiplier: float = 1.0

# res://scripts/data/level_data.gd
class_name LevelData extends Resource
@export var id: StringName                 # "w1_l1"
@export var world: int = 1
@export var display_name: String
@export var scene: PackedScene
@export var boss_scene: PackedScene
```

### Partida guardada (`user://save.json`)

```json
{
  "version": 1,
  "unlocked_worlds": [1],
  "completed_levels": ["w1_l1"],
  "data_cores": 1,
  "collected_cores": ["w1_hidden_a"],
  "owned_upgrades": ["more_health"],
  "equipped": { "weapons": ["packet", "triple"], "passive": "" },
  "settings": { "screen_shake": true, "reduce_flashes": false, "assist_mode": false,
                "music_volume": 0.8, "sfx_volume": 0.9 },
  "stats": { "deaths": {"router_boss": 4}, "play_time_s": 812 }
}
```

## 2 · Modelos de entidades (escenas)

| Escena | Nodo raíz | Hijos clave | Script | Señales |
|---|---|---|---|---|
| `Player.tscn` | `CharacterBody2D` | `Visual` (Node2D con `_draw`), `Hurtbox` (Area2D), `Muzzle` (Marker2D), `ShieldArea` (Area2D), `InteractArea` (Area2D), `Camera2D` | `player.gd` | `health_changed(cur, max)`, `shield_changed(cur, max)`, `died` |
| `PlayerBullet.tscn` | `Area2D` | `CollisionShape2D`, `VisibleOnScreenNotifier2D` | `player_bullet.gd` | — |
| `EnemyBullet.tscn` | `Area2D` | Igual | `enemy_bullet.gd` | — |
| `EnemyBase` (script) | `CharacterBody2D` / `Area2D` | `Hurtbox`, `HealthComponent` | `enemy_base.gd` | `died` |
| `PopUp.tscn` | `Area2D` | Hereda de EnemyBase | `pop_up.gd` | |
| `NetworkWorm.tscn` | `PathFollow2D` + `Area2D` | | `network_worm.gd` | |
| `RouterBoss.tscn` | `Node2D` (arena) | `Boss` (Area2D), `Antennas`, `Platforms`, `BossHUD` | `router_boss.gd` | `phase_changed(i)`, `defeated` |
| `RoutePuzzle.tscn` | `Node2D` | `Emitter`, `Receiver`, `PuzzleNode`×3, `Door` | `route_puzzle.gd` | `solved` |
| `PuzzleNode.tscn` | `Area2D` | | `puzzle_node.gd` | `rotated(dir)` |
| `NetworkNode.tscn` | `Area2D` | | `network_node.gd` | `activated` |
| `Checkpoint.tscn` | `Area2D` | | `checkpoint.gd` | `reached` |
| `HUD.tscn` | `CanvasLayer` | Señal (PV), Escudo, Dash, Arma | `hud.gd` | |
| `DeathScreen.tscn` | `CanvasLayer` | Barra de progreso, botón Reintentar | `death_screen.gd` | `retry` |

### Componentes reutilizables

```gdscript
class_name HealthComponent extends Node
signal changed(current: float, maximum: float)
signal depleted
@export var max_health: float = 3.0
var current: float
func damage(amount: float) -> void
func heal(amount: float) -> void
```

### Máquina de estados del jugador

```
IDLE ⇄ RUN ⇄ JUMP → FALL → IDLE
  │      │      │      │
  └──────┴──► DASH ◄───┘   (vuelve al estado según is_on_floor)
SHIELD (desde IDLE/RUN, mientras se mantiene)
HURT (0,2 s de retroceso) → estado anterior
DEAD
```

### Máquina de estados de un jefe

```
INTRO → IDLE → TELEGRAPH(ataque) → ACTIVE → RECOVERY → IDLE …
                         │ (PV cruza umbral)
                         ▼
                 PHASE_TRANSITION (2,4 s, invulnerable, borra balas) → IDLE
DEFEATED → explosión de bits → emite `defeated`
```

## 3 · Modelos visuales

El prototipo dibuja todo con código (`_draw()`, `Polygon2D`, `Line2D`) para no depender de
assets. Las medidas siguientes sirven igual para el arte final en Aseprite.

| Personaje | Tamaño (px) | Silueta | Colores | Animaciones (frames) |
|---|---|---|---|---|
| **Byte** | 16×16 (hitbox 10×14) | Cubo redondeado con "cabecera" de paquete, 2 ojos, guantes blancos, patas de circuito, cañón cian | Cuerpo `#3BE8FF`, guantes `#FFFFFF`, contorno `#0B1A2E` | idle 4, run 6, jump 2, fall 2, dash 3, hurt 2, shield 2, shoot (capa) 2 |
| **Pop-up** | 20×16 | Ventana con barra de título y botón ✕ | Marco `#FF4FD8`, fondo `#2A0F3A` | aparecer 4, idle 2, disparar 3, morir 4 |
| **Gusano de red** | 24×10 (segmentos) | 4 segmentos redondos | `#9DFF4F` | mover 4, hincharse 2, dividirse 3 |
| **Spyware** | 12×12 | Imita un núcleo de datos, con un ojo oculto | Igual que el pickup + glitch `#FF3355` | disfraz 1, revelar 4, saltar 3 |
| **Troyano** | 20×24 | Caballito de madera pixelado con ruedas de engranaje | `#C9803A` | andar 4, abrir portal 4 |
| **Bot DDoS** | 10×10 | Bola con antena | `#FFB13B` | volar 2, brillar 2 |
| **Router Furioso** | 160×96 | Caja con 4 antenas, ojos LED, boca de puerto RJ45 | Carcasa `#1E2B44`, LEDs `#3BFF8A` → `#FF3355` en F2 | idle 4, cargar 3, disparar 3, furia 6, derrota 8 |
| **Malwarex** | 192×192 | Núcleo glitch con tentáculos de cable | `#FF3355`, `#B13BFF`, ruido | por fase |
