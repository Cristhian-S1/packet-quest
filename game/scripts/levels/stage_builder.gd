class_name StageBuilder
extends RefCounted

const BOSS_TRANSITION_TIME: float = 2.4

static func background(parent: Node) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = -10
	layer.add_child(CircuitBackground.new())
	parent.add_child(layer)

static func parallax(parent: Node, backdrop: Node2D, base: Color, tint: Color) -> void:
	var backdrop_layer: LevelParallax = LevelParallax.new()
	backdrop_layer.name = "LevelParallax"
	backdrop_layer.base = base
	backdrop_layer.tint = tint
	backdrop_layer.middle = backdrop
	parent.add_child(backdrop_layer)

static func platform(parent: Node, pos: Vector2, size: Vector2, moving: float = 0.0, one_way: bool = false,
		chip: ChipPlatform = null) -> ChipPlatform:
	if chip == null:
		chip = ChipPlatform.new()
	chip.position = pos
	chip.size = size
	chip.vertical_travel = moving
	chip.one_way = one_way
	parent.add_child(chip)
	return chip

static func player(parent: Node, pos: Vector2, width: int = 2720) -> PacketPlayer:
	var byte: PacketPlayer = preload("res://scenes/player/Player.tscn").instantiate() as PacketPlayer
	byte.position = pos
	byte.camera_width = width
	parent.add_child(byte)
	if GameState.boss_rush_active and GameState.boss_rush_hp > 0.0:
		byte.health.current = minf(GameState.boss_rush_hp, byte.health.max_health)
		byte.health.changed.emit(byte.health.current, byte.health.max_health)
	return byte

static func hud(parent: Node, level_exit_x: float = 0.0) -> void:
	var overlay: PacketHUD = preload("res://scenes/ui/HUD.tscn").instantiate() as PacketHUD
	overlay.level_exit_x = level_exit_x
	parent.add_child(overlay)

static func boss_card(parent: Node, boss_name: String, opening: String, title_center: Vector2 = Vector2(320, 52)) -> Label:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 12
	parent.add_child(layer)
	var heading: Label = PQStyle.label_at(layer, boss_name, title_center - Vector2(80, 0), 13, PQStyle.MAGENTA)
	heading.size.x = 160
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card: Label = PQStyle.label_at(layer, opening, Vector2(128, 104), 24, PQStyle.CYAN)
	card.size = Vector2(384, 72)
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return card

static func show_boss_phase(card: Label, phase_number: int, phase_name: String, color: Color) -> void:
	card.text = "FASE %02d\n%s" % [phase_number, phase_name.to_upper()]
	card.modulate = color
	card.show()

static func show_victory_stats(card: Label) -> void:
	if GameState.boss_rush_active:
		return
	var panel: Panel = Panel.new()
	panel.position = Vector2(36, 151)
	panel.size = Vector2(568, 47)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", PQStyle.panel(PQStyle.NIGHT, PQStyle.CHIP))
	card.get_parent().add_child(panel)
	for boss: bool in [false, true]:
		var record: bool = GameState.boss_record if boss else GameState.level_record
		var line: Label = PQStyle.label_at(panel, StageStats.summary(GameState.data, GameState.current_world, boss, record),
			Vector2(0, 7 if boss else 25), 12, PQStyle.GREEN if record else Color.WHITE)
		line.size.x = panel.size.x
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
