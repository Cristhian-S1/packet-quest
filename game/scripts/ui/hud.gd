class_name PacketHUD
extends CanvasLayer

var player: PacketPlayer
var canvas: Control
var info: Label
var notice: Label
var notice_time: float = 0.0
## Fotogramas de hit-stop restantes (no milisegundos: así es determinista con --fixed-fps).
var hit_stop_frames: int = 0
var death_shown: bool = false
var _stopping: bool = false
var _pause_key: String

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("player") as PacketPlayer
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_hud)
	add_child(canvas)
	info = PQStyle.label_at(canvas, "", Vector2(384, 12), 11, PQStyle.EDGE)
	notice = PQStyle.label_at(canvas, "", Vector2(128, 328), 12, PQStyle.GREEN)
	Events.player_died.connect(_death)
	Events.checkpoint_reached.connect(_checkpoint)
	Events.core_collected.connect(_core)
	Events.impact.connect(_impact)
	GameState.settings_changed.connect(_settings_changed)
	_settings_changed("")

func _process(delta: float) -> void:
	canvas.queue_redraw()
	var weapon_name: String = player.current_weapon().display_name.to_upper() if is_instance_valid(player) else "PAQUETE"
	info.text = "%s   ·   NÚCLEOS %02d   ·   %s pausa" % [
		weapon_name, int(GameState.data.get("data_cores", 0)), _pause_key]
	notice_time = maxf(0, notice_time - delta)
	notice.visible = notice_time > 0
	if hit_stop_frames > 0:
		hit_stop_frames -= 1
	if _stopping and hit_stop_frames == 0:
		_stopping = false
		GameState.restore_speed()

func _settings_changed(key: String) -> void:
	if key.is_empty() or key == "bindings":
		_pause_key = InputLabels.for_action(&"pause")

func _draw_hud() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 42), Color(PQStyle.NIGHT, 0.96))
	canvas.draw_line(Vector2(16, 41), Vector2(624, 41), PQStyle.CHIP, 1)
	if not is_instance_valid(player):
		return
	canvas.draw_string(ThemeDB.fallback_font, Vector2(16, 14), "BYTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PQStyle.CYAN)
	for index: int in range(int(player.health.max_health)):
		var height: float = 7 + index * 4
		canvas.draw_rect(Rect2(16 + index * 10, 34 - height, 7, height), PQStyle.CYAN if player.health.current > index else PQStyle.CHIP)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(76, 14), "FIREWALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PQStyle.GREEN)
	canvas.draw_rect(Rect2(76, 22, 88, 7), PQStyle.CHIP)
	canvas.draw_rect(Rect2(76, 22, 88 * player.shield_meter / player.shield_max, 7), PQStyle.RED if player.shield_broken > 0 else PQStyle.GREEN)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(188, 14), "DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PQStyle.CYAN)
	canvas.draw_rect(Rect2(188, 22, 60, 7), PQStyle.CHIP)
	canvas.draw_rect(Rect2(188, 22, 60 * (1 - player.cooldown / player.dash_cooldown), 7), PQStyle.CYAN)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused and not death_shown:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		add_child(preload("res://scenes/ui/PauseMenu.tscn").instantiate())

func _death() -> void:
	if death_shown:
		return
	death_shown = true
	if is_instance_valid(player) and not GameState.in_boss:
		GameState.boss_progress = clampf(player.global_position.x / player.camera_width, 0, 1)
	get_tree().paused = true
	add_child(preload("res://scenes/ui/DeathScreen.tscn").instantiate())

func _checkpoint(_pos: Vector2) -> void:
	notice.text = "Punto de restauración conectado"
	notice_time = 3

func _core(_id: StringName) -> void:
	notice.text = "+1 núcleo de datos · Progreso guardado"
	notice_time = 3

func _impact(duration: float, _shake: float) -> void:
	if duration <= 0 or get_tree().paused:
		return
	hit_stop_frames = maxi(hit_stop_frames, ceili(duration * 60.0))
	_stopping = true
	Engine.time_scale = 0.05

func _exit_tree() -> void:
	GameState.restore_speed()
