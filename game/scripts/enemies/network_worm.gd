class_name NetworkWorm
extends EnemyBase

@export var move_speed: float = 60.0
@export var path_width: float = 112.0
var cable: Path2D
var follower: PathFollow2D
var anchor: Vector2
var pending_attack: bool = false

func _init() -> void:
	max_health = 5

func _ready() -> void:
	telegraph_time = 0.3
	super._ready()
	_warning_sfx = &"enemy_worm"
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
			_play_attack_warning()
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
	var length: float = cable.curve.get_baked_length() if cable != null else 0.0
	var forward: bool = length <= 0.0 or fposmod(age * move_speed, length * 2.0) < length
	var direction: float = 1.0 if forward == (move_speed >= 0.0) else -1.0
	EnemyArt.worm(self, visual_pose(), visual_frame(), art_tint(), direction)
	if state == State.TELEGRAPH:
		draw_warning(11.0)
