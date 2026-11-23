class_name EnemyBase
extends Area2D

signal died
enum State { IDLE, TELEGRAPH, ACTIVE, RECOVERY, DEAD }
@export var max_health: float = 3.0
@export var telegraph_time: float = 0.4
@export var cycle_time: float = 1.8
@export var bullet_speed: float = 120.0
var state: State = State.IDLE
var timer: float = 0.8
var health: HealthComponent
var player: PacketPlayer
var pool: ProjectilePool
var age: float = 0.0
var flash: float = 0.0
var on_screen: bool = false
var marked: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("homing_target")
	collision_layer = 4
	collision_mask = 0
	add_child(PQStyle.box_shape(Vector2(20, 16)))
	health = HealthComponent.new()
	health.max_health = max_health
	health.depleted.connect(_die)
	add_child(health)
	pool = get_tree().get_first_node_in_group("projectile_pool") as ProjectilePool
	player = get_tree().get_first_node_in_group("player") as PacketPlayer

func _physics_process(delta: float) -> void:
	age += delta
	flash = maxf(0, flash - delta)
	queue_redraw()
	if state == State.DEAD:
		timer -= delta
		if timer <= 0:
			queue_free()
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player") as PacketPlayer
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: Vector2 = camera.get_screen_center_position() if camera != null else Vector2(320, 180)
	on_screen = Rect2(center - Vector2(310, 170), Vector2(620, 340)).has_point(global_position)
	visible = on_screen
	if not on_screen and not _runs_offscreen():
		# Returning enemies must telegraph again before firing.
		if state == State.TELEGRAPH or state == State.ACTIVE:
			state = State.IDLE
			timer = 0.5
		return
	if player != null and player.state != PacketPlayer.State.DEAD and global_position.distance_to(player.global_position) < 17:
		player.take_damage(1.0, global_position)
	advance(delta)

func _runs_offscreen() -> bool:
	return false

func advance(delta: float) -> void:
	timer -= delta
	if timer > 0:
		return
	match state:
		State.IDLE:
			state = State.TELEGRAPH
			timer = telegraph_time
		State.TELEGRAPH:
			state = State.ACTIVE
			fire()
			timer = 0.1
		State.ACTIVE:
			state = State.RECOVERY
			timer = cycle_time - telegraph_time - 0.1
		State.RECOVERY:
			state = State.IDLE
			timer = 0

func fire() -> void:
	if pool != null and player != null and on_screen:
		pool.fire(true, global_position, global_position.direction_to(player.global_position) * bullet_speed)

func take_damage(amount: float, _origin: Vector2) -> void:
	if state == State.DEAD:
		return
	flash = 0.035
	health.damage(amount)

func _die() -> void:
	state = State.DEAD
	timer = 0.3
	collision_layer = 0
	remove_from_group("homing_target")
	Events.impact.emit(0.03, 0.0)
	if player != null and randf() < 0.1:
		var cache: DataCore = DataCore.new()
		cache.cache_fragment = true
		cache.position = position
		get_parent().add_child.call_deferred(cache)
	died.emit()

func draw_bits() -> void:
	for index: int in range(8):
		var offset: Vector2 = Vector2.from_angle(index * TAU / 8.0) * (0.3 - timer) * 100
		draw_rect(Rect2(offset, Vector2(3, 3)), PQStyle.MAGENTA)
