> build · deepseek-v4-pro
→ Skill "test-driven-development" 
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
$ git status && git log --oneline -5
At line:1 char:277
+ ... PORT.md only for broad architecture context." ; git status && git log ...
+                                                                ~~
The token '&&' is not a valid statement separator in this version.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : InvalidEndOfLine
> build · deepseek-v4-pro
$ bash --version
GNU bash, version 5.3.15(2)-release (x86_64-pc-cygwin)
Copyright (C) 2025 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
$ git log --oneline -8
548394f docs: especificación M8 Mundo 2 Wi-Fi; config MCP godot para Claude Code y opencode
7ae5c65 Merge feat/m7-taller: M7 taller de mejoras y mapa de la red
48cebe1 docs: logs de revisión M7 y graphify
4b61d05 docs: grafo de conocimiento graphify (245 nodos, 57 comunidades)
ed9ab90 fix(m7): el Ralentizador cuenta en tiempo de juego; docs de herramientas
82676f4 feat(m7): taller de mejoras y mapa de la red
bebafe8 feat(m7): ranuras de arma y pasivas en Byte
ad4f137 feat(m7): abanico, ping teledirigido, marcador y escala enemiga
$ git status
On branch fix/m7-minors
nothing to commit, working tree clean
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
Baseline verde (7/7 PASS). Empiezo el TDD punto por punto.
## Punto 3 — RED: enemigo muerto sale de `homing_target`
← Edit game/tests/test_weapons.gd
Index: game/tests/test_weapons.gd
===================================================================
--- game/tests/test_weapons.gd
+++ game/tests/test_weapons.gd
@@ -9,8 +9,9 @@
 	finished = false
 	_test_spread_directions()
 	_test_steer_without_target()
 	_test_steer_limits_turn()
+	_test_dead_enemy_leaves_homing(tree)
 	await _test_player(tree)
 	check(player_checked, "prueba del jugador abortada por un error de script")
 	finished = true
 	return errors
> build · deepseek-v4-pro
← Edit game/tests/test_weapons.gd
Index: game/tests/test_weapons.gd
===================================================================
--- game/tests/test_weapons.gd
+++ game/tests/test_weapons.gd
@@ -86,8 +86,16 @@
 func check(condition: bool, message: String) -> void:
 	if not condition:
 		errors.append(message)
+func _test_dead_enemy_leaves_homing(tree: SceneTree) -> void:
+	var enemy: EnemyBase = EnemyBase.new()
+	tree.root.add_child(enemy)
+	check(enemy.is_in_group("homing_target"), "enemigo vivo está en homing_target")
+	enemy._die()
+	check(not enemy.is_in_group("homing_target"), "enemigo muerto sale de homing_target")
+	enemy.queue_free()
+
 func _test_spread_directions() -> void:
 	var dirs: Array[Vector2] = Projectile.spread_directions(Vector2.RIGHT, 3, 12.0)
 	check(dirs.size() == 3, "abanico: 3 direcciones")
 	if dirs.size() == 3:
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
FAIL test_weapons: enemigo muerto sale de homing_target
RESULTADO: 6/7 PASS
> build · deepseek-v4-pro
RED confirmado. Ahora la corrección en `enemy_base.gd`:
← Edit game/scripts/enemies/enemy_base.gd
Index: game/scripts/enemies/enemy_base.gd
===================================================================
--- game/scripts/enemies/enemy_base.gd
+++ game/scripts/enemies/enemy_base.gd
@@ -87,8 +87,9 @@
 func _die() -> void:
 	state = State.DEAD
 	timer = 0.3
 	collision_layer = 0
+	remove_from_group("homing_target")
 	Events.impact.emit(0.03, 0.0)
 	if player != null and randf() < 0.1:
 		var cache: DataCore = DataCore.new()
 		cache.cache_fragment = true
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
Verde. Commit del punto 3:
$ git add game/scripts/enemies/enemy_base.gd game/tests/test_weapons.gd; git commit -m "fix(m7): enemigos muertos salen del grupo homing_target"
[fix/m7-minors 75003dd] fix(m7): enemigos muertos salen del grupo homing_target
 2 files changed, 10 insertions(+)
> build · deepseek-v4-pro
## Punto 5 — RED: sfx distinto por arma
Primero añado las pruebas en `test_weapons.gd`.
← Edit game/tests/test_weapons.gd
Index: game/tests/test_weapons.gd
===================================================================
--- game/tests/test_weapons.gd
+++ game/tests/test_weapons.gd
@@ -9,8 +9,9 @@
 	finished = false
 	_test_spread_directions()
 	_test_steer_without_target()
 	_test_steer_limits_turn()
