class_name PacketPlayer
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal died
enum State { IDLE, RUN, JUMP, FALL, DASH, SHIELD, HURT, DEAD }

@export var speed: float = 150.0
@export var acceleration: float = 1200.0
@export var friction: float = 1600.0
@export var gravity: float = 900.0
@export var fall_multiplier: float = 1.6
@export var jump_speed: float = -330.0
@export var jump_cut: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.10
@export var max_fall: float = 420.0
@export var dash_distance: float = 72.0
@export var dash_duration: float = 0.18
@export var dash_iframes: float = 0.15
@export var dash_cooldown: float = 0.6
@export var max_hp: float = 3.0
@export var hurt_invulnerability: float = 1.0
@export var knockback: float = 120.0
@export var hurt_duration: float = 0.2
@export var shield_max: float = 100.0
@export var shield_drain: float = 40.0
@export var shield_block_cost: float = 15.0
@export var shield_recharge: float = 12.0
@export var shield_delay: float = 1.0
@export var shield_break_duration: float = 2.0
@export var interact_range: float = 24.0
@export var camera_width: int = 2720
@export var weapon: WeaponData = preload("res://resources/weapons/packet.tres")

var state: State = State.IDLE
var health: HealthComponent
var camera: Camera2D
var hurtbox: Hurtbox
var shield_area: Area2D
var muzzle: Marker2D
var shield_meter: float = 100.0
var shield_active: bool = false
var shield_wait: float = 0.0
var shield_broken: float = 0.0
var cooldown: float = 0.0
var dash_left: float = 0.0
var dash_vector: Vector2 = Vector2.RIGHT
var air_dash_used: bool = false
var invulnerability: float = 0.0
var hurt_left: float = 0.0
var coyote: float = 0.0
var buffered_jump: float = 0.0
var shoot_wait: float = 0.0
var facing: float = 1.0
var aim: Vector2 = Vector2.RIGHT
var safe_position: Vector2 = Vector2.ZERO
var pool: ProjectilePool
var animation_time: float = 0.0
var trails: Array[Vector2] = []
var shake_left: float = 0.0
var shake_power: float = 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	add_child(PQStyle.box_shape(Vector2(10, 14)))
	health = HealthComponent.new()
	health.max_health = max_hp + (1.0 if bool(GameState.data.get("settings", {}).get("assist_mode", false)) else 0.0)
	health.changed.connect(func(cur: float, maximum: float) -> void: health_changed.emit(cur, maximum))
	health.depleted.connect(_die)
	add_child(health)
	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	hurtbox.add_child(PQStyle.box_shape(Vector2(10, 14)))
	hurtbox.hit.connect(take_damage)
	add_child(hurtbox)
	muzzle = Marker2D.new()
	muzzle.name = "Muzzle"
	add_child(muzzle)
	shield_area = Area2D.new()
	shield_area.name = "ShieldArea"
	shield_area.collision_layer = 128
	shield_area.collision_mask = 16
	shield_area.add_child(PQStyle.box_shape(Vector2(5, 24)))
	add_child(shield_area)
	var interact_area: Area2D = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 0
	interact_area.collision_mask = 32
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = interact_range
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = circle
	interact_area.add_child(shape)
	add_child(interact_area)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_right = camera_width
	camera.limit_top = 0
	camera.limit_bottom = 360
	camera.position = Vector2(70, -70)
	add_child(camera)
	safe_position = global_position
	shield_meter = shield_max
	pool = get_tree().get_first_node_in_group("projectile_pool") as ProjectilePool
	Events.impact.connect(_impact)

