class_name RouterBoss
extends Node2D

signal phase_changed(index: int)
signal defeated

const BossArt = preload("res://scripts/art/boss_art.gd")
enum State { INTRO, IDLE, TELEGRAPH, ACTIVE, RECOVERY, PHASE_TRANSITION, DEFEATED }

const RING_TIME_EPSILON: float = 0.000001

@export var max_health: float = 60.0
@export var phase_threshold: float = 0.5
@export var transition_duration: float = StageBuilder.BOSS_TRANSITION_TIME
@export var ring_telegraph: float = 0.6
@export var stampede_telegraph: float = 0.8
@export var laser_telegraph: float = 1.0
@export var ring_speed: float = 150.0
@export var ring_count: int = 12
@export var ring_interval: float = 3.0
@export var double_ring_delay: float = 0.35
@export var stampede_count: int = 4
@export var stampede_speed: float = 200.0
@export var laser_duration: float = 0.45
@export var recovery_duration: float = 0.2
@export var stampede_duration: float = 0.84
@export var packet_interval: float = 0.21
@export var phases: Array[BossPhaseData] = [preload("res://resources/phases/router_stable.tres"), preload("res://resources/phases/router_overload.tres")]
var health: HealthComponent
var player: PacketPlayer
var pool: ProjectilePool
var body: Hurtbox
var phase: int = 0
var state: State = State.INTRO
var timer: float = 1.2
var attack: StringName = &"A"
var sequence_index: int = 0
var pending_transition: bool = false
var invulnerable: bool = true
var laser_y: float = 296.0
var active_elapsed: float = 0.0
var next_packet: float = 0.0
var packets_sent: int = 0
var second_ring: bool = false
var ring_wait: float = 0.0
var age: float = 0.0
var flash: float = 0.0
var death_elapsed: float = 0.0
var core_spawned: bool = false
var card: Label

