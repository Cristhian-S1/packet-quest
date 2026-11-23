class_name FirewallBoss
extends Node2D

signal phase_changed(index: int)
signal defeated

enum State { INTRO, WAIT, TELEGRAPH, ACTIVE, RECOVERY, PHASE_TRANSITION, DEFEATED }
enum Attack { RULE, LASER }

const MAX_HEALTH: float = 120.0
const PHASE_TWO: float = 0.70
const PHASE_THREE: float = 0.40
const PHASE_NAMES: Array[String] = ["Reglas de bloqueo", "Puertos abiertos", "El muro avanza"]
const PORT_COLORS: Array[Color] = [PQStyle.RED, PQStyle.GREEN, PQStyle.BLUE]
const FLOOR: float = 304.0
const CENTER_PORT: float = 176.0
const PORT_SIZE: float = 48.0
const PORT_NAMES: Array[String] = ["ALTO", "MEDIO", "BAJO"]
const PORT_TIME: float = 1.2
const PORT_CYCLE: float = 2.8
const PORT_WARNING: float = 0.4
const WALL_START: float = 480.0
const WALL_LIMIT: float = 160.0
const WALL_SPEED: float = 24.0
const WALL_DEPTH: float = 64.0
const CORE_DEPTH: float = 40.0
const LASER_WARNING: float = 0.8
const LASER_ACTIVE: float = 0.45

var player: PacketPlayer
var pool: ProjectilePool
var health: HealthComponent
var core: Hurtbox
var card: Label
var phase: int = 1

var _state: State = State.INTRO
var _timer: float = 1.2
var _phase_age: float = 0.0
var _pending_phase: int = 0
var _attack: Attack = Attack.RULE
var _laser_next: bool = true
var _laser_y: float = 296.0
var _rule_index: int = 0
var _rules: Array[RuleBar] = []
var _wall: Node2D
var _upper: FirewallBrick
var _lower: FirewallBrick
var _port_y: float = -1.0
var _port_warning: bool = false
var _port_flash: float = 0.0

static func phase_for(hp_ratio: float) -> int:
	if hp_ratio <= PHASE_THREE:
		return 3
	return 2 if hp_ratio <= PHASE_TWO else 1

static func rule_gap_lane(index: int) -> int:
	return posmod(index, RuleBar.LANES_Y.size())

static func correct_port(step: int) -> int:
	return posmod(step, RuleBar.LANES_Y.size())

static func wall_x(elapsed: float, hits: int) -> float:
	return clampf(WALL_START - WALL_SPEED * elapsed + 8.0 * hits, WALL_LIMIT, WALL_START)

