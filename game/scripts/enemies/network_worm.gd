class_name NetworkWorm
extends EnemyBase

@export var move_speed: float = 60.0
@export var path_width: float = 112.0
var cable: Path2D
var follower: PathFollow2D
var anchor: Vector2
var pending_attack: bool = false

func _ready() -> void:
	max_health = 5
	telegraph_time = 0.3
	super._ready()
	anchor = position
	cable = Path2D.new()
	cable.curve = Curve2D.new()
	cable.curve.add_point(Vector2(-path_width / 2, 0))
	cable.curve.add_point(Vector2(0, -8))
	cable.curve.add_point(Vector2(path_width / 2, 0))
	follower = PathFollow2D.new()
	follower.rotates = false
	follower.loop = false
	cable.add_child(follower)
	add_child(cable)

func advance(delta: float) -> void:
	var length: float = cable.curve.get_baked_length()
	follower.progress = pingpong(age * move_speed, length)
	position = anchor + follower.position
	cable.position = anchor - position
	if state == State.IDLE:
		if pending_attack:
			pending_attack = false
			state = State.TELEGRAPH
			timer = telegraph_time
		return
	timer -= delta
	if timer > 0:
		return
	match state:
		State.TELEGRAPH:
			state = State.ACTIVE
			fire()
			timer = 0.12
		State.ACTIVE:
			state = State.RECOVERY
			timer = 0.65
		State.RECOVERY:
			state = State.IDLE

func take_damage(amount: float, origin: Vector2) -> void:
	super.take_damage(amount, origin)
	if state != State.DEAD:
		pending_attack = true

func fire() -> void:
	if pool != null and on_screen:
		pool.fire(true, global_position, Vector2(-85, -150), 1, Vector2(0, 300))
		pool.fire(true, global_position, Vector2(85, -150), 1, Vector2(0, 300))

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	var radius: float = 4.0 + (2.0 if state == State.TELEGRAPH else 0.0)
	for index: int in range(4):
		var pos: Vector2 = Vector2(index * 6 - 9, sin(age * 8 + index) * 2)
		draw_circle(pos, radius, Color.WHITE if flash > 0 else Color("9dff4f"))
	draw_circle(Vector2(10, -1), 1, PQStyle.NIGHT)
	if state == State.TELEGRAPH:
		draw_line(Vector2(-8, -12), Vector2(-13, -18), PQStyle.RED, 2)
		draw_line(Vector2(8, -12), Vector2(13, -18), PQStyle.RED, 2)
