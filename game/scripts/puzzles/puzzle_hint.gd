class_name PuzzleHint
extends Panel

const DELAY: float = 60.0
const INTERVAL: float = 10.0
const PULSE: float = 1.0

var _elapsed: float = 0.0

func _ready() -> void:
	name = "PuzzleHint"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1
	var outline: StyleBoxFlat = PQStyle.panel(Color.TRANSPARENT, PQStyle.AMBER)
	outline.set_border_width_all(2)
	add_theme_stylebox_override("panel", outline)
	hide()

func point_at(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

func reset() -> void:
	_elapsed = 0.0
	hide()

func advance(delta: float, player: Node2D, exit_x: float, solved: bool) -> void:
	if solved or not is_instance_valid(player):
		hide()
		return
	var room: Node2D = get_parent() as Node2D
	var x: float = room.to_local(player.global_position).x
	if x < 0.0 or x >= exit_x:
		hide()
		return
	_elapsed += delta
	if _elapsed < DELAY:
		return
	var age: float = fposmod(_elapsed - DELAY, INTERVAL)
	var steady: bool = GameState.reduce_flashes
	visible = steady or age < PULSE
	if visible:
		modulate.a = 1.0 if steady else sin(PI * age / PULSE)
