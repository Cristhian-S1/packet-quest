class_name StageBuilder
extends RefCounted

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
