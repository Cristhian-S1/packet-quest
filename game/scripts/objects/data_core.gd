class_name DataCore
extends Area2D

signal collected
@export var core_id: StringName = &"w1_hidden_a"
@export var cache_fragment: bool = false
var age: float = 0.0
var taken: bool = false

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	add_child(PQStyle.box_shape(Vector2(18, 18)))
	body_entered.connect(_entered)
	if not cache_fragment and String(core_id) in GameState.data.get("collected_cores", []):
		queue_free()

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _entered(body: Node2D) -> void:
	if taken or not body is PacketPlayer:
		return
	taken = true
	if cache_fragment:
		var player: PacketPlayer = body as PacketPlayer
		player.shield_meter = minf(player.shield_max, player.shield_meter + 20)
	else:
		GameState.collect_core(core_id)
	collected.emit()
	queue_free()

func _draw() -> void:
	draw_core(self, age, PQStyle.GREEN if cache_fragment else PQStyle.AMBER)

static func draw_core(canvas: CanvasItem, age: float, color: Color) -> void:
	var offset: Vector2 = Vector2(0, sin(age * 3) * 3)
	canvas.draw_polyline(PackedVector2Array([offset + Vector2(0, -10), offset + Vector2(8, 0),
		offset + Vector2(0, 10), offset + Vector2(-8, 0), offset + Vector2(0, -10)]), color, 2)
	canvas.draw_rect(Rect2(offset - Vector2(3, 3), Vector2(6, 6)), color)
