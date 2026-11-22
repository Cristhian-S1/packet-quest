class_name TrojanPortal
extends Node2D

const POPUP: PackedScene = preload("res://scenes/enemies/PopUp.tscn")

var _popups: Array[PopUp] = []
var _warning_time: float = 0.0
var _warning_left: float = 0.0
var _opened: bool = false
var _closed: bool = false

static func spawn_offsets() -> Array[Vector2]:
	return [Vector2(-28, 0), Vector2(28, 0)]

static func spawn_count(alive: int) -> int:
	return clampi(4 - alive, 0, 2)

func _ready() -> void:
	z_index = -1
	set_process(false)

func warn(duration: float) -> void:
	_warning_time = duration
	_warning_left = duration
	set_process(true)
	queue_redraw()

func activate() -> void:
	if _closed:
		return
	_opened = true
	_warning_left = 0.0
	set_process(false)
	for index: int in range(_popups.size() - 1, -1, -1):
		if not is_instance_valid(_popups[index]) or _popups[index].state == EnemyBase.State.DEAD:
			_popups.remove_at(index)
	var offsets: Array[Vector2] = spawn_offsets()
	for index: int in range(spawn_count(_popups.size())):
		var popup: PopUp = POPUP.instantiate() as PopUp
		popup.position = position + offsets[index]
		popup.timer += 0.18 * index
		get_parent().add_child(popup)
		_popups.append(popup)
	queue_redraw()

func close() -> void:
	_closed = true
	hide()
	queue_free()

func _process(delta: float) -> void:
	_warning_left = maxf(0.0, _warning_left - delta)
	if _warning_left == 0.0:
		set_process(false)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2(0, -14)
	if _opened:
		draw_circle(center, 15.0, Color(PQStyle.MAGENTA, 0.28))
		draw_arc(center, 15.0, 0.0, TAU, 24, PQStyle.MAGENTA, 2.0)
		draw_line(center + Vector2(0, -10), center + Vector2(0, 10), PQStyle.RED, 3.0)
	if _warning_left > 0.0:
		var radius: float = lerpf(4.0, 21.0, 1.0 - _warning_left / _warning_time)
		draw_arc(center, radius, 0.0, TAU, 24, PQStyle.AMBER, 1.5)
