# M7 · Taller de Mejoras y Mapa de la red — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Byte puede gastar núcleos de datos en 7 mejoras, equipar 2 armas y 1 pasiva, cambiar de arma en el juego, y navegar Menú → Mapa de la red → Nivel / Taller.

**Architecture:** La lógica de progresión es un módulo puro (`Progression`, funciones estáticas sobre el Dictionary de guardado), así que se prueba sin escenas. Los datos son Resources `.tres` cargados por `Catalog`. `PacketPlayer` lee el guardado en `_ready()` para configurar armas y pasivas; la UI (Taller y Mapa) solo llama a `Progression` y a `GameState`.

**Tech Stack:** Godot 4.7.2, GDScript tipado, pruebas headless propias (`tests/test_runner.gd`).

**Spec:** `docs/03-mecanicas.md` (secciones *Disparo de datos* y *Progresión: núcleos de datos y mejoras*), `docs/07-modelos.md` (UpgradeData, save.json). Beads: `pq-8nz.1`–`pq-8nz.6`.

## Global Constraints

- Godot 4.7.2, GDScript con tipado estático; sin assets externos (todo se dibuja por código con `PQStyle`).
- Paquete: daño 1, 8/s, 480 px/s. Ráfaga triple: 0,6 c/u, 5/s, 420 px/s, 3 balas ±12°. Ping: 1,3, 6/s, 300 px/s, gira 180°/s.
- Costes: Más vida 2 (Permanente), Ráfaga triple 2 (Arma), Ping 2 (Arma), Dash extendido 1 (Permanente), Firewall reforzado 1 (Pasiva), Marcador 2 (Pasiva), Ralentizador 3 (Pasiva).
- Efectos: +1 PV; dash 96 px; escudo 150 y recarga ×1,3; enemigos marcados +25 % de daño; 1 vez por nivel, al quedar con 1 PV, balas enemigas al 50 % durante 3 s.
- Ranuras: 2 armas + 1 pasiva; las permanentes no ocupan ranura. `packet` siempre está disponible sin comprarse.
- Ids (también en save.json): `packet`, `triple`, `ping`, `more_health`, `long_dash`, `strong_firewall`, `marker`, `slowdown`.
- Textos de UI en español. Resolución lógica 640×360.

## Review Focus

1. **Comprar con núcleos justos o insuficientes:** con coste == núcleos la compra se hace y quedan 0; con menos se rechaza sin cambiar nada → Task 2 `test_buy_exact_and_insufficient`.
2. **Guardado editado a mano o antiguo:** un arma equipada que no existe o no se posee se ignora y Byte cae a `packet`, sin errores → Task 4 `test_player_falls_back_to_packet`.
3. **Quitar la última arma equipada:** siempre queda al menos 1 → Task 2 `test_cannot_unequip_last_weapon`.
4. **Ping sin enemigos en pantalla:** la bala va recta, sin `null` ni divisiones por cero → Task 3 `test_steer_without_target`.
5. **`swap_weapon` con una sola arma:** no hace nada y no rompe la cadencia → Task 4 `test_swap_with_single_weapon`.

---

## File Structure

| Archivo | Responsabilidad |
|---|---|
| `resources/weapons/triple.tres`, `ping.tres` | Datos de las armas nuevas |
| `resources/upgrades/*.tres` (7) | Catálogo de mejoras |
| `scripts/data/catalog.gd` (`class_name Catalog`) | Carga y busca armas y mejoras por id |
| `scripts/progression/progression.gd` (`class_name Progression`) | Reglas puras: comprar, equipar, consultar pasivas |
| `scripts/player/player.gd` (modificar) | Ranuras de arma, swap, disparo en abanico, pasivas |
| `scripts/player/projectile.gd` (modificar) | Teledirigido, marcador, escala de tiempo enemiga |
| `scripts/enemies/enemy_base.gd`, `scripts/bosses/router_boss.gd` (modificar) | `marked`, grupo `homing_target` |
| `scenes/ui/Workshop.tscn` + `scripts/ui/workshop.gd` | Taller de Mejoras |
| `scenes/main/NetworkMap.tscn` + `scripts/main/network_map.gd` | Mapa de la red |
| `scripts/main/main.gd`, `scripts/ui/victory_screen.gd`, `scripts/ui/hud.gd`, `scripts/autoload/game_state.gd` (modificar) | Navegación y HUD |
| `tests/test_progression.gd`, `tests/test_weapons.gd`, `tests/test_runner.gd` (modificar) | Pruebas |