func _ready() -> void:
	AudioManager.play_music(&"boss")
	GameState.current_world = 3
	GameState.in_boss = true
	GameState.death_cause = "firewall_corrupto"
	GameState.boss_progress = 0.0
	process_physics_priority = -5
	add_child(FirewallBackdrop.new())
	pool = ProjectilePool.new()
	add_child(pool)
	StageBuilder.platform(self, Vector2(0, FLOOR), Vector2(640, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(640, 0), Vector2(16, 360))
	for x: float in [96.0, 272.0]:
		StageBuilder.platform(self, Vector2(x, 256), Vector2(80, 10), 0.0, true)
	player = StageBuilder.player(self, GameState.checkpoint if GameState.playing else Vector2(64, 296), 640)
	health = HealthComponent.new()
	health.max_health = MAX_HEALTH
	health.depleted.connect(_defeat)
	add_child(health)
	_build_wall()
	for _index: int in range(4):
		var rule: RuleBar = RuleBar.new()
		rule.swept = true
		_rules.append(rule)
		add_child(rule)
	StageBuilder.hud(self)
	card = StageBuilder.boss_card(self, "FIREWALL CORRUPTO", "FIREWALL CORRUPTO\nREGLAS DE BLOQUEO")
	card.position.y = 107.0

func _build_wall() -> void:
	_wall = Node2D.new()
	_wall.name = "Muro"
	_wall.position.x = WALL_START
	add_child(_wall)
	_upper = _build_brick(0.0, WALL_DEPTH)
	_lower = _build_brick(0.0, WALL_DEPTH)
	_lower.set_height(0.0)
	_build_brick(WALL_DEPTH, 640.0 - WALL_START - WALL_DEPTH)
	core = Hurtbox.new()
	core.name = "Núcleo"
	core.position = Vector2(CORE_DEPTH, CENTER_PORT)
	core.collision_layer = 0
	core.collision_mask = 0
	core.monitoring = false
	core.homing_target = true
	core.invulnerable = true
	core.add_child(PQStyle.box_shape(Vector2.ONE * PORT_SIZE))
	core.hit.connect(take_damage)
	_wall.add_child(core)
	core.hide()

func _build_brick(x: float, width: float) -> FirewallBrick:
	var brick: FirewallBrick = FirewallBrick.new()
	brick.struck.connect(_brick_struck)
	StageBuilder.platform(_wall, Vector2(x, 0), Vector2(width, FLOOR), 0.0, false, brick)
	return brick

func _physics_process(delta: float) -> void:
	_port_flash = maxf(0.0, _port_flash - delta)
	match _state:
		State.INTRO, State.PHASE_TRANSITION:
			_timer -= delta
			if _timer <= 0.00001:
				card.hide()
				_state = State.WAIT
				_timer = 0.0
				_update_ports()
		State.DEFEATED:
			_timer -= delta
			if _timer <= 0.0:
				set_physics_process(false)
				GameState.open_map()
		_:
			if player.state != PacketPlayer.State.DEAD:
				_phase_age += delta
				_update_ports()
				if phase == 3:
					_move_wall(delta)
					_wall_contact()
				_tick_attacks(delta)
	queue_redraw()

func _update_ports() -> void:
	_port_warning = false
	match phase:
		1:
			var cycle: float = fposmod(_phase_age, PORT_CYCLE)
			var opens_at: float = PORT_CYCLE - PORT_TIME
			_port_warning = cycle >= opens_at - PORT_WARNING and cycle < opens_at
			_set_port(CENTER_PORT if cycle >= opens_at else -1.0)
		2:
			var socket: int = correct_port(floori(_phase_age / PORT_TIME))
			_set_port(RuleBar.LANES_Y[2 - socket])
		3:
			_set_port(CENTER_PORT)

func _set_port(y: float) -> void:
	if _port_y == y:
		return
	_port_y = y
	var opened: bool = y >= 0.0
	core.invulnerable = not opened or _pending_phase != 0
	core.collision_layer = 4 if opened else 0
	core.visible = opened
	if opened:
		core.position.y = y
		_upper.set_height(y - PORT_SIZE / 2.0)
		_lower.position.y = minf(FLOOR, y + PORT_SIZE / 2.0)
		_lower.set_height(FLOOR - _lower.position.y)
	else:
		_upper.set_height(FLOOR)
		_lower.set_height(0.0)

func _tick_attacks(delta: float) -> void:
	_timer -= delta
	if _state == State.ACTIVE and absf(player.position.y - _laser_y) < 10.0 and player.position.x < _wall.position.x:
		player.take_damage(1.0, Vector2(_wall.position.x, _laser_y))
	if _timer > 0.00001:
		return
	match _state:
		State.WAIT:
			_begin_attack()
		State.TELEGRAPH:
			if _attack == Attack.LASER:
				_state = State.ACTIVE
				_timer = LASER_ACTIVE
			else:
				_recover()
		State.ACTIVE:
			if _pending_phase != 0:
				_begin_transition(_pending_phase)
			else:
				_recover()
		State.RECOVERY:
			_state = State.WAIT
			_timer = 0.5 if phase == 1 else (0.1 if phase == 3 else 0.0)
			if _timer == 0.0:
				_begin_attack()

func _begin_attack() -> void:
	_state = State.TELEGRAPH
	_attack = Attack.LASER if phase == 2 and _laser_next else Attack.RULE
	_laser_next = _attack == Attack.RULE
	if _attack == Attack.LASER:
		_timer = LASER_WARNING
		_laser_y = player.position.y
		AudioManager.play_warning(&"firewall_laser")
	else:
		_timer = RuleBar.SWEEP_WARNING
		var lanes: Array[int] = [rule_gap_lane(_rule_index)]
		if phase == 2:
			lanes.append(rule_gap_lane(_rule_index + 1))
		for rule: RuleBar in _rules:
			if not rule.visible:
				rule.start_sweep(_wall.position.x - RuleBar.SIZE.x / 2.0, 140.0 if phase == 1 else 170.0, lanes)
				break
		_rule_index += 1
		AudioManager.play_warning(&"firewall_rule")

func _recover() -> void:
	_state = State.RECOVERY
	_timer = 1.0 if phase == 1 else 0.8

func _move_wall(delta: float) -> void:
	# El tope descarta el avance sobrante para que cada impacto aún pueda empujar el muro.
	var elapsed: float = (WALL_START - _wall.position.x) / WALL_SPEED + delta
	_wall.position.x = wall_x(elapsed, 0)

func _brick_struck() -> void:
	if phase != 3 or _state == State.PHASE_TRANSITION or _state == State.DEFEATED:
		return
	var elapsed: float = (WALL_START - _wall.position.x) / WALL_SPEED
	_wall.position.x = wall_x(elapsed, 1)
	_port_flash = 0.12

func _wall_contact() -> void:
	const CONTACT_MARGIN: float = 6.0
	if player.position.x + CONTACT_MARGIN < _wall.position.x:
		return
	var safe_y: bool = absf(player.position.y - CENTER_PORT) + 7.0 <= PORT_SIZE / 2.0
	if not safe_y or player.position.x + CONTACT_MARGIN >= _wall.position.x + WALL_DEPTH:
		player.take_damage(1.0, Vector2(_wall.position.x + WALL_DEPTH, player.position.y))

func take_damage(amount: float, _origin: Vector2) -> void:
	if core.invulnerable:
		return
	health.damage(amount)
	GameState.boss_progress = 1.0 - health.current / MAX_HEALTH
	if _state == State.DEFEATED:
		return
	_port_flash = 0.08
	Events.impact.emit(0.0, 2.0)
	var next_phase: int = phase_for(health.current / MAX_HEALTH)
	if next_phase > phase:
		if _state == State.ACTIVE:
			_pending_phase = next_phase
			core.invulnerable = true
		else:
			_begin_transition(next_phase)

func _begin_transition(next_phase: int) -> void:
	phase = next_phase
	_pending_phase = 0
	_phase_age = 0.0
	_rule_index = 0
	_laser_next = true
	_state = State.PHASE_TRANSITION
	_timer = StageBuilder.BOSS_TRANSITION_TIME
	_port_warning = false
	_set_port(-1.0)
	_clear_attacks()
	StageBuilder.show_boss_phase(card, phase, PHASE_NAMES[phase - 1], PQStyle.RED)
	Events.impact.emit(0.0, 6.0)
	phase_changed.emit(phase)

func _clear_attacks() -> void:
	pool.clear_enemy()
	for rule: RuleBar in _rules:
		rule.stop_sweep()

func _defeat() -> void:
	_state = State.DEFEATED
	_timer = 0.8
	var origin: Vector2 = _wall.to_global(Vector2(14, _port_y if _port_y >= 0.0 else CENTER_PORT))
	_set_port(-1.0)
	_clear_attacks()
	_wall.hide()
	CelebrationBurst.spawn(self, origin, true)
	card.text = "SEGMENTO RESTAURADO"
	card.modulate = PQStyle.GREEN
	card.show()
	GameState.collect_core(&"w3_firewall_boss")
	GameState.win()
	defeated.emit()
	Events.boss_defeated.emit(&"firewall_corrupto")

func _draw() -> void:
	if health == null:
		return
	_draw_health()
	if _state == State.DEFEATED:
		for index: int in range(20):
			var drift: Vector2 = Vector2.from_angle(index * TAU / 20.0) * (0.8 - _timer) * 160.0
			draw_rect(Rect2(to_local(core.global_position) + drift, Vector2(4, 4)), PQStyle.GREEN)
		return
	_draw_ports()
	if _attack == Attack.LASER and (_state == State.TELEGRAPH or _state == State.ACTIVE):
		_draw_laser()

func _draw_health() -> void:
	draw_rect(Rect2(158, 43, 324, 9), PQStyle.NIGHT)
	draw_rect(Rect2(160, 44, 320, 6), PQStyle.CHIP)
	draw_rect(Rect2(160, 44, 320 * health.current / MAX_HEALTH, 6), PQStyle.RED)
	for ratio: float in [PHASE_TWO, PHASE_THREE]:
		var marker: float = 160.0 + 320.0 * ratio
		draw_line(Vector2(marker, 42), Vector2(marker, 51), Color.WHITE)

func _draw_ports() -> void:
	var front: float = _wall.position.x
	for index: int in range(PORT_NAMES.size()):
		var y: float = CENTER_PORT if phase != 2 and index == 0 else RuleBar.LANES_Y[2 - index]
		var active: bool = y == _port_y
		var tint: Color = PORT_COLORS[index] if phase == 2 else PQStyle.AMBER
		if not active:
			tint = Color(tint, 0.42)
		if index == 0 and _port_warning and (GameState.reduce_flashes or int(_phase_age * 18.0) % 2 == 0):
			tint = Color.WHITE
		var height: float = minf(PORT_SIZE, FLOOR - y + PORT_SIZE / 2.0)
		var mouth: Rect2 = Rect2(front + CORE_DEPTH - PORT_SIZE / 2.0, y - PORT_SIZE / 2.0, PORT_SIZE, height)
		if active:
			draw_rect(Rect2(front, mouth.position.y, WALL_DEPTH, height), Color(PQStyle.NIGHT, 0.75))
			_draw_core(Vector2(front + CORE_DEPTH, y), tint)
		draw_rect(mouth, tint, false, 1.0)
		var port_name: String = "CENTRAL" if phase != 2 and index == 0 else PORT_NAMES[index]
		draw_string(ThemeDB.fallback_font, Vector2(front + 73, y + 4), port_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tint)
	draw_rect(Rect2(front + 80, 86, 62, 40), PQStyle.NIGHT)
	draw_rect(Rect2(front + 80, 86, 62, 40), PQStyle.RED, false)
	draw_string(ThemeDB.fallback_font, Vector2(front + 88, 102), "ESTADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PQStyle.RED)
	draw_string(ThemeDB.fallback_font, Vector2(front + 88, 117), "ABIERTO" if _port_y >= 0.0 else "CERRADO",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PQStyle.GREEN if _port_y >= 0.0 else PQStyle.AMBER)

func _draw_core(center: Vector2, tint: Color) -> void:
	if _port_flash > 0.0 and not GameState.reduce_flashes:
		tint = Color.WHITE
	var diamond: PackedVector2Array = PackedVector2Array([center + Vector2(0, -16), center + Vector2(15, 0),
		center + Vector2(0, 16), center + Vector2(-15, 0), center + Vector2(0, -16)])
	draw_colored_polygon(diamond, Color(tint, 0.25))
	draw_polyline(diamond, tint, 2.0)
	draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), tint)

