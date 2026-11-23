class_name TrojanBoss
extends Node2D

signal phase_changed(index: int)
signal defeated

enum State { INTRO, WARNING, JUMP, OPEN, RECOVERY, PHASE_TRANSITION, DEFEATED }

const CHEST_SPOTS: Array[Vector2] = [Vector2(160, 296), Vector2(320, 296), Vector2(480, 296)]
const DESCARGA_LANES: Array[float] = [296.0, 256.0, 216.0]
const PHASE_NAMES: Array[String] = ["Cofre sellado", "Invocación", "Cofres falsos"]
const POPUP: PackedScene = preload("res://scenes/enemies/PopUp.tscn")
const MAX_HEALTH: float = 150.0
const PHASE_TWO: float = 0.70
const PHASE_THREE: float = 0.40
const WARNING_TIME: float = 0.6
const JUMP_TIME: float = 0.6
const JUMP_HEIGHT: float = 68.0
const GLOW_TIME: float = 0.4
const RECOVERY_TIME: float = 0.8
const SHOT_SPEED: float = 160.0
const BODY_SIZE: Vector2 = Vector2(48, 48)
const PLAYER_SIZE: Vector2 = Vector2(10, 14)

var player: PacketPlayer
var pool: ProjectilePool
var health: HealthComponent
var body: Hurtbox
var card: Label
var phase: int = 1

var _state: State = State.INTRO
var _timer: float = 1.2
var _flash: float = 0.0
var _step: int = 0
var _target: int = 0
var _jump_origin: Vector2
var _lanes: Array[int] = []
var _shot_direction: float = -1.0
var _shot_warning: float = 0.0
var _chips: Array[RID] = []
var _minions: Array[PopUp] = []
var _minions_killed: int = 0

static func phase_for(hp_ratio: float) -> int:
	if hp_ratio <= PHASE_THREE:
		return 3
	return 2 if hp_ratio <= PHASE_TWO else 1

static func chest_spot(index: int) -> Vector2:
	return CHEST_SPOTS[posmod(index, CHEST_SPOTS.size())]

static func open_window(phase_number: int, minions_killed: int) -> float:
	return clampf(1.5 + (0.5 if phase_number >= 2 else 0.0) * minions_killed, 0.0, 3.0)

static func true_chest(step: int) -> int:
	return posmod(step, CHEST_SPOTS.size())

static func descarga_lanes(index: int) -> Array[int]:
	var lanes: Array[int] = [0, 2]
	if (index >> 1) & 1 == 1:
		lanes[0] = 1
	return lanes

func _ready() -> void:
	AudioManager.play_music(&"boss")
	GameState.current_world = 4
	GameState.in_boss = true
	GameState.death_cause = "troyano_real"
	GameState.boss_progress = 0.0
	add_child(ServerBackdrop.new())
	StageBuilder.platform(self, Vector2(0, 304), Vector2(640, 56))
	StageBuilder.platform(self, Vector2(-16, 0), Vector2(16, 360))
	StageBuilder.platform(self, Vector2(640, 0), Vector2(16, 360))
	for x: float in [96.0, 448.0]:
		var chip: ChipPlatform = StageBuilder.platform(self, Vector2(x, 256), Vector2(80, 12), 0.0, true)
		_chips.append(chip.get_rid())
	pool = ProjectilePool.new()
	add_child(pool)
	player = StageBuilder.player(self, GameState.checkpoint if GameState.playing else Vector2(64, 296), 640)
	health = HealthComponent.new()
	health.max_health = MAX_HEALTH
	health.depleted.connect(_defeat)
	add_child(health)
	body = Hurtbox.new()
	body.position = chest_spot(1)
	body.invulnerable = true
	body.homing_target = true
	body.collision_layer = 4
	body.collision_mask = 8
	body.monitoring = false
	body.add_child(PQStyle.box_shape(BODY_SIZE))
	body.hit.connect(take_damage)
	add_child(body)
	StageBuilder.hud(self)
	card = StageBuilder.boss_card(self, "TROYANO REAL", "TROYANO REAL\nCOFRE SELLADO")

