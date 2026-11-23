class_name WifiQueenBoss
extends Node2D

signal phase_changed(index: int)
signal defeated

const BossArt = preload("res://scripts/art/boss_art.gd")
const ArtMotion = preload("res://scripts/art/art_motion.gd")

enum State { INTRO, WAIT, TELEGRAPH, ACTIVE, RECOVERY, PHASE_TRANSITION, DEFEATED }
enum Attack { WAVES, PING, SPIRAL, TELEPORT }

const MAX_HEALTH: float = 90.0
const PHASE_TWO: float = 0.7
const PHASE_THREE: float = 0.4
const PHASE_NAMES: Array[String] = ["Señal estable", "Itinerancia", "Interferencia"]
const PHASE_COLORS: Array[Color] = [PQStyle.CYAN, PQStyle.MAGENTA, PQStyle.AMBER]
const ANTENNAS: Array[Vector2] = [Vector2(160, 112), Vector2(320, 88), Vector2(480, 112)]
# Byte de pie ocupa y 290–304: el carril bajo obliga a saltar, el medio solo alcanza en el aire
# y el alto queda sobre el pico del salto (~60 px). Ver wave_lanes().
const WAVE_LANES: Array[float] = [296.0, 256.0, 216.0]
const SIGNAL_PATTERN: Array[Attack] = [Attack.WAVES, Attack.PING]
const ROAMING_PATTERN: Array[Attack] = [Attack.SPIRAL, Attack.TELEPORT, Attack.WAVES, Attack.TELEPORT,
	Attack.SPIRAL, Attack.TELEPORT, Attack.PING, Attack.TELEPORT]
const ATTACK_SFX: Array[StringName] = [&"wifi_waves", &"wifi_ping", &"wifi_spiral", &"wifi_teleport"]
const WARNINGS: Array[float] = [0.6, 0.8, 0.5, 0.4]
const SPIRAL_TIME: float = 1.2
const SPIRAL_COUNT: int = 16
const INTERFERENCE_CYCLE: float = 4.0
const INTERFERENCE_WARNING: float = 1.0
const INTERFERENCE_END: float = 2.5

var player: PacketPlayer
var pool: ProjectilePool
var health: HealthComponent
var body: Hurtbox
var card: Label
var repeaters: Array[WifiRepeater] = []
var phase: int = 1
var state: State = State.INTRO
var timer: float = 1.2
var attack: Attack = Attack.WAVES

var _sequence_index: int = 0
var _wave_index: int = 0
var _ping_x: float = 320.0
var _spiral_sent: int = 0
var _antenna: int = 1
var _destination: int = 1
var _interference_age: float = 0.0
var _interference_index: int = 0
var _lanes: Array[int] = []
var _interference_hit: bool = false
var _age: float = 0.0
var _flash: float = 0.0

static func phase_for(hp_ratio: float) -> int:
	if hp_ratio <= PHASE_THREE:
		return 3
	return 2 if hp_ratio <= PHASE_TWO else 1

# Alterna "salta" (bajo + alto) y "quédate en el suelo" (medio + alto) cada dos oleadas, para que
# no coincida siempre con el lado de salida. Nunca bajo y medio a la vez: no habría hueco seguro.
static func wave_lanes(index: int) -> Array[int]:
	var lanes: Array[int] = [0, 2]
	if (index >> 1) & 1 == 1:
		lanes = [1, 2]
	return lanes

static func interference_lanes(seed_index: int) -> Array[int]:
	match posmod(seed_index, 3):
		0: return [0, 2]
		1: return [1, 3]
		_: return [0, 3]