+	_test_weapon_sfx()
 	_test_dead_enemy_leaves_homing(tree)
 	await _test_player(tree)
 	check(player_checked, "prueba del jugador abortada por un error de script")
 	finished = true
> build · deepseek-v4-pro
← Edit game/tests/test_weapons.gd
Index: game/tests/test_weapons.gd
===================================================================
--- game/tests/test_weapons.gd
+++ game/tests/test_weapons.gd
@@ -95,8 +95,20 @@
 	enemy._die()
 	check(not enemy.is_in_group("homing_target"), "enemigo muerto sale de homing_target")
 	enemy.queue_free()
+func _test_weapon_sfx() -> void:
+	check(Catalog.weapon(&"packet").sfx == &"packet", "sfx: packet por defecto")
+	check(Catalog.weapon(&"triple").sfx == &"triple", "sfx: triple propio")
+	check(Catalog.weapon(&"ping").sfx == &"ping", "sfx: ping propio")
+	check(Catalog.weapon(&"triple").sfx != Catalog.weapon(&"packet").sfx
+		and Catalog.weapon(&"ping").sfx != Catalog.weapon(&"packet").sfx
+		and Catalog.weapon(&"triple").sfx != Catalog.weapon(&"ping").sfx, "sfx: cada arma un sonido")
+	AudioManager.play_sfx(&"packet")
+	var packet_pitch: float = AudioManager.last_pitch
+	AudioManager.play_sfx(&"ping")
+	check(AudioManager.last_pitch != packet_pitch, "sfx: variación de tono por arma")
+
 func _test_spread_directions() -> void:
 	var dirs: Array[Vector2] = Projectile.spread_directions(Vector2.RIGHT, 3, 12.0)
 	check(dirs.size() == 3, "abanico: 3 direcciones")
 	if dirs.size() == 3:
> build · deepseek-v4-pro
← Edit game/tests/test_weapons.gd
Index: game/tests/test_weapons.gd
===================================================================
--- game/tests/test_weapons.gd
+++ game/tests/test_weapons.gd
@@ -64,8 +64,9 @@
 	player.swap_weapon()
 	for bullet: Projectile in pool.player_bullets:
 		bullet.deactivate()
 	player.shoot()
+	check(AudioManager.last_sfx == &"triple", "disparo usa el sfx del arma equipada")
 	var active: int = 0
 	for bullet: Projectile in pool.player_bullets:
 		if bullet.active:
 			active += 1
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
SCRIPT ERROR: Invalid access to property or key 'sfx' on a base object of type 'Resource (WeaponData)'.
SCRIPT ERROR: Invalid access to property or key 'last_sfx' on a base object of type 'Node (audio_manager.gd)'.
FAIL test_weapons: prueba del jugador abortada por un error de script
RESULTADO: 6/7 PASS
> build · deepseek-v4-pro
RED confirmado (errores de `sfx` y `last_sfx`). Ahora la implementación:
← Edit game/scripts/data/weapon_data.gd
Index: game/scripts/data/weapon_data.gd
===================================================================
--- game/scripts/data/weapon_data.gd
+++ game/scripts/data/weapon_data.gd
@@ -8,4 +8,5 @@
 @export var bullet_speed: float = 480.0
 @export var spread_count: int = 1
 @export var spread_angle_deg: float = 0.0
 @export var homing_turn_deg: float = 0.0
+@export var sfx: StringName = &"packet"
> build · deepseek-v4-pro
← Edit game/scripts/player/player.gd
Index: game/scripts/player/player.gd
===================================================================
--- game/scripts/player/player.gd
+++ game/scripts/player/player.gd
@@ -324,9 +324,9 @@
 		if bullet != null:
 			bullet.homing_turn_rad = deg_to_rad(item.homing_turn_deg)
 			bullet.marks = marker_active
 	shoot_wait += 1.0 / item.fire_rate
-	AudioManager.play_sfx(&"packet")
+	AudioManager.play_sfx(item.sfx)
 func interact() -> void:
 	var nearest: Node2D = null
 	var distance: float = interact_range + 0.01
> build · deepseek-v4-pro
← Write game/scripts/autoload/audio_manager.gd
Wrote file successfully: game/scripts/autoload/audio_manager.gd
> build · deepseek-v4-pro
← Edit game/resources/weapons/triple.tres
Index: game/resources/weapons/triple.tres
===================================================================
--- game/resources/weapons/triple.tres
+++ game/resources/weapons/triple.tres
@@ -11,4 +11,5 @@
 bullet_speed = 420.0
 spread_count = 3
 spread_angle_deg = 12.0
 homing_turn_deg = 0.0