func _draw_laser() -> void:
	var socket: Vector2 = Vector2(_wall.position.x + 14, _port_y)
	var elbow: Vector2 = Vector2(socket.x, _laser_y)
	var endpoint: Vector2 = Vector2(0, _laser_y)
	if _state == State.TELEGRAPH:
		draw_dashed_line(socket, elbow, PQStyle.RED, 1.0, 5.0)
		draw_dashed_line(elbow, endpoint, PQStyle.RED, 2.0, 8.0)
	else:
		var beam: PackedVector2Array = PackedVector2Array([socket, elbow, endpoint])
		draw_polyline(beam, PQStyle.RED, 8.0)
		draw_polyline(beam, Color.WHITE, 2.0)


class FirewallBrick extends ChipPlatform:
	signal struck

	var _shape: CollisionShape2D
	var _flash: float = 0.0

	func _ready() -> void:
		super._ready()
		_shape = get_child(0) as CollisionShape2D
		sync_to_physics = false
		z_index = -1

	func set_height(height: float) -> void:
		size.y = height
		_shape.disabled = height <= 0.0
		if height > 0.0:
			(_shape.shape as RectangleShape2D).size = size
			_shape.position = size / 2.0
		visible = height > 0.0
		queue_redraw()

	func receive_projectile(_amount: float, _origin: Vector2, _velocity: Vector2) -> void:
		struck.emit()
		_flash = 0.12
		queue_redraw()

	func _physics_process(delta: float) -> void:
		if _flash > 0.0:
			_flash = maxf(0.0, _flash - delta)
			if _flash == 0.0:
				queue_redraw()

	func _draw() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("4e183a"))
		draw_rect(rect, PQStyle.RED, false)
		for y: int in range(16, int(size.y), 16):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(PQStyle.RED, 0.30))
			var offset: int = 8 if y % 32 == 0 else 23
			for x: int in range(offset, int(size.x), 30):
				draw_line(Vector2(x, y - 15), Vector2(x, y), Color(PQStyle.RED, 0.30))
		draw_line(Vector2(1, 0), Vector2(1, size.y), PQStyle.RED, 2.0)
		if _flash > 0.0 and not GameState.reduce_flashes:
			draw_line(Vector2(3, 0), Vector2(3, size.y), PQStyle.AMBER, 2.0)