func _physics_process(delta: float) -> void:
	animation_time += delta
	queue_redraw()
	if state == State.DEAD:
		return
	cooldown = maxf(0, cooldown - delta)
	invulnerability = maxf(0, invulnerability - delta)
	shoot_wait -= delta
	if not Input.is_action_pressed("shoot") or shield_active or hurt_left > 0:
		shoot_wait = maxf(0, shoot_wait)
	buffered_jump = maxf(0, buffered_jump - delta)
	shield_broken = maxf(0, shield_broken - delta)
	shield_wait = maxf(0, shield_wait - delta)
	hurt_left = maxf(0, hurt_left - delta)
	var horizontal: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("aim_up", "aim_down")
	var locked: bool = Input.is_action_pressed("lock_aim")
	_update_aim(horizontal, vertical, locked)
	if is_on_floor():
		coyote = coyote_time
		air_dash_used = false
		if hurt_left <= 0.0:
			safe_position = global_position
	else:
		coyote = maxf(0, coyote - delta)
	if Input.is_action_just_pressed("jump"):
		buffered_jump = jump_buffer
	if Input.is_action_just_pressed("dash") and cooldown <= 0 and not air_dash_used and hurt_left <= 0:
		dash_vector = Vector2(horizontal, vertical).normalized()
		if dash_vector == Vector2.ZERO:
			dash_vector = Vector2(facing, 0)
		dash_left = dash_duration
		cooldown = dash_cooldown
		if not is_on_floor():
			air_dash_used = true
		invulnerability = maxf(invulnerability, dash_iframes)
		state = State.DASH
		trails.clear()
	shield_active = Input.is_action_pressed("shield") and shield_broken <= 0 and shield_meter > 0 and dash_left <= 0 and hurt_left <= 0
	_update_shield(delta)
	if dash_left > 0:
		# Partial final physics tick keeps displacement exactly 72 px at 60 Hz.
		velocity = dash_vector * dash_distance / dash_duration * minf(1.0, dash_left / delta)
		dash_left = maxf(0, dash_left - delta)
		trails.push_front(global_position)
		if trails.size() > 3:
			trails.pop_back()
	elif hurt_left > 0:
		state = State.HURT
		velocity.y = minf(max_fall, velocity.y + gravity * delta)
	else:
		trails.clear()
		var target_speed: float = 0.0 if locked else horizontal * speed * (0.5 if shield_active else 1.0)
		velocity.x = move_toward(velocity.x, target_speed, (acceleration if target_speed != 0 else friction) * delta)
		if not is_on_floor():
			velocity.y = minf(max_fall, velocity.y + gravity * (fall_multiplier if velocity.y > 0 else 1.0) * delta)
		if buffered_jump > 0 and coyote > 0:
			velocity.y = jump_speed
			buffered_jump = 0
			coyote = 0
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= jump_cut
		state = State.SHIELD if shield_active else (State.RUN if absf(velocity.x) > 1 else State.IDLE)
		if not is_on_floor():
			state = State.JUMP if velocity.y < 0 else State.FALL
	move_and_slide()
	if global_position.y > 388:
		pit_respawn()
	if Input.is_action_pressed("shoot") and not shield_active and shoot_wait <= 0 and state != State.DEAD and hurt_left <= 0:
		shoot()
	if Input.is_action_just_pressed("interact"):
		interact()
	# Packet is the only equipped weapon in the M0–M6 slice.
	if Input.is_action_just_pressed("swap_weapon"):
		AudioManager.play_sfx(&"weapon_packet")
	if shake_left > 0:
		shake_left -= delta
		camera.offset = Vector2(sin(animation_time * 120), cos(animation_time * 99)) * shake_power
	else:
		camera.offset = Vector2.ZERO

func _update_aim(horizontal: float, vertical: float, locked: bool) -> void:
	if absf(horizontal) > 0.2:
		facing = signf(horizontal)
	var direction: Vector2 = Vector2(signf(horizontal), signf(vertical))
	if not locked:
		if vertical < -0.2:
			direction = Vector2(signf(horizontal), -1)
		else:
			direction = Vector2(facing, 0)
	if direction != Vector2.ZERO:
		aim = direction.normalized()
	muzzle.position = aim * 13
	shield_area.position = Vector2(facing * 12, 0)

func _update_shield(delta: float) -> void:
	if shield_active:
		shield_meter = maxf(0, shield_meter - shield_drain * delta)
		shield_wait = shield_delay
	elif shield_wait <= 0 and shield_broken <= 0:
		shield_meter = minf(shield_max, shield_meter + shield_recharge * delta)
	if shield_meter <= 0 and shield_active:
		_break_shield()
	shield_area.visible = shield_active
	shield_changed.emit(shield_meter, shield_max)