func _ready() -> void:
	AudioManager.play_music(&"boss")
	GameState.current_world = 2
	GameState.in_boss = true
	GameState.death_cause = "reina_wifi"
	GameState.boss_progress = 0.0
	add_child(WifiBackdrop.new())
	pool = ProjectilePool.new()
	add_child(pool)
	StageBuilder.platform(self, Vector2(0, 304), Vector2(640, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(640, 0), Vector2(16, 360))
	for x: float in [200.0, 360.0]:
		StageBuilder.platform(self, Vector2(x, 254), Vector2(80, 10), 0.0, true)
	player = StageBuilder.player(self, GameState.checkpoint if GameState.playing else Vector2(64, 296), 640)
	for x: float in [120.0, 520.0]:
		var repeater: WifiRepeater = WifiRepeater.new()
		repeater.position = Vector2(x, 288)
		add_child(repeater)
		repeaters.append(repeater)
	health = HealthComponent.new()
	health.max_health = MAX_HEALTH
	health.depleted.connect(_defeat)
	add_child(health)
	body = Hurtbox.new()
	body.name = "Reina"
	body.position = ANTENNAS[_antenna]
	body.collision_layer = 4
	body.collision_mask = 0
	body.monitoring = false
	body.homing_target = true
	body.invulnerable = true
	body.add_child(PQStyle.box_shape(Vector2(84, 38)))
	body.hit.connect(take_damage)
	add_child(body)
	StageBuilder.hud(self)
	card = StageBuilder.boss_card(self, "REINA WI-FI", "REINA WI-FI\nSEÑAL ESTABLE", Vector2(88, 70))
	card.position.y = 148.0

func _physics_process(delta: float) -> void:
	_age += delta
	_flash = maxf(0.0, _flash - delta)
	if state != State.DEFEATED:
		body.position = ANTENNAS[_antenna] + Vector2(0, sin(_age * 3.0) * 4.0)
	if phase == 3 and state != State.PHASE_TRANSITION and state != State.DEFEATED:
		_tick_interference(delta)
	_advance(delta)
	queue_redraw()

func _advance(delta: float) -> void:
	if state == State.WAIT:
		if phase < 3:
			_begin_next()
		return
	timer -= delta
	if state == State.ACTIVE and attack == Attack.SPIRAL:
		_fire_spiral()
	if timer > 0.00001:
		return
	match state:
		State.INTRO, State.PHASE_TRANSITION:
			body.invulnerable = false
			card.hide()
			state = State.WAIT
			if phase == 3:
				AudioManager.play_warning(&"wifi_interference")
		State.TELEGRAPH:
			_fire_attack()
		State.ACTIVE:
			if phase == 2 and attack != Attack.TELEPORT:
				_begin_next()
			else:
				state = State.RECOVERY
				timer = 1.0 if phase == 1 else 0.8
		State.RECOVERY:
			state = State.WAIT
		State.DEFEATED:
			set_physics_process(false)
			GameState.open_map()

func _begin_next() -> void:
	var pattern: Array[Attack] = SIGNAL_PATTERN if phase == 1 else ROAMING_PATTERN
	_begin_attack(pattern[_sequence_index % pattern.size()])
	_sequence_index += 1

func _begin_attack(next: Attack) -> void:
	attack = next
	state = State.TELEGRAPH
	timer = WARNINGS[attack]
	AudioManager.play_warning(ATTACK_SFX[attack])
	match attack:
		Attack.WAVES:
			pass
		Attack.PING:
			_ping_x = clampf(player.global_position.x, 68.0, 572.0)
		Attack.TELEPORT:
			_destination = (_antenna + 1) % ANTENNAS.size()

func _fire_attack() -> void:
	state = State.ACTIVE
	# Para las descargas instantáneas, el estado activo ocupa un tick.
	timer = 0.0
	match attack:
		Attack.WAVES:
			_fire_waves()
		Attack.PING:
			for index: int in range(-2, 3):
				pool.fire(true, Vector2(_ping_x + index * 32, 46), Vector2(0, 180))
		Attack.SPIRAL:
			_spiral_sent = 0
			timer = SPIRAL_TIME
			_fire_spiral()
		Attack.TELEPORT:
			_antenna = _destination
			body.position = ANTENNAS[_antenna]
			body.reset_physics_interpolation()

func _fire_waves() -> void:
	for index: int in range(2):
		var y: float = WAVE_LANES[wave_lanes(_wave_index)[index]]
		if phase == 2 or _wave_index % 2 == 0:
			_wave_row(y, 1.0)
		if phase == 2 or _wave_index % 2 == 1:
			_wave_row(y, -1.0)
	_wave_index += 1

func _wave_row(y: float, direction: float) -> void:
	for index: int in range(5):
		var inset: float = 5.0 + index * 14.0
		var x: float = inset if direction > 0.0 else 640.0 - inset
		var bullet: Projectile = pool.fire(true, Vector2(x, y), Vector2(direction * 160.0, 0))
		if bullet != null:
			bullet.horizontal_bounces = 1

func _fire_spiral() -> void:
	var elapsed: float = SPIRAL_TIME - timer
	while _spiral_sent < SPIRAL_COUNT and elapsed + 0.00001 >= _spiral_sent * SPIRAL_TIME / SPIRAL_COUNT:
		var direction: Vector2 = Vector2.from_angle(_spiral_sent * PI / 6)
		pool.fire(true, body.global_position, direction * 130.0)
		_spiral_sent += 1

func _tick_interference(delta: float) -> void:
	var previous: float = _interference_age
	_interference_age += delta
	if _interference_age >= INTERFERENCE_CYCLE:
		_interference_age -= INTERFERENCE_CYCLE
		_interference_index += 1
		_lanes = interference_lanes(_interference_index)
		_interference_hit = false
		AudioManager.play_warning(&"wifi_interference")
	if previous < INTERFERENCE_END and _interference_age >= INTERFERENCE_END and state == State.WAIT:
		_begin_attack(Attack.PING if _interference_index % 2 == 0 else Attack.SPIRAL)
	if _interference_age < INTERFERENCE_WARNING or _interference_age >= INTERFERENCE_END or _interference_hit:
		return
	var lane: int = clampi(floori(player.global_position.x / 160.0), 0, 3)
	if lane not in _lanes or player.invulnerability > 0.0:
		return
	for repeater: WifiRepeater in repeaters:
		if repeater.protects(player.global_position):
			return
	_interference_hit = true
	player.take_damage(1.0, Vector2(lane * 160 + 80, player.global_position.y))

func take_damage(amount: float, _origin: Vector2) -> void:
	if body.invulnerable:
		return
	health.damage(amount)
	GameState.boss_progress = 1.0 - health.current / MAX_HEALTH
	if state == State.DEFEATED:
		return
	_flash = 0.035
	Events.impact.emit(0.0, 2.0)
	var next_phase: int = phase_for(health.current / MAX_HEALTH)
	if next_phase > phase:
		_begin_transition(next_phase)

func _begin_transition(next_phase: int) -> void:
	phase = next_phase
	_sequence_index = 0
	_wave_index = 0
	state = State.PHASE_TRANSITION
	timer = StageBuilder.BOSS_TRANSITION_TIME
	body.invulnerable = true
	pool.clear_enemy()
	if phase == 3:
		_lanes = interference_lanes(0)
	StageBuilder.show_boss_phase(card, phase, PHASE_NAMES[phase - 1], PHASE_COLORS[phase - 1])
	Events.impact.emit(0.0, 6.0)
	phase_changed.emit(phase)

func _defeat() -> void:
	state = State.DEFEATED
	timer = 0.8
	body.invulnerable = true
	body.collision_layer = 0
	body.remove_from_group(&"homing_target")
	pool.clear_enemy()
	BossArt.show_restoration(card)
	GameState.win()
	defeated.emit()
	CelebrationBurst.spawn(self, body.global_position, true)
	Events.boss_defeated.emit(&"wifi_queen")

func _draw() -> void:
	if body == null:
		return
	var color: Color = PHASE_COLORS[phase - 1]
	_draw_bar(color)
	_draw_antennas(color)
	if state == State.DEFEATED:
		BossArt.restored(self, body.position, 0.8 - timer, color,
			GameState.reduce_flashes)
		return
	if state == State.TELEGRAPH and attack == Attack.SPIRAL:
		draw_set_transform(body.position, TAU * (1.0 - timer / WARNINGS[Attack.SPIRAL]))
		_draw_queen(Vector2.ZERO, color)
		draw_set_transform(Vector2.ZERO)
	else:
		_draw_queen(body.position, color)
	if phase == 3 and state != State.PHASE_TRANSITION and _interference_age < INTERFERENCE_END:
		_draw_interference()
	if state == State.TELEGRAPH:
		_draw_warning()

func _draw_bar(color: Color) -> void:
	draw_rect(Rect2(158, 43, 324, 9), PQStyle.NIGHT)
	draw_rect(Rect2(160, 44, 320, 6), PQStyle.CHIP)
	draw_rect(Rect2(160, 44, 320 * health.current / MAX_HEALTH, 6), color)
	for ratio: float in [PHASE_TWO, PHASE_THREE]:
		var x: float = 160 + 320 * ratio
		draw_line(Vector2(x, 42), Vector2(x, 51), Color.WHITE)

func _draw_antennas(color: Color) -> void:
	for index: int in range(ANTENNAS.size()):
		var center: Vector2 = ANTENNAS[index]
		var tint: Color = Color(color, 0.65 if index == _antenna else 0.24)
		draw_line(center + Vector2(0, 13), center + Vector2(0, 51), tint, 2.0)
		draw_line(center + Vector2(-14, 39), center + Vector2(14, 39), tint, 2.0)
		for ring: int in range(3):
			draw_arc(center, 31 + ring * 10, 0.25, PI - 0.25, 16, tint, 1.0)

func _draw_queen(center: Vector2, color: Color) -> void:
	var casing: Color = Color("223756").lerp(color, ArtMotion.hit_strength(_flash, GameState.reduce_flashes))
	var swing: float = roundf(sin(_age * 5.0) * (2.0 + phase))
	for side: float in [-1.0, 1.0]:
		var span: float = 42.0 + phase * 4.0
		var wing: PackedVector2Array = PackedVector2Array([center + Vector2(side * 17, -8),
			center + Vector2(side * span, -19 + swing), center + Vector2(side * (span - 4), 6 + swing),
			center + Vector2(side * 19, 17)])
		draw_colored_polygon(wing, casing)
		wing.append(wing[0])
		draw_polyline(wing, color, 2)
		for rib: int in range(phase + 1):
			var origin: Vector2 = center + Vector2(side * (span - 7), -10 + swing + rib * 4)
			draw_line(origin, center + Vector2(side * 22, -1 + rib * 4), color.darkened(0.35), 2)
		draw_rect(Rect2(center + Vector2(side * (span - 6) - 1, -13 + swing), Vector2(3, 3)), color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-21, -16), center + Vector2(21, -16),
		center + Vector2(24, 4), center + Vector2(0, 23), center + Vector2(-24, 4)]), casing)
	draw_rect(Rect2(center + Vector2(-15, -8), Vector2(30, 14)), PQStyle.NIGHT)
	draw_line(center + Vector2(-10, -2), center + Vector2(-3, 1), color, 3)
	draw_line(center + Vector2(3, 1), center + Vector2(10, -2), color, 3)
	draw_polyline(PackedVector2Array([center + Vector2(-17, -17), center + Vector2(-20, -28),
		center + Vector2(-7, -23), center + Vector2(0, -34), center + Vector2(7, -23),
		center + Vector2(20, -28), center + Vector2(17, -17), center + Vector2(-17, -17)]), PQStyle.AMBER, 2.0)
	for index: int in range(phase):
		draw_rect(Rect2(center + Vector2(index * 6 - phase * 3 + 1, 11), Vector2(4, 3)), color)