---

### Task 1: Catálogo de datos (armas y mejoras)

**Files:**
- Create: `resources/weapons/triple.tres`, `resources/weapons/ping.tres`, `resources/upgrades/{more_health,triple,ping,long_dash,strong_firewall,marker,slowdown}.tres`, `scripts/data/catalog.gd`
- Test: `tests/test_progression.gd` (función `_test_catalog`)

**Interfaces:**
- Produces: `Catalog.weapon(id: StringName) -> WeaponData` (null si no existe), `Catalog.upgrade(id: StringName) -> UpgradeData` (null si no existe), `Catalog.upgrades() -> Array[UpgradeData]` (en el orden de la tabla de la spec). Las mejoras de tipo arma tienen el mismo id que su WeaponData.

- [ ] **Step 1: Test** `_test_catalog`: `Catalog.upgrades().size() == 7`; `Catalog.weapon(&"triple")`: damage 0.6, fire_rate 5, bullet_speed 420, spread_count 3, spread_angle_deg 12; `Catalog.weapon(&"ping")`: damage 1.3, fire_rate 6, bullet_speed 300, homing_turn_deg 180; `Catalog.upgrade(&"slowdown").cost == 3`; `Catalog.upgrade(&"more_health").kind == UpgradeData.Kind.PERMANENT`; `Catalog.upgrade(&"nope") == null`.
- [ ] **Step 2:** Añadir `"progression"` a `TESTS` en `test_runner.gd` y ejecutar → FAIL (falta `test_progression.gd`).
- [ ] **Step 3:** Crear los `.tres` y `catalog.gd` (preloads en un `const`, búsqueda lineal por id).
- [ ] **Step 4:** Ejecutar el runner → `PASS test_progression`.
- [ ] **Step 5:** Commit `feat(m7): catálogo de armas y mejoras`.

### Task 2: Reglas de progresión (comprar y equipar)

**Files:**
- Create: `scripts/progression/progression.gd`
- Test: `tests/test_progression.gd`

**Interfaces:**
- Consumes: `Catalog.upgrade`, `Catalog.weapon`.
- Produces (todas `static`, `data` = Dictionary de save.json):
  - `can_buy(data, id: StringName) -> bool` (existe, no se posee, `data_cores >= cost`)
  - `buy(data, id: StringName) -> bool` — resta núcleos, añade a `owned_upgrades`; si es arma y hay < 2 equipadas, la equipa.
  - `owns(data, id: StringName) -> bool` (`packet` siempre es true)
  - `toggle_weapon(data, id: StringName) -> bool` — si está equipada la quita (salvo que sea la última); si no, la añade si hay hueco (< 2) y se posee.
  - `set_passive(data, id: StringName) -> bool` — `&""` desequipa; solo acepta pasivas poseídas.
  - `has_effect(data, id: StringName) -> bool` — permanente poseída o pasiva equipada.
  - `equipped_weapons(data) -> Array[StringName]` — filtra los ids inexistentes o no poseídos; nunca vacío (fallback `[&"packet"]`).

- [ ] **Step 1: Tests** en `test_progression.gd`:
  - `test_buy_exact_and_insufficient`: con `data_cores = 2`, `buy(&"marker")` → true y `data_cores == 0`; `buy(&"long_dash")` con 0 → false y `owned_upgrades` sin cambios.
  - `test_no_double_buy`: comprar dos veces la misma → la segunda es false y los núcleos no bajan.
  - `test_weapon_autoequip`: con 4 núcleos, `buy(&"triple")` → `equipped_weapons == [&"packet", &"triple"]`; `buy(&"ping")` → sigue con 2 equipadas.
  - `test_cannot_unequip_last_weapon`: `toggle_weapon(&"triple")` → quita; `toggle_weapon(&"packet")` (única) → false y sigue equipada.
  - `test_passive_rules`: `set_passive(&"marker")` sin poseerla → false; después de comprarla → true y `has_effect(&"marker")`; `set_passive(&"more_health")` → false (es permanente); `has_effect(&"more_health")` tras comprarla → true.
  - `test_equipped_filters_invalid`: `equipped.weapons = ["laser", "ping"]` sin poseer ping → `[&"packet"]`.