func _physics_process(delta: float) -> void:
	if _state != State.DEFEATED and player.state == PacketPlayer.State.DEAD:
		return
	_flash = maxf(0.0, _flash - delta)
	_timer -= delta
	match _state:
		State.JUMP:
			var progress: float = clampf(1.0 - _timer / JUMP_TIME, 0.0, 1.0)
			body.position = _jump_origin.lerp(chest_spot(_target), progress)
			body.position.y -= sin(progress * PI) * JUMP_HEIGHT
		State.OPEN:
			if _shot_warning > 0.0:
				_shot_warning -= delta
				if _shot_warning <= 0.00001:
					_shot_warning = 0.0
					_emit_discharge()
	_check_contact()
	if _timer <= 0.00001:
		match _state:
			State.INTRO, State.PHASE_TRANSITION:
				card.hide()
				_begin_cycle()
			State.WARNING:
				_state = State.JUMP
				_timer = JUMP_TIME
				_jump_origin = body.position
			State.JUMP:
				_open()
			State.OPEN:
				_state = State.RECOVERY
				_timer = RECOVERY_TIME
				body.invulnerable = true
				_clear_minions()
			State.RECOVERY:
				_step += 1
				_begin_cycle()
			State.DEFEATED:
				set_physics_process(false)
				GameState.open_map()
	queue_redraw()

func _begin_cycle() -> void:
	_state = State.WARNING
	_timer = WARNING_TIME
	AudioManager.play_warning(&"trojan_mimics" if phase == 3 else &"trojan_jump")
	_target = true_chest(_step) if phase == 3 else posmod(_step, CHEST_SPOTS.size())
	_lanes = descarga_lanes(_step)

func _open() -> void:
	body.position = chest_spot(_target)
	body.invulnerable = false
	_state = State.OPEN
	_minions_killed = 0
	_timer = open_window(phase, _minions_killed)
	_shot_direction = -1.0 if player.position.x < body.position.x else 1.0
	_shot_warning = WARNING_TIME
	AudioManager.play_warning(&"trojan_discharge")
	if phase == 2:
		AudioManager.play_warning(&"trojan_summon")
		for offset: Vector2 in TrojanPortal.spawn_offsets():
			var minion: PopUp = POPUP.instantiate() as PopUp
			minion.position = body.position + offset
			minion.died.connect(_minion_killed)
			_minions.append(minion)
			add_child(minion)

func _emit_discharge() -> void:
	for lane: int in _lanes:
		var muzzle: Vector2 = to_global(Vector2(body.position.x, DESCARGA_LANES[lane]))
		pool.fire(true, muzzle, Vector2(_shot_direction * SHOT_SPEED, 0), 1.0, Vector2.ZERO, _chips)

func _minion_killed() -> void:
	if _state != State.OPEN:
		return
	var before: float = open_window(phase, _minions_killed)
	_minions_killed += 1
	_timer += open_window(phase, _minions_killed) - before

func _clear_minions() -> void:
	for minion: PopUp in _minions:
		if is_instance_valid(minion):
			minion.queue_free()
	_minions.clear()

func _check_contact() -> void:
	if _state == State.JUMP or _state == State.RECOVERY or (_state == State.WARNING and phase < 3):
		_damage_on_contact(body.position)
	if phase == 3 and (_state == State.JUMP or _state == State.OPEN or _state == State.RECOVERY):
		for index: int in range(CHEST_SPOTS.size()):
			if index != _target:
				_damage_on_contact(CHEST_SPOTS[index])