func _draw_warning() -> void:
	match attack:
		Attack.WAVES:
			for index: int in range(2):
				var y: float = WAVE_LANES[wave_lanes(_wave_index)[index]]
				draw_dashed_line(Vector2(0, y), Vector2(640, y), PQStyle.AMBER, 1, 8.0)
				if phase == 2 or _wave_index % 2 == 0:
					_draw_wave_arrow(Vector2(18, y), 1.0)
				if phase == 2 or _wave_index % 2 == 1:
					_draw_wave_arrow(Vector2(622, y), -1.0)
		Attack.PING:
			for index: int in range(-2, 3):
				var x: float = _ping_x + index * 32
				draw_polyline(PackedVector2Array([Vector2(x - 5, 56), Vector2(x, 64), Vector2(x + 5, 56)]), PQStyle.AMBER, 2)
		Attack.SPIRAL:
			for index: int in range(5):
				var angle: float = _age * 12 + index * TAU / 5
				draw_arc(body.position, 50.0, angle, angle + 0.6, 8, PQStyle.MAGENTA, 2)
		Attack.TELEPORT:
			var target: Vector2 = ANTENNAS[_destination]
			draw_polyline(PackedVector2Array([target + Vector2(-42, -16), target + Vector2(-20, -10),
				target + Vector2(0, -32), target + Vector2(20, -10), target + Vector2(42, -16),
				target + Vector2(22, 8), target + Vector2(0, 21), target + Vector2(-22, 8),
				target + Vector2(-42, -16)]), Color(PQStyle.MAGENTA, 0.65), 2)

func _draw_wave_arrow(center: Vector2, direction: float) -> void:
	draw_polyline(PackedVector2Array([center + Vector2(-6 * direction, -6), center + Vector2(5 * direction, 0),
		center + Vector2(-6 * direction, 6)]), PQStyle.AMBER, 2)

func _draw_interference() -> void:
	var warning: bool = _interference_age < INTERFERENCE_WARNING
	var color: Color = PQStyle.AMBER if warning else PQStyle.MAGENTA
	for lane: int in _lanes:
		var x: float = lane * 160
		draw_rect(Rect2(x, 42, 160, 262), Color(color, 0.08 if warning else 0.21))
		for y: int in range(56, 304, 12):
			draw_line(Vector2(x, y), Vector2(x + 160, y - 8), Color(color, 0.15), 1.0)
		draw_line(Vector2(x, 42), Vector2(x, 304), Color(color, 0.65), 2.0)
		draw_line(Vector2(x + 160, 42), Vector2(x + 160, 304), Color(color, 0.65), 2.0)