- [ ] **Step 2:** Ejecutar → FAIL.
- [ ] **Step 3:** Implementar `progression.gd`. `buy` y los toggles no guardan a disco; guarda quien llama (`GameState.save()`).
- [ ] **Step 4:** Ejecutar → PASS.
- [ ] **Step 5:** Commit `feat(m7): reglas de compra y equipado`.

### Task 3: Proyectiles — abanico, teledirigido, marcador y ralentizador

**Files:**
- Modify: `scripts/player/projectile.gd`, `scripts/components/projectile_pool.gd:20`, `scripts/enemies/enemy_base.gd`, `scripts/bosses/router_boss.gd`
- Test: `tests/test_weapons.gd` (añadir `"weapons"` a `TESTS`)

**Interfaces:**
- Produces:
  - `static func Projectile.spread_directions(aim: Vector2, count: int, angle_deg: float) -> Array[Vector2]` — `count == 1` → `[aim]`; si no, ángulos repartidos de `-angle_deg` a `+angle_deg`.
  - `static func Projectile.steer(velocity: Vector2, to_target: Vector2, max_turn_rad: float) -> Vector2` — gira como mucho `max_turn_rad`, conserva el módulo; `to_target == Vector2.ZERO` → la misma velocidad.
  - `static var Projectile.enemy_time_scale: float = 1.0` — multiplica el `delta` de las balas enemigas.
  - Propiedades de `Projectile`: `homing_turn_rad: float`, `marks: bool`. `ProjectilePool.fire(...)` no cambia; el jugador configura la bala que devuelve.
  - `EnemyBase` y `RouterBoss` declaran `var marked: bool = false` y se añaden al grupo `homing_target`. Al impactar, si `marks`, el daño es ×1,25 cuando el objetivo ya estaba `marked` y luego se pone `marked = true`. `launch()` resetea `homing_turn_rad = 0` y `marks = false`.

- [ ] **Step 1: Tests** en `test_weapons.gd`: `spread_directions(Vector2.RIGHT, 3, 12)` → 3 vectores, el central `≈ RIGHT`, los extremos a `±deg_to_rad(12)` (tolerancia 0.001); `spread_directions(Vector2.UP, 1, 12) == [Vector2.UP]`; `test_steer_without_target`: `steer(Vector2(300,0), Vector2.ZERO, 0.05) == Vector2(300,0)`; `steer(Vector2(300,0), Vector2(0,1), deg_to_rad(3))` → ángulo `≈ deg_to_rad(3)` y módulo `≈ 300`.
- [ ] **Step 2:** Ejecutar → FAIL.
- [ ] **Step 3:** Implementar las funciones estáticas y el uso en `_physics_process`: el objetivo del teledirigido es el nodo de `homing_target` más cercano dentro de la cámara (si no hay, va recto); `max_turn = homing_turn_rad * delta`; las balas enemigas usan `delta * enemy_time_scale`.
- [ ] **Step 4:** Ejecutar el runner y `tests/test_integration.gd` → todo PASS.
- [ ] **Step 5:** Commit `feat(m7): abanico, ping teledirigido, marcador y escala enemiga`.

### Task 4: Byte usa sus ranuras de arma y sus pasivas

**Files:**
- Modify: `scripts/player/player.gd` (`_ready`, `shoot`, el bloque `swap_weapon` en ~187, `take_damage`), `scripts/ui/hud.gd:30`
- Test: `tests/test_weapons.gd`

**Interfaces:**
- Consumes: `Progression.equipped_weapons`, `Progression.has_effect`, `Catalog.weapon`, `Projectile.spread_directions`.
- Produces: `PacketPlayer.weapon_slots: Array[WeaponData]`, `PacketPlayer.weapon_index: int`, `func swap_weapon() -> void`, `func current_weapon() -> WeaponData`, `func apply_progression(data: Dictionary) -> void` (se llama desde `_ready` con `GameState.data`; las pruebas la llaman directamente). El HUD muestra `current_weapon().display_name.to_upper()`.