func _damage_on_contact(center: Vector2) -> void:
	var chest: Rect2 = Rect2(center - BODY_SIZE * 0.5, BODY_SIZE)
	var byte: Rect2 = Rect2(player.position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	if chest.intersects(byte):
		player.take_damage(1.0, to_global(center))

func take_damage(amount: float, _origin: Vector2) -> void:
	if body.invulnerable:
		return
	health.damage(amount)
	GameState.boss_progress = 1.0 - health.current / MAX_HEALTH
	if _state == State.DEFEATED:
		return
	_flash = 0.08
	var next_phase: int = phase_for(health.current / MAX_HEALTH)
	if next_phase > phase:
		_begin_transition(next_phase)
	else:
		Events.impact.emit(0.0, 2.0)

func _begin_transition(next_phase: int) -> void:
	phase = next_phase
	_step = 0
	_state = State.PHASE_TRANSITION
	_timer = StageBuilder.BOSS_TRANSITION_TIME
	body.invulnerable = true
	pool.clear_enemy()
	_clear_minions()
	StageBuilder.show_boss_phase(card, phase, PHASE_NAMES[phase - 1], PQStyle.MAGENTA)
	Events.impact.emit(0.0, 6.0)
	phase_changed.emit(phase)

func _defeat() -> void:
	_state = State.DEFEATED
	_timer = RECOVERY_TIME
	body.invulnerable = true
	body.collision_layer = 0
	body.hide()
	pool.clear_enemy()
	_clear_minions()
	card.text = "SEGMENTO RESTAURADO"
	card.modulate = PQStyle.GREEN
	card.show()
	GameState.collect_core(&"w4_trojan_boss")
	GameState.win()
	defeated.emit()
	CelebrationBurst.spawn(self, body.global_position, true)
	Events.boss_defeated.emit(&"troyano_real")

func _draw() -> void:
	if health == null:
		return
	_draw_health()
	if _state == State.DEFEATED:
		for index: int in range(16):
			var drift: Vector2 = Vector2.from_angle(index * TAU / 16.0) * (RECOVERY_TIME - _timer) * 110.0
			draw_rect(Rect2(body.position + drift, Vector2(4, 4)), PQStyle.GREEN)
		return
	var fake_phase: bool = phase == 3 and _state != State.PHASE_TRANSITION
	if fake_phase:
		for index: int in range(CHEST_SPOTS.size()):
			if index != _target or _state == State.WARNING:
				var glows: bool = index == _target and WARNING_TIME - _timer < GLOW_TIME
				_draw_chest(CHEST_SPOTS[index], PQStyle.CYAN if glows else PQStyle.MAGENTA, false)
	if not (fake_phase and _state == State.WARNING):
		var tint: Color = Color.WHITE if _flash > 0.0 and not GameState.reduce_flashes else PQStyle.MAGENTA
		_draw_chest(body.position, tint, _state == State.OPEN)
	if _state == State.JUMP or (_state == State.WARNING and phase < 3):
		var landing: Vector2 = chest_spot(_target) + Vector2(0, 6)
		draw_rect(Rect2(landing - Vector2(27, 2), Vector2(54, 4)), Color(PQStyle.RED, 0.48))
	if _state == State.OPEN and _shot_warning > 0.0:
		for lane: int in _lanes:
			var y: float = DESCARGA_LANES[lane]
			draw_dashed_line(Vector2(body.position.x, y), Vector2(0.0 if _shot_direction < 0.0 else 640.0, y),
				PQStyle.AMBER, 1.5, 7.0)

func _draw_health() -> void:
	draw_rect(Rect2(158, 43, 324, 9), PQStyle.NIGHT)
	draw_rect(Rect2(160, 44, 320, 6), PQStyle.CHIP)
	draw_rect(Rect2(160, 44, 320 * health.current / MAX_HEALTH, 6), PQStyle.MAGENTA)
	for ratio: float in [PHASE_TWO, PHASE_THREE]:
		var x: float = 160.0 + 320.0 * ratio
		draw_line(Vector2(x, 42), Vector2(x, 51), Color.WHITE)

func _draw_chest(center: Vector2, tint: Color, opened: bool) -> void:
	var base: Rect2 = Rect2(center + Vector2(-24, -12), Vector2(48, 20))
	var lid_y: float = -29.0 if opened else -23.0
	var lid: Rect2 = Rect2(center + Vector2(-25, lid_y), Vector2(50, 11))
	draw_rect(base, PQStyle.NIGHT)
	draw_rect(base.grow(-2.0), PQStyle.CHIP)
	draw_rect(base, tint, false, 2.0)
	draw_rect(lid, PQStyle.CHIP)
	draw_rect(lid, tint, false, 2.0)
	for x: float in [-18.0, 14.0]:
		draw_rect(Rect2(center + Vector2(x, -9), Vector2(4, 14)), Color(tint, 0.5))
	if opened:
		draw_rect(Rect2(center + Vector2(-18, -18), Vector2(36, 6)), PQStyle.RED)
		draw_circle(center + Vector2(0, -13), 8.0, Color(PQStyle.CYAN, 0.4))
		draw_rect(Rect2(center + Vector2(-4, -15), Vector2(8, 9)), PQStyle.CYAN)
	else:
		draw_rect(Rect2(center + Vector2(-5, -15), Vector2(10, 12)), PQStyle.AMBER)
		draw_rect(Rect2(center + Vector2(-1, -12), Vector2(2, 6)), PQStyle.NIGHT)