func _break_shield() -> void:
	shield_active = false
	shield_broken = shield_break_duration
	shield_wait = shield_delay

func receive_projectile(amount: float, origin: Vector2, incoming: Vector2) -> void:
	var toward: Vector2 = global_position - origin
	if shield_active and (origin.x - global_position.x) * facing > 0 and toward.dot(incoming) > 0:
		shield_meter = maxf(0, shield_meter - shield_block_cost)
		if shield_meter <= 0:
			_break_shield()
		shield_changed.emit(shield_meter, shield_max)
		return
	take_damage(amount, origin)

func take_damage(amount: float, origin: Vector2) -> void:
	if invulnerability > 0 or state == State.DEAD:
		return
	invulnerability = hurt_invulnerability
	hurt_left = hurt_duration
	dash_left = 0
	shield_active = false
	velocity = Vector2((-1.0 if origin.x >= global_position.x else 1.0) * knockback, -90)
	state = State.HURT
	Events.impact.emit(0.05, 2.0)
	health.damage(amount)

func pit_respawn() -> void:
	# A pit always costs one HP, including during damage i-frames.
	health.damage(1)
	if state == State.DEAD:
		return
	global_position = safe_position
	velocity = Vector2.ZERO
	dash_left = 0
	invulnerability = hurt_invulnerability
	camera.reset_smoothing()

func shoot() -> void:
	if pool == null:
		return
	pool.fire(false, muzzle.global_position, aim * weapon.bullet_speed, weapon.damage)
	shoot_wait += 1.0 / weapon.fire_rate
	AudioManager.play_sfx(&"packet")

func interact() -> void:
	var nearest: Node2D = null
	var distance: float = interact_range + 0.01
	for candidate: Node in get_tree().get_nodes_in_group("interactable"):
		var node: Node2D = candidate as Node2D
		var current_distance: float = global_position.distance_to(node.global_position)
		if current_distance < distance:
			nearest = node
			distance = current_distance
	if nearest != null and nearest.has_method("interact"):
		nearest.call("interact")

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	GameState.record_death()
	died.emit()
	Events.player_died.emit()

func _impact(_duration: float, power: float) -> void:
	if bool(GameState.data.get("settings", {}).get("screen_shake", true)):
		shake_left = 0.15
		shake_power = power

func _draw() -> void:
	for index: int in range(trails.size()):
		draw_rect(Rect2(to_local(trails[index]) - Vector2(8, 8), Vector2(16, 16)), Color(PQStyle.CYAN, 0.12 * (3 - index)))
	if invulnerability > 0 and not bool(GameState.data.get("settings", {}).get("reduce_flashes", false)) and int(animation_time * 14) % 2 == 0:
		return
	draw_rect(Rect2(-9, -9, 18, 18), Color("0b1a2e"))
	draw_rect(Rect2(-8, -8, 16, 16), PQStyle.CYAN)
	draw_rect(Rect2(-6, -6, 12, 3), Color.WHITE)
	draw_rect(Rect2(facing * 2 - 3, -1, 2, 3), PQStyle.NIGHT)
	draw_rect(Rect2(facing * 2 + 2, -1, 2, 3), PQStyle.NIGHT)
	var step: float = sin(animation_time * 20) * 2 if state == State.RUN else 0.0
	draw_line(Vector2(-4, 7), Vector2(-5 + step, 11), PQStyle.CYAN, 2)
	draw_line(Vector2(4, 7), Vector2(5 - step, 11), PQStyle.CYAN, 2)
	draw_line(Vector2.ZERO, aim * 13, PQStyle.CHIP, 5)
	draw_circle(aim * 9 + Vector2(0, 2), 3, Color.WHITE)
	draw_line(aim * 11, aim * 15, PQStyle.CYAN, 4)
	if shield_active:
		draw_arc(Vector2.ZERO, 16, -1.2 if facing > 0 else PI - 1.2, 1.2 if facing > 0 else PI + 1.2, 10, PQStyle.GREEN, 3)