+sfx = &"triple"
← Edit game/resources/weapons/ping.tres
Index: game/resources/weapons/ping.tres
===================================================================
--- game/resources/weapons/ping.tres
+++ game/resources/weapons/ping.tres
@@ -11,4 +11,5 @@
 bullet_speed = 300.0
 spread_count = 1
 spread_angle_deg = 0.0
 homing_turn_deg = 180.0
+sfx = &"ping"
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
Verde. Commit del punto 5:
$ git add game/scripts/data/weapon_data.gd game/scripts/player/player.gd game/scripts/autoload/audio_manager.gd game/resources/weapons/triple.tres game/resources/weapons/ping.tres game/tests/test_weapons.gd; git commit -m "fix(m7): sonido de disparo distinto por arma (campo sfx y variación de tono)"
[fix/m7-minors 5a02eaa] fix(m7): sonido de disparo distinto por arma (campo sfx y variación de tono)
 6 files changed, 34 insertions(+), 2 deletions(-)
> build · deepseek-v4-pro
## Punto 6 — RED: comprar pasiva la auto-equipa
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -11,8 +11,9 @@
 	_test_no_double_buy()
 	_test_weapon_autoequip()
 	_test_cannot_unequip_last_weapon()
 	_test_passive_rules()
+	_test_buy_passive_autoequips()
 	_test_equipped_filters_invalid()
 	_test_workshop_status()
 	finished = true
 	return errors
> build · deepseek-v4-pro
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -68,8 +68,16 @@
 	check(Progression.has_effect(data, &"more_health"), "efecto de permanente poseída")
 	check(Progression.set_passive(data, &""), "desequipar pasiva")
 	check(not Progression.has_effect(data, &"marker"), "pasiva desequipada sin efecto")
+func _test_buy_passive_autoequips() -> void:
+	var data: Dictionary = fresh(6)
+	check(Progression.buy(data, &"marker"), "compra pasiva marker")
+	check(Progression.has_effect(data, &"marker"), "pasiva se autoequipa al comprar con ranura vacía")
+	check(Progression.buy(data, &"slowdown"), "compra pasiva slowdown")
+	check(Progression.has_effect(data, &"marker"), "nueva pasiva no desequipa la equipada")
+	check(not Progression.has_effect(data, &"slowdown"), "segunda pasiva no se autoequipa sobre la primera")
+
 func _test_workshop_status() -> void:
 	var workshop: Script = load("res://scripts/ui/workshop.gd") as Script
 	var data: Dictionary = fresh(2)
 	check(workshop.call("status", data, Catalog.upgrade(&"slowdown")) == "Sin núcleos", "taller: sin núcleos")
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
FAIL test_progression: pasiva se autoequipa al comprar con ranura vacía; nueva pasiva no desequipa la equipada
PASS test_weapons
RESULTADO: 6/7 PASS
> build · deepseek-v4-pro
RED confirmado. Implemento en `progression.gd`:
← Edit game/scripts/progression/progression.gd
Index: game/scripts/progression/progression.gd
===================================================================
--- game/scripts/progression/progression.gd
+++ game/scripts/progression/progression.gd
@@ -22,8 +22,10 @@
 	data["data_cores"] = int(data["data_cores"]) - item.cost
 	(data["owned_upgrades"] as Array).append(String(id))
 	if item.kind == UpgradeData.Kind.WEAPON and equipped_weapons(data).size() < MAX_WEAPONS:
 		_set_weapons(data, equipped_weapons(data) + [id])
+	elif item.kind == UpgradeData.Kind.PASSIVE and str(data.get("equipped", {}).get("passive", "")) == "":
+		set_passive(data, id)
 	return true
 static func equipped_weapons(data: Dictionary) -> Array[StringName]:
 	var result: Array[StringName] = []
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
$ git add game/scripts/progression/progression.gd game/tests/test_progression.gd; git commit -m "fix(m7): comprar una pasiva la equipa si no hay ninguna equipada"
[fix/m7-minors 249f5b9] fix(m7): comprar una pasiva la equipa si no hay ninguna equipada
 2 files changed, 11 insertions(+)
> build · deepseek-v4-pro
## Punto 7 — RED: estado "Ranuras llenas"
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -14,8 +14,9 @@
 	_test_passive_rules()
 	_test_buy_passive_autoequips()
 	_test_equipped_filters_invalid()
 	_test_workshop_status()
