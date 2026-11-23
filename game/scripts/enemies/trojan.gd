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
	EnemyArt.trojan(self, visual_pose(), visual_frame(), art_tint())
	if state == State.TELEGRAPH:
		draw_warning(11.0)