func _ready() -> void:
	GameState.current_world = 1
	GameState.in_boss = true
	AudioManager.play_music(&"boss_router")
	StageBuilder.background(self)
	pool = ProjectilePool.new()
	add_child(pool)
	StageBuilder.platform(self, Vector2(0, 304), Vector2(640, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(640, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(80, 256), Vector2(112, 16), 0, true)
	StageBuilder.platform(self, Vector2(448, 256), Vector2(112, 16), 0, true)
	player = StageBuilder.player(self, Vector2(64, 296), 640)
	health = HealthComponent.new()
	health.max_health = max_health
	health.depleted.connect(_defeat)
	add_child(health)
	body = Hurtbox.new()
	body.name = "Boss"
	body.homing_target = true
	body.position = Vector2(320, 176)
	body.collision_layer = 4
	body.collision_mask = 8
	body.add_child(PQStyle.box_shape(Vector2(160, 96)))
	body.hit.connect(take_damage)
	add_child(body)
	StageBuilder.hud(self)
	card = StageBuilder.boss_card(self, "ROUTER FURIOSO", "ROUTER FURIOSO\nSEÑAL ESTABLE")
	GameState.death_cause = "router_boss"
	GameState.boss_progress = 0

func _physics_process(delta: float) -> void:
	age += delta
	flash = maxf(0, flash - delta)
	ring_wait = maxf(0, ring_wait - delta)
	if state != State.DEFEATED and state != State.INTRO and state != State.PHASE_TRANSITION and Rect2(body.position - Vector2(80, 48), Vector2(160, 96)).has_point(player.position):
		player.take_damage(1, body.global_position)
	advance(delta)
	queue_redraw()

func advance(delta: float) -> void:
	if state == State.DEFEATED:
		death_elapsed += delta
		if death_elapsed >= 0.6 and not core_spawned:
			_spawn_core()
		return
	if player != null and player.state == PacketPlayer.State.DEAD:
		return
	timer -= delta
	if state == State.ACTIVE:
		active_elapsed += delta
		_active_attack(delta)
	if timer > 0:
		return
	match state:
		State.INTRO:
			invulnerable = false
			card.visible = false
			state = State.IDLE
			timer = 0.3
		State.IDLE:
			_begin_attack()
		State.TELEGRAPH:
			state = State.ACTIVE
			active_elapsed = 0
			packets_sent = 0
			next_packet = 0
			second_ring = false
			match attack:
				&"A":
					_ring(0)
					ring_wait = ring_interval
					timer = 0.5 if phase == 1 else 0.15
				&"B":
					timer = stampede_duration
				&"C":
					timer = laser_duration
		State.ACTIVE:
			if pending_transition:
				_begin_transition()
			else:
				state = State.RECOVERY
				timer = recovery_duration * phases[phase].recovery_multiplier
		State.RECOVERY:
			state = State.IDLE
			timer = 0.0
		State.PHASE_TRANSITION:
			invulnerable = false
			card.visible = false
			state = State.IDLE
			timer = 0.2

func _begin_attack() -> void:
	var sequence: Array[StringName] = phases[phase].attack_sequence
	attack = sequence[sequence_index % sequence.size()]
	if attack == &"A":
		# El residuo de coma flotante no debe retrasar el aviso un tick entero.
		var until_warning: float = ring_wait - ring_telegraph - RING_TIME_EPSILON
		if until_warning > 0.0:
			timer = until_warning
			return
	sequence_index += 1
	state = State.TELEGRAPH
	match attack:
		&"A": timer = ring_telegraph
		&"B": timer = stampede_telegraph
		&"C":
			timer = laser_telegraph
			laser_y = player.global_position.y
	GameState.death_cause = "router_boss_%s" % attack
	AudioManager.play_warning(StringName("router_" + String(attack)))

func _active_attack(_delta: float) -> void:
	match attack:
		&"A":
			if phase == 1 and not second_ring and active_elapsed >= double_ring_delay:
				second_ring = true
				_ring(deg_to_rad(15))
		&"B":
			while packets_sent < stampede_count and active_elapsed >= next_packet:
				var right: bool = phase == 1 and packets_sent % 2 == 1
				var bullet: Projectile = pool.fire(true, Vector2(628 if right else 12, 300), Vector2(-stampede_speed if right else stampede_speed, 0))
				if bullet != null:
					bullet.rolling = true
					bullet.can_hop = phase == 1 and packets_sent == stampede_count - 1
				packets_sent += 1
				next_packet += packet_interval
		&"C":
			if absf(player.global_position.y - laser_y) < 10:
				player.take_damage(1, Vector2(320, laser_y))

func _ring(offset: float) -> void:
	for index: int in range(ring_count):
		pool.fire(true, Vector2(320, 112), Vector2.from_angle(offset + index * TAU / ring_count) * ring_speed)

func take_damage(amount: float, _origin: Vector2 = Vector2.ZERO) -> void:
	if invulnerable or state == State.DEFEATED:
		return
	health.damage(amount)
	flash = 0.035
	GameState.boss_progress = 1 - health.current / max_health
	Events.impact.emit(0.0, 2.0)
	if state != State.DEFEATED and phase == 0 and health.current / max_health <= phase_threshold:
		pending_transition = true
		if state != State.ACTIVE:
			_begin_transition()

func _begin_transition() -> void:
	phase = 1
	sequence_index = 0
	pending_transition = false
	state = State.PHASE_TRANSITION
	invulnerable = true
	timer = transition_duration
	pool.clear_enemy()
	StageBuilder.show_boss_phase(card, phase + 1, phases[phase].name, PQStyle.RED)
	Events.impact.emit(0.0, 6.0)
	phase_changed.emit(phase)

func _defeat() -> void:
	state = State.DEFEATED
	invulnerable = true
	pool.clear_enemy()
	body.collision_layer = 0
	BossArt.show_restoration(card)
	GameState.boss_progress = 1.0
	GameState.record_boss_clear()
	defeated.emit()
	CelebrationBurst.spawn(self, body.global_position, true)
	Events.boss_defeated.emit(&"router_boss")

func _spawn_core() -> void:
	core_spawned = true
	if "w1_router" in GameState.data.get("collected_cores", []):
		_finish()
		return
	var core: DataCore = DataCore.new()
	core.core_id = &"w1_router"
	core.position = Vector2(320, 296)
	core.collected.connect(_finish)
	add_child(core)
	card.text = "RECOGE EL NÚCLEO DE DATOS"

func _finish() -> void:
	GameState.win()
	get_tree().paused = true
	add_child(preload("res://scenes/ui/VictoryScreen.tscn").instantiate())

func _draw_boss_bar() -> void:
	# Thin bar at the top of the screen, under the HUD line, never over the boss.
	var bar_rect: Rect2 = Rect2(160, 44, 320, 6)
	draw_rect(Rect2(bar_rect.position - Vector2(1, 1), bar_rect.size + Vector2(2, 2)), PQStyle.NIGHT)
	draw_rect(bar_rect, PQStyle.CHIP)
	if health != null and max_health > 0.0:
		var ratio: float = clampf(health.current / max_health, 0.0, 1.0)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), PQStyle.MAGENTA)
	draw_rect(bar_rect, PQStyle.EDGE, false, 1)
	var marker_x: float = bar_rect.position.x + bar_rect.size.x * phase_threshold
	draw_line(Vector2(marker_x, bar_rect.position.y - 2), Vector2(marker_x, bar_rect.position.y + bar_rect.size.y + 2), Color.WHITE, 1)

func _draw() -> void:
	_draw_boss_bar()
	if state == State.DEFEATED:
		BossArt.restored(self, body.position, death_elapsed, PQStyle.GREEN if phase == 0 else PQStyle.RED,
			GameState.reduce_flashes)
		return
	BossArt.router(self, body.position, phase, age, flash, GameState.reduce_flashes)
	if state == State.TELEGRAPH:
		match attack:
			&"A":
				draw_arc(Vector2(320, 112), 14 + sin(age * 18) * 4, 0, TAU, 24, PQStyle.RED, 2)
			&"B":
				for index: int in range(3):
					var x: float = 12 + index * 20
					draw_polyline(PackedVector2Array([Vector2(x, 286), Vector2(x + 8, 294), Vector2(x, 302)]), PQStyle.RED, 3)
					if phase == 1:
						draw_polyline(PackedVector2Array([Vector2(640 - x, 286), Vector2(632 - x, 294), Vector2(640 - x, 302)]), PQStyle.RED, 3)
			&"C":
				for x: int in range(0, 640, 16):
					draw_line(Vector2(x, laser_y), Vector2(x + 8, laser_y), PQStyle.RED, 1)
	if state == State.ACTIVE and attack == &"C":
		draw_line(Vector2(0, laser_y), Vector2(640, laser_y), PQStyle.RED, 6)
		draw_line(Vector2(0, laser_y), Vector2(640, laser_y), Color.WHITE, 2)