+	_test_workshop_slots_full()
 	finished = true
 	return errors
 func fresh(cores: int) -> Dictionary:
> build · deepseek-v4-pro
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -90,8 +90,16 @@
 	data["data_cores"] = 2
 	Progression.buy(data, &"more_health")
 	check(workshop.call("status", data, Catalog.upgrade(&"more_health")) == "Instalada", "taller: permanente")
+func _test_workshop_slots_full() -> void:
+	var workshop: Script = load("res://scripts/ui/workshop.gd") as Script
+	var data: Dictionary = fresh(4)
+	Progression.buy(data, &"triple")
+	Progression.buy(data, &"ping")
+	check(workshop.call("status", data, Catalog.upgrade(&"ping")) == "Ranuras llenas", "taller: ranuras llenas")
+	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipada", "taller: arma equipada")
+
 func _test_equipped_filters_invalid() -> void:
 	var data: Dictionary = fresh(0)
 	data["equipped"]["weapons"] = ["laser", "ping"]
 	check(Progression.equipped_weapons(data) == [&"packet"], "ids inválidos o no poseídos → packet")
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
FAIL test_progression: taller: ranuras llenas
PASS test_weapons
RESULTADO: 6/7 PASS
> build · deepseek-v4-pro
RED confirmado. Implemento en `workshop.gd`:
← Edit game/scripts/ui/workshop.gd
Index: game/scripts/ui/workshop.gd
===================================================================
--- game/scripts/ui/workshop.gd
+++ game/scripts/ui/workshop.gd
@@ -47,9 +47,11 @@
 	match item.kind:
 		UpgradeData.Kind.PERMANENT:
 			return "Instalada"
 		UpgradeData.Kind.WEAPON:
-			return "Equipada" if item.id in Progression.equipped_weapons(data) else "Equipar"
+			if item.id in Progression.equipped_weapons(data):
+				return "Equipada"
+			return "Ranuras llenas" if Progression.equipped_weapons(data).size() >= Progression.MAX_WEAPONS else "Equipar"
 		_:
 			return "Equipada" if Progression.has_effect(data, item.id) else "Equipar"
 func _press(id: StringName) -> void:
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
$ git add game/scripts/ui/workshop.gd game/tests/test_progression.gd; git commit -m "fix(m7): el estado 'Equipar' indica 'Ranuras llenas' con 2 armas equipadas"
[fix/m7-minors 0ed3ad6] fix(m7): el estado 'Equipar' indica 'Ranuras llenas' con 2 armas equipadas
 2 files changed, 12 insertions(+), 1 deletion(-)
> build · deepseek-v4-pro
## Punto 8 — RED: `Catalog.upgrades()` devuelve una copia
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -15,8 +15,9 @@
 	_test_buy_passive_autoequips()
 	_test_equipped_filters_invalid()
 	_test_workshop_status()
 	_test_workshop_slots_full()
+	_test_upgrades_returns_copy()
 	finished = true
 	return errors
 func fresh(cores: int) -> Dictionary:
> build · deepseek-v4-pro
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -99,8 +99,14 @@
 	Progression.buy(data, &"ping")
 	check(workshop.call("status", data, Catalog.upgrade(&"ping")) == "Ranuras llenas", "taller: ranuras llenas")
 	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipada", "taller: arma equipada")
+func _test_upgrades_returns_copy() -> void:
+	var snapshot: int = Catalog.upgrades().size()
+	var copy: Array[UpgradeData] = Catalog.upgrades()
+	copy.clear()
+	check(Catalog.upgrades().size() == snapshot, "catálogo: upgrades() devuelve una copia")
+
 func _test_equipped_filters_invalid() -> void:
 	var data: Dictionary = fresh(0)
 	data["equipped"]["weapons"] = ["laser", "ping"]
 	check(Progression.equipped_weapons(data) == [&"packet"], "ids inválidos o no poseídos → packet")
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
ERROR: Array is in read-only state.
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
El array `const` es de solo lectura, así que la mutación lanza error en lugar de vaciarlo. Ajusto la prueba para que detecte la copia mutable:
← Edit game/tests/test_progression.gd
Index: game/tests/test_progression.gd
===================================================================
--- game/tests/test_progression.gd
+++ game/tests/test_progression.gd
@@ -100,12 +100,11 @@
 	check(workshop.call("status", data, Catalog.upgrade(&"ping")) == "Ranuras llenas", "taller: ranuras llenas")
 	check(workshop.call("status", data, Catalog.upgrade(&"triple")) == "Equipada", "taller: arma equipada")
 func _test_upgrades_returns_copy() -> void:
