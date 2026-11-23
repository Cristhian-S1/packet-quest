class_name PQStyle
extends RefCounted

const NIGHT: Color = Color("070b17")
const BOARD: Color = Color("0e2a22")
const CHIP: Color = Color("2d3a52")
const EDGE: Color = Color("4f6a8f")
const CYAN: Color = Color("3be8ff")
const MAGENTA: Color = Color("ff4fd8")
const PINK: Color = Color("ff3d8b")
const RED: Color = Color("ff3355")
const BLUE: Color = Color("67a7ff")
const GREEN: Color = Color("3bff8a")
const AMBER: Color = Color("ffb13b")

static func box_shape(size: Vector2) -> CollisionShape2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var node: CollisionShape2D = CollisionShape2D.new()
	node.shape = shape
	return node

static func label_at(parent: Node, text: String, pos: Vector2, size: int = 12, color: Color = Color.WHITE) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

static func panel(color: Color = NIGHT, border: Color = EDGE) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func button(parent: Node, text: String, pos: Vector2, action: Callable, width: float = 224.0) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.position = pos
	node.size = Vector2(width, 32)
	node.add_theme_font_size_override("font_size", 14)
	node.add_theme_stylebox_override("normal", panel(BOARD, EDGE))
	node.add_theme_stylebox_override("hover", panel(CHIP, CYAN))
	node.add_theme_stylebox_override("focus", panel(CHIP, CYAN))
	node.add_theme_stylebox_override("pressed", panel(BOARD, GREEN))
	menu_feedback(node)
	node.pressed.connect(action)
	parent.add_child(node)
	return node

static func menu_feedback(control: Control) -> void:
	control.focus_entered.connect(AudioManager.play_sfx.bind(&"menu_focus"))
	if control is BaseButton:
		(control as BaseButton).pressed.connect(AudioManager.play_sfx.bind(&"menu_click"))

static func bar(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style
