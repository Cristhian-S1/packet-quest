extends EnemyBase

enum SpyState { DISGUISED, TELEGRAPH, JUMP, RECOVER }
const REVEAL_DISTANCE: float = 64.0
const CHASE_DISTANCE: float = 160.0
const RECOVER_TIME: float = 0.8
const JUMP_SPEED: Vector2 = Vector2(180, -260)
const GRAVITY: float = 900.0

var spy_state: SpyState = SpyState.DISGUISED
var jump_velocity: Vector2:
	get:
		return _body.velocity
var _body: CharacterBody2D

func _ready() -> void:
	super._ready()
	remove_from_group(&"homing_target")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	_body = CharacterBody2D.new()
	_body.collision_layer = 0
	_body.collision_mask = 1
	_body.add_child(PQStyle.box_shape(Vector2(20, 16)))
	add_child(_body)

func _physics_process(delta: float) -> void:
	age += delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()
	if state == State.DEAD:
		timer -= delta
		if timer <= 0.0:
			queue_free()
		return
	if not is_instance_valid(player):
		return
	var distance: float = global_position.distance_to(player.global_position)
	match spy_state:
		SpyState.DISGUISED:
			if distance < REVEAL_DISTANCE:
				collision_layer = 4
				add_to_group(&"homing_target")
				_warn()
		SpyState.TELEGRAPH:
			timer -= delta
			if timer <= 0.00001:
				var direction: float = 1.0 if player.global_position.x >= global_position.x else -1.0
				_body.velocity = Vector2(JUMP_SPEED.x * direction, JUMP_SPEED.y)
				spy_state = SpyState.JUMP
		SpyState.JUMP:
			_jump(delta)
		SpyState.RECOVER:
			timer = maxf(0.0, timer - delta)
			if timer <= 0.0 and distance < CHASE_DISTANCE:
				_warn()

func _warn() -> void:
	spy_state = SpyState.TELEGRAPH
	timer = telegraph_time

func _jump(delta: float) -> void:
	_body.velocity.y += GRAVITY * delta
	_body.move_and_slide()
	# El cuerpo resuelve el terreno y el área raíz acompaña su movimiento.
	position += _body.position
	_body.position = Vector2.ZERO
	if global_position.distance_squared_to(player.global_position) < 17.0 * 17.0:
		player.take_damage(1.0, global_position)
	if _body.is_on_floor():
		_body.velocity = Vector2.ZERO
		spy_state = SpyState.RECOVER
		timer = RECOVER_TIME
	elif global_position.y > 388.0:
		queue_free()

func take_damage(amount: float, origin: Vector2) -> void:
	if spy_state != SpyState.DISGUISED:
		super.take_damage(amount, origin)

func _die() -> void:
	remove_from_group(&"homing_target")
	super._die()

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	if spy_state == SpyState.DISGUISED:
		DataCore.draw_core(self, age, PQStyle.AMBER)
		return
	var color: Color = Color.WHITE if flash > 0.0 and not GameState.reduce_flashes else PQStyle.MAGENTA
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 6), Vector2(-7, -7), Vector2(0, -4),
		Vector2(8, -10), Vector2(11, 6), Vector2(0, 9)]), color)
	draw_rect(Rect2(-6, -1, 12, 4), PQStyle.NIGHT)
	draw_rect(Rect2(-3, 0, 2, 2), PQStyle.PINK)
	draw_rect(Rect2(2, 0, 2, 2), PQStyle.PINK)
	if spy_state == SpyState.TELEGRAPH:
		var shift: float = 2.0 if GameState.reduce_flashes else sin(age * 50) * 5
		draw_line(Vector2(-15 + shift, -12), Vector2(7 + shift, -12), PQStyle.PINK, 2)
		draw_line(Vector2(0 - shift, 11), Vector2(14 - shift, 11), color, 2)