-	var snapshot: int = Catalog.upgrades().size()
 	var copy: Array[UpgradeData] = Catalog.upgrades()
 	copy.clear()
-	check(Catalog.upgrades().size() == snapshot, "catálogo: upgrades() devuelve una copia")
+	check(copy.is_empty() and Catalog.upgrades().size() == 7, "catálogo: upgrades() devuelve una copia mutable")
 func _test_equipped_filters_invalid() -> void:
 	var data: Dictionary = fresh(0)
 	data["equipped"]["weapons"] = ["laser", "ping"]
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
ERROR: Array is in read-only state.
FAIL test_progression: catálogo: upgrades() devuelve una copia mutable
PASS test_weapons
RESULTADO: 6/7 PASS
> build · deepseek-v4-pro
RED confirmado. Implemento en `catalog.gd`:
← Edit game/scripts/data/catalog.gd
Index: game/scripts/data/catalog.gd
===================================================================
--- game/scripts/data/catalog.gd
+++ game/scripts/data/catalog.gd
@@ -31,5 +31,5 @@
 			return item
 	return null
 static func upgrades() -> Array[UpgradeData]:
-	return UPGRADES
+	return UPGRADES.duplicate()
> build · deepseek-v4-pro
$ bash tools/run-tests.sh
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
> build · deepseek-v4-pro
Verde. Commit del punto 8:
$ git add game/scripts/data/catalog.gd game/tests/test_progression.gd; git commit -m "fix(m7): Catalog.upgrades() devuelve una copia en lugar de la referencia"
[fix/m7-minors 7769d3b] fix(m7): Catalog.upgrades() devuelve una copia en lugar de la referencia
 2 files changed, 7 insertions(+), 1 deletion(-)
> build · deepseek-v4-pro
Los 5 puntos completados. Ejecuto la suite completa con integración:
$ bash tools/run-tests.sh --integration
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia
> build · deepseek-v4-pro
$ git status; git log --oneline -6
On branch fix/m7-minors
nothing to commit, working tree clean
7769d3b fix(m7): Catalog.upgrades() devuelve una copia en lugar de la referencia
0ed3ad6 fix(m7): el estado 'Equipar' indica 'Ranuras llenas' con 2 armas equipadas
249f5b9 fix(m7): comprar una pasiva la equipa si no hay ninguna equipada
5a02eaa fix(m7): sonido de disparo distinto por arma (campo sfx y variación de tono)
75003dd fix(m7): enemigos muertos salen del grupo homing_target
548394f docs: especificación M8 Mundo 2 Wi-Fi; config MCP godot para Claude Code y opencode
> build · deepseek-v4-pro
He terminado los cinco hallazgos Minor con TDD (un commit por punto) y la suite completa está en verde.
## Resumen
| Punto | Cambio | Commit |
|-------|--------|--------|
| 3 | `enemy_base.gd`: `remove_from_group("homing_target")` en `_die()` | `75003dd` |
| 5 | `weapon_data.gd`: campo `sfx`; `player.gd`: usa `item.sfx`; `audio_manager.gd`: variación de tono por arma; `.tres` de triple/ping con sfx propio | `5a02eaa` |
| 6 | `progression.gd`: `buy()` auto-equipa pasiva si la ranura está vacía | `249f5b9` |
| 7 | `workshop.gd`: estado `"Ranuras llenas"` con 2 armas equipadas | `0ed3ad6` |
| 8 | `catalog.gd`: `upgrades()` devuelve `UPGRADES.duplicate()` | `7769d3b` |
Cada punto siguió RED (test fallando primero) → GREEN (fix) → commit. No toqué `scripts/main/network_map.gd` ni los hallazgos 4 y 9. No usé `bd` ni hice push.
## Resultado literal de la suite completa
```
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
RESULTADO: 7/7 PASS
PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia
```
Working tree limpio, en rama `fix/m7-minors`, sin cambios pendientes.
Nota de implementación sobre el punto 5: como el prototipo no tiene assets de audio (todo es silencio deliberado en `AudioManager`), añadí el campo `sfx` a `WeaponData` (valores `packet`/`triple`/`ping`) y un mapa `SFX_PITCH` con `pitch_scale` distinto por arma, aplicado cuando se suministre un `AudioStream`; además dejé `last_sfx`/`last_pitch` observables para verificar el comportamiento en headless.
