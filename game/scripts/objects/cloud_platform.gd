class_name CloudPlatform
extends StaticBody2D

const SIZE: Vector2 = CoveragePlatform.SIZE
const PERIOD: float = 4.0
const FADE_START: float = 2.0
const GONE_START: float = 2.5

@export var phase_offset: float = 0.0

var _age: float = 0.0
var _state: StringName = &"solid"
var _shape: CollisionShape2D

static func state_at(t: float) -> StringName:
	var elapsed: float = fposmod(t, PERIOD)
	if elapsed < FADE_START:
		return &"solid"
	return &"fading" if elapsed < GONE_START else &"gone"

func _ready() -> void:
	GameState.settings_changed.connect(_settings_changed)
	collision_layer = 1
	collision_mask = 0
	_age = phase_offset
	_state = state_at(_age)
	_shape = PQStyle.box_shape(SIZE)
	_shape.one_way_collision = true
	_shape.disabled = _state == &"gone"
	add_child(_shape)

func _physics_process(delta: float) -> void:
	_age += delta
	var next_state: StringName = state_at(_age)
	if next_state != _state:
		_state = next_state
		_shape.set_deferred(&"disabled", _state == &"gone")
		queue_redraw()
	elif _state == &"fading" and not GameState.reduce_flashes:
		queue_redraw()

func _settings_changed(key: String) -> void:
	if key.is_empty() or key == "reduce_flashes":
		queue_redraw()

func _draw() -> void:
	var tint: Color = PQStyle.CYAN
	if _state == &"fading" and (GameState.reduce_flashes or int(_age * 16.0) % 2 == 0):
		tint = Color.WHITE
	elif _state == &"gone":
		tint.a = 0.25
	draw_rect(Rect2(-SIZE / 2.0, SIZE), Color(PQStyle.CHIP, tint.a))
	draw_line(Vector2(-32, -6), Vector2(32, -6), tint, 2)
	for x: int in range(-26, 28, 12):
		draw_rect(Rect2(x, -2, 7, 4), tint)
