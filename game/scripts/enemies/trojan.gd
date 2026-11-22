class_name Trojan
extends EnemyBase

const PORTAL_SCENE: PackedScene = preload("res://scenes/enemies/TrojanPortal.tscn")

@export_range(0.0, 128.0) var patrol_half_width: float = 64.0
@export var patrol_speed: float = 40.0

var portal: TrojanPortal
var _patrol_center: float
var _patrol_travel: float = 0.0

func _init() -> void:
	max_health = 8.0
	telegraph_time = 1.0
	cycle_time = 5.0

func _ready() -> void:
	super._ready()
	_patrol_center = position.x

func _runs_offscreen() -> bool:
	return true

func advance(delta: float) -> void:
	if (state == State.IDLE or state == State.RECOVERY) and patrol_half_width > 0.0:
		_patrol_travel += patrol_speed * delta
		position.x = _patrol_center + pingpong(_patrol_travel + patrol_half_width, 2.0 * patrol_half_width) - patrol_half_width
	var previous: State = state
	super.advance(delta)
	if state == State.TELEGRAPH and previous != State.TELEGRAPH:
		_ensure_portal()
		portal.warn(telegraph_time)

func fire() -> void:
	_ensure_portal()
	portal.activate()

func _ensure_portal() -> void:
	if is_instance_valid(portal):
		return
	portal = PORTAL_SCENE.instantiate() as TrojanPortal
	portal.position = position
	get_parent().add_child(portal)

func _die() -> void:
	if is_instance_valid(portal):
		portal.close()
	super._die()

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	var tint: Color = Color.WHITE if flash > 0.0 else PQStyle.MAGENTA
	draw_rect(Rect2(-11, -12, 22, 18), PQStyle.NIGHT)
	draw_rect(Rect2(-11, -12, 22, 18), tint, false, 2.0)
	draw_rect(Rect2(-7, -9, 14, 5), PQStyle.CHIP)
	draw_rect(Rect2(-5, -6, 10, 4), PQStyle.RED if state == State.TELEGRAPH else tint)
	draw_rect(Rect2(-10, 6, 6, 2), tint)
	draw_rect(Rect2(4, 6, 6, 2), tint)
	draw_line(Vector2(-4, 2), Vector2(4, 2), PQStyle.AMBER, 1.0)

