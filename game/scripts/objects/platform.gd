class_name ChipPlatform
extends AnimatableBody2D

const TileArt = preload("res://scripts/art/tile_art.gd")

@export var size: Vector2 = Vector2(96, 16)
@export var vertical_travel: float = 0.0
@export var period: float = 3.2
@export var one_way: bool = false
var anchor: Vector2
var age: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	anchor = position
	var shape: CollisionShape2D = PQStyle.box_shape(size)
	shape.position = size / 2
	shape.one_way_collision = one_way
	add_child(shape)
	sync_to_physics = true
	if vertical_travel > 0.0:
		var guide: Line2D = Line2D.new()
		guide.name = "CableGuide"
		guide.top_level = true
		guide.z_index = -1
		guide.position = to_global(Vector2(size.x / 2.0, 0.0))
		guide.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -vertical_travel)])
		guide.width = 1.0
		guide.default_color = PQStyle.EDGE
		add_child(guide)

func _physics_process(delta: float) -> void:
	if vertical_travel != 0:
		age += delta
		position.y = oscillating_top(anchor.y, vertical_travel, period, age)

static func oscillating_top(anchor_y: float, travel: float, duration: float, t: float) -> float:
	return anchor_y - (1.0 - cos(t * TAU / duration)) * travel / 2.0

func _draw() -> void:
	var rim: Color = PQStyle.BLUE.darkened(0.28) if vertical_travel > 0.0 else PQStyle.EDGE
	TileArt.chip(self, Rect2(Vector2.ZERO, size), rim)
