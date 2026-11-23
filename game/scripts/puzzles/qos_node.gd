class_name QosNode
extends Area2D

signal pressed(id: StringName)

@export_enum("voz", "video", "correo", "descarga") var traffic_id: String = "voz"

var _lit: bool = false
var _hint: bool = false
var _nearby: bool = false

func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 32
	collision_mask = 2
	monitorable = false
	var proximity: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 21.0
	proximity.shape = circle
	add_child(proximity)
	body_entered.connect(_set_nearby.bind(true))
	body_exited.connect(_set_nearby.bind(false))

func interact() -> void:
	pressed.emit(StringName(traffic_id))

func set_lights(lit: bool, hint: bool = false) -> void:
	if _lit != lit or _hint != hint:
		_lit = lit
		_hint = hint
		queue_redraw()

func _set_nearby(_body: Node2D, nearby: bool) -> void:
	_nearby = nearby
	queue_redraw()

func _draw() -> void:
	var id: StringName = StringName(traffic_id)
	var color: Color = PQStyle.CYAN if _lit or _hint else PQStyle.EDGE
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(-26, -24, 52, 28), PQStyle.NIGHT)
	draw_rect(Rect2(-26, -24, 52, 28), color, false)
	draw_string(font, Vector2(-26, -29), QosPuzzle.LABELS[id], HORIZONTAL_ALIGNMENT_CENTER, 52, 10, color)
	var urgency: int = QosPuzzle.urgency(id)
	for index: int in range(urgency):
		draw_rect(Rect2((index - (urgency - 1) * 0.5) * 7.0 - 2, -17, 4, 13), color)
	if _nearby:
		draw_string(font, Vector2(-26, -45), InputLabels.for_action(&"interact"), HORIZONTAL_ALIGNMENT_CENTER, 52, 10, Color.WHITE)
