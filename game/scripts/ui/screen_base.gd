class_name PacketScreen
extends CanvasLayer

var panel: Control
var backdrop: ColorRect

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	backdrop = ColorRect.new()
	backdrop.color = Color(PQStyle.NIGHT, 0.93)
	backdrop.size = Vector2(640, 360)
	add_child(backdrop)
	panel = Control.new()
	add_child(panel)

func title(text: String, color: Color = PQStyle.CYAN, y: float = 72.0) -> void:
	var label: Label = PQStyle.label_at(panel, text, Vector2(48, y), 30, color)
	label.size.x = 544
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func subtitle(text: String, y: float = 120) -> void:
	var label: Label = PQStyle.label_at(panel, text, Vector2(48, y), 13, PQStyle.EDGE)
	label.size.x = 544
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
