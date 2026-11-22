class_name StageBuilder
extends RefCounted

const BOSS_TRANSITION_TIME: float = 2.4

static func background(parent: Node) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = -10
	layer.add_child(CircuitBackground.new())
	parent.add_child(layer)

static func platform(parent: Node, pos: Vector2, size: Vector2, moving: float = 0.0, one_way: bool = false) -> ChipPlatform:
	var chip: ChipPlatform = ChipPlatform.new()
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
	return byte

static func hud(parent: Node) -> void:
	parent.add_child(preload("res://scenes/ui/HUD.tscn").instantiate())

static func boss_card(parent: Node, boss_name: String, opening: String) -> Label:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 12
	parent.add_child(layer)
	var heading: Label = PQStyle.label_at(layer, boss_name, Vector2(160, 52), 13, PQStyle.MAGENTA)
	heading.size.x = 320
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card: Label = PQStyle.label_at(layer, opening, Vector2(128, 104), 24, PQStyle.CYAN)
	card.size = Vector2(384, 72)
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return card

static func show_boss_phase(card: Label, phase_number: int, phase_name: String, color: Color) -> void:
	card.text = "FASE %02d\n%s" % [phase_number, phase_name.to_upper()]
	card.modulate = color
	card.show()
