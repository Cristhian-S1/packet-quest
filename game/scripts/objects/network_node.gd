class_name NetworkNode
extends Area2D

signal activated
@export var targets: Array[NodePath] = []
@export var corruption_hits: int = 0
@export var accent: Color = PQStyle.GREEN
var nearby: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 32 | (4 if corruption_hits > 0 else 0)
	collision_mask = 2
	add_child(PQStyle.box_shape(Vector2(16, 20)))

func _process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	nearby = player != null and player.global_position.distance_to(global_position) <= 24
	queue_redraw()

func interact() -> void:
	if corruption_hits > 0:
		return
	for path: NodePath in targets:
		var target: Node = get_node_or_null(path)
		if target != null and target.has_method("activate"):
			target.call("activate")
	activated.emit()

func take_damage(_amount: float, _origin: Vector2) -> void:
	corruption_hits = maxi(0, corruption_hits - 1)
	if corruption_hits == 0:
		collision_layer = 32
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-8, -10, 16, 20), PQStyle.CHIP)
	draw_rect(Rect2(-5, -7, 10, 9), PQStyle.RED if corruption_hits > 0 else accent)
	if nearby:
		draw_arc(Vector2.ZERO, 15, 0, TAU, 16, accent, 1)
		draw_string(ThemeDB.fallback_font, Vector2(-3, -19), InputLabels.for_action(&"interact"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
