class_name PacketCheckpoint
extends Area2D

signal reached
var active: bool = false

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	add_child(PQStyle.box_shape(Vector2(24, 40)))
	body_entered.connect(_entered)
	active = GameState.checkpoint.x >= global_position.x - 8
	queue_redraw()

func _entered(body: Node2D) -> void:
	if not body is PacketPlayer or active:
		return
	active = true
	GameState.checkpoint = global_position
	(body as PacketPlayer).health.heal(3)
	Events.checkpoint_reached.emit(global_position)
	reached.emit()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(0, 12), Vector2(0, -25), PQStyle.EDGE, 2)
	draw_rect(Rect2(0, -25, 20, 12), PQStyle.GREEN if active else PQStyle.CHIP)
	draw_line(Vector2(5, -19), Vector2(9, -15), PQStyle.NIGHT, 2)
	draw_line(Vector2(9, -15), Vector2(16, -23), PQStyle.NIGHT, 2)