- [ ] **Step 1: Tests** (instanciando `res://scenes/player/Player.tscn` dentro de un Node2D con un `ProjectilePool`):
  - `test_player_falls_back_to_packet`: `apply_progression` con `equipped.weapons = ["laser"]` → `weapon_slots.size() == 1` y `current_weapon().id == &"packet"`.
  - `test_swap_with_single_weapon`: `swap_weapon()` → `weapon_index == 0`.
  - `test_swap_two_weapons`: con triple poseída y equipada → `swap_weapon()` → `current_weapon().id == &"triple"`; otra vez → `&"packet"`.
  - `test_passives_apply`: con `more_health`, `long_dash` y `strong_firewall` (pasiva) → `health.max_health == 4`, `dash_distance == 96`, `shield_max == 150`, `shield_recharge == 12 * 1.3`.
  - `test_triple_fires_three`: con triple activa, `shoot()` → 3 balas activas en `pool.player_bullets`.
- [ ] **Step 2:** Ejecutar → FAIL.
- [ ] **Step 3:** Implementar. `apply_progression` debe ser idempotente: calcula desde los valores base guardados (no acumula +1 PV en cada llamada). Ralentizador: en `take_damage`, si `has_effect(slowdown)`, no se ha usado en este nivel y los PV quedan en 1 → `Projectile.enemy_time_scale = 0.5` durante 3 s (temporizador con `process_always`) y luego vuelve a 1.0; también se restaura a 1.0 en `_exit_tree`. Los disparos de Ping ponen `homing_turn_rad = deg_to_rad(homing_turn_deg)`; con marcador activo, `marks = true`.
- [ ] **Step 4:** Ejecutar runner + integración → PASS.
- [ ] **Step 5:** Commit `feat(m7): ranuras de arma y pasivas en Byte`.

### Task 5: Taller de Mejoras y Mapa de la red

**Files:**
- Create: `scenes/ui/Workshop.tscn`, `scripts/ui/workshop.gd` (extends `PacketScreen`), `scenes/main/NetworkMap.tscn`, `scripts/main/network_map.gd`
- Modify: `scripts/autoload/game_state.gd` (añadir `const MAP`, `func open_map()`, `func open_workshop()`, `func save() -> Error`), `scripts/main/main.gd:11` (Jugar → `GameState.open_map`), `scripts/ui/victory_screen.gd` (botón "Continuar" → `open_map`)
- Test: `tests/test_scenes_load.gd` (subir el mínimo a 20 escenas)

**Interfaces:**
- Consumes: `Progression.*`, `Catalog.upgrades()`, `GameState.data`, `GameState.start_run`.
- Taller: título "TALLER DE MEJORAS", contador "NÚCLEOS: n", una fila (Button de 400 px) por mejora con `"<nombre> · <coste> · <estado>"`, donde estado ∈ {`Comprar`, `Sin núcleos`, `Equipada`, `Equipar`, `Instalada`}. Al pulsarla: comprar / alternar arma / alternar pasiva, `GameState.save()` y redibujar. Debajo, la descripción de la fila con foco. Botón "Volver al mapa".
- Mapa: 6 nodos conectados en línea (Red Local, Wi-Fi, Firewall, Servidor, Nube, Centro de datos) dibujados con `_draw`; el Mundo 1 es un botón "Entrar" → `GameState.start_run`; los demás muestran "BLOQUEADO" o, si están en `unlocked_worlds`, "PRÓXIMAMENTE". Botones "Taller" y "Menú".

- [ ] **Step 1:** Subir el umbral de `test_scenes_load` a 20 y ejecutar → FAIL (18 escenas).
- [ ] **Step 2:** Implementar las dos escenas y la navegación.
- [ ] **Step 3:** Ejecutar el runner → PASS; `--quit-after 300` sin errores.
- [ ] **Step 4:** Capturar `Workshop` y `NetworkMap` con `capture.gd` y revisar a 640×360 que nada se solapa.
- [ ] **Step 5:** Commit `feat(m7): taller de mejoras y mapa de la red`; cerrar en beads `pq-8nz.*` y actualizar `game/README.md` (controles: Q cambia de arma).
