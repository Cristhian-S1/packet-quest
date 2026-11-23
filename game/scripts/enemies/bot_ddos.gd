class_name BotDDoS
extends EnemyBase

const SHOT_COUNT: int = 6
const FAN_SPREAD: float = 120.0
const BOB_HEIGHT: float = 24.0
const PATROL_WIDTH: float = 48.0

@export_range(1.0, 150.0, 1.0) var flight_speed: float = 36.0

var _spawn: Vector2

static func fan_directions(center: Vector2, count: int, spread_deg: float) -> Array[Vector2]:
	if count <= 0:
		return []
	var aim: Vector2 = Vector2.RIGHT if center.is_zero_approx() else center.normalized()
	return Projectile.spread_directions(aim, count, spread_deg / 2.0)

func _ready() -> void:
	super._ready()
	_spawn = position

func _physics_process(delta: float) -> void:
	if state != State.DEAD:
		var x: float = pingpong(PATROL_WIDTH + (age + delta) * flight_speed, PATROL_WIDTH * 2.0) - PATROL_WIDTH
		position = _spawn + Vector2(x, sin(age + delta) * BOB_HEIGHT)
	super._physics_process(delta)

func advance(delta: float) -> void:
	timer -= delta
	if state == State.ACTIVE:
		state = State.RECOVERY
	if timer > 0.00001:
		return
	if state == State.TELEGRAPH:
		state = State.ACTIVE
		fire()
		timer += cycle_time - telegraph_time
	else:
		state = State.TELEGRAPH
		timer += telegraph_time
		AudioManager.play_sfx(&"telegraph")

func fire() -> void:
	if not on_screen or not is_instance_valid(player) or pool == null:
		return
	var aim: Vector2 = player.global_position - global_position
	for direction: Vector2 in fan_directions(aim, SHOT_COUNT, FAN_SPREAD):
		pool.fire(true, global_position, direction * bullet_speed)

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	EnemyArt.bot(self, visual_pose(), visual_frame(), art_tint())
	if state == State.TELEGRAPH:
		draw_warning(14.0)
		if is_instance_valid(player):
			var aim: Vector2 = player.global_position - global_position
			for ray: Vector2 in fan_directions(aim, 3, FAN_SPREAD):
				draw_line((ray * 18).round(), (ray * 25).round(), PQStyle.RED, 2.0)
