class_name BotPilot
extends RefCounted

## Piloto reutilizable para las pruebas de extremo a extremo.
## Conduce a Byte exclusivamente mediante Input.action_press / action_release
## (nunca teletransporta ni toca posiciones/velocidades; solo el arranque de cada
## prueba puede fijar el estado inicial). Ofrece las primitivas de reloj, entrada
## y espera con límite de frames que usan las suites.

const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"aim_up", &"aim_down", &"jump",
	&"shoot", &"dash", &"shield", &"lock_aim", &"interact", &"swap_weapon", &"ui_accept",
]

var tree: SceneTree

func _init(scene_tree: SceneTree) -> void:
	tree = scene_tree

# --- Reloj ---------------------------------------------------------------

## Espera `count` frames completos (física + proceso), como el runner original.
func frames(count: int) -> void:
	for _i: int in range(count):
		await tree.physics_frame
		await tree.process_frame

## Espera solo frames de física (más rápido para rutinas de movimiento).
func physics_frames(count: int) -> void:
	for _i: int in range(count):
		await tree.physics_frame

# --- Entrada -------------------------------------------------------------

func press(action: StringName) -> void:
	Input.action_press(action)

func release(action: StringName) -> void:
	Input.action_release(action)

## Pulsa y suelta una acción en el siguiente frame.
func tap(action: StringName) -> void:
	Input.action_press(action)
	await frames(1)
	Input.action_release(action)

## Mantiene una acción durante `count` frames y la suelta.
func hold(action: StringName, count: int) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)

## Suelta toda acción del piloto (evita teclas colgadas entre fases).
func release_all() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)

# --- Esperas con límite --------------------------------------------------

## Espera hasta que `condition` (Callable que devuelve bool) sea cierto.
## Devuelve true si se cumplió antes de agotar `max_frames`.
func wait_until(condition: Callable, max_frames: int) -> bool:
	for _i: int in range(max_frames):
		await tree.physics_frame
		await tree.process_frame
		if bool(condition.call()):
			return true
	return false

## Espera hasta que `condition` sea cierto o hasta que `abort` lo sea (p. ej. muerte).
## Devuelve true si fue por `condition` (éxito).
func wait_until_or(condition: Callable, abort: Callable, max_frames: int) -> bool:
	for _i: int in range(max_frames):
		await tree.physics_frame
		await tree.process_frame
		if bool(abort.call()):
			return false
		if bool(condition.call()):
			return true
	return false

# --- Menús ---------------------------------------------------------------

## Activa el botón enfocado como pulsar Enter/Espacio (ui_accept).
func confirm() -> void:
	await key_tap(KEY_ENTER)

## Envía eventos reales a la interfaz, incluidos los nodos que reciben _input.
func key_tap(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	var released: InputEventKey = InputEventKey.new()
	released.keycode = key
	released.pressed = false
	Input.parse_input_event(released)
	await tree.process_frame

# --- Movimiento ----------------------------------------------------------

## Camina manteniendo `direction` durante `count` frames.
func walk(direction: StringName, count: int) -> void:
	await hold(direction, count)

## Camina hasta alcanzar `target_x` (en horizontal) y suelta la tecla.
## Devuelve false si no lo alcanza en `max_frames`.
func move_to_x(player: Node2D, target_x: float, max_frames: int = 900) -> bool:
	var direction: StringName = &"move_right" if target_x >= player.global_position.x else &"move_left"
	Input.action_press(direction)
	var reached: bool = false
	for _i: int in range(max_frames):
		await tree.physics_frame
		await tree.process_frame
		if direction == &"move_right" and player.global_position.x >= target_x:
			reached = true
			break
		if direction == &"move_left" and player.global_position.x <= target_x:
			reached = true
			break
	Input.action_release(direction)
	return reached
