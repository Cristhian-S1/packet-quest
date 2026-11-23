extends Node2D

const OPTIONS: PackedScene = preload("res://scenes/ui/OptionsMenu.tscn")

var age: float = 0.0
var _buttons: HBoxContainer
var _options_button: Button

func _ready() -> void:
	StageBuilder.background(self)
	PQStyle.label_at(self, "PQ / PROTOCOLO DE RESTAURACIÓN", Vector2(36, 28), 10, PQStyle.GREEN)
	PQStyle.label_at(self, "PACKET\nQUEST", Vector2(32, 68), 40, PQStyle.CYAN)
	PQStyle.label_at(self, "LA RED ROTA", Vector2(36, 194), 19)
	PQStyle.label_at(self, "Una red infectada. Un paquete íntegro.", Vector2(36, 224), 12, PQStyle.EDGE)
	_buttons = HBoxContainer.new()
	_buttons.position = Vector2(36, 262)
	_buttons.add_theme_constant_override("separation", 12)
	add_child(_buttons)
	var play: Button = PQStyle.button(_buttons, "Jugar   →", Vector2.ZERO, GameState.open_map)
	play.custom_minimum_size = Vector2(176, 32)
	_options_button = PQStyle.button(_buttons, "Opciones", Vector2.ZERO, _open_options)
	_options_button.custom_minimum_size = Vector2(112, 32)
	var exit: Button = PQStyle.button(_buttons, "Salir", Vector2.ZERO, _quit)
	exit.custom_minimum_size = Vector2(84, 32)
	play.grab_focus()
	PQStyle.label_at(self, "%d MUNDOS" % SaveManager.WORLD_COUNT, Vector2(483, 273), 11, PQStyle.GREEN)
	PQStyle.label_at(self, "GODOT 4.7.2", Vector2(36, 332), 9, PQStyle.EDGE)

func _open_options() -> void:
	_buttons.hide()
	var options: OptionsMenu = OPTIONS.instantiate() as OptionsMenu
	options.closed.connect(_restore_options_focus)
	add_child(options)

func _restore_options_focus() -> void:
	_buttons.show()
	_options_button.grab_focus()

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _quit() -> void:
	get_tree().quit()

func _draw() -> void:
	draw_line(Vector2(36, 53), Vector2(604, 53), PQStyle.CHIP)
	var center: Vector2 = Vector2(476, 169 + sin(age * 2) * 5)
	for index: int in range(3):
		var radius: float = 55 + index * 18
		draw_arc(center, radius, age * 0.15 + index, age * 0.15 + index + 4.8, 48, Color(PQStyle.CYAN, 0.1 + index * 0.05), 1)
	draw_rect(Rect2(center - Vector2(32, 32), Vector2(64, 64)), PQStyle.CYAN)
	draw_rect(Rect2(center - Vector2(24, 24), Vector2(48, 12)), Color.WHITE)
	draw_rect(Rect2(center + Vector2(-14, 0), Vector2(8, 12)), PQStyle.NIGHT)
	draw_rect(Rect2(center + Vector2(10, 0), Vector2(8, 12)), PQStyle.NIGHT)
	draw_line(center + Vector2(-16, 32), center + Vector2(-24, 44), PQStyle.CYAN, 6)
	draw_line(center + Vector2(16, 32), center + Vector2(24, 44), PQStyle.CYAN, 6)
	draw_rect(Rect2(center + Vector2(26, 4), Vector2(30, 12)), PQStyle.CHIP)
	draw_circle(center + Vector2(28, 16), 10, Color.WHITE)
	draw_rect(Rect2(center + Vector2(48, 4), Vector2(10, 12)), PQStyle.CYAN)
	for index: int in range(3):
		var x: float = 370 + index * 100
		draw_rect(Rect2(x, 302, 6, 6), PQStyle.GREEN if index == 0 else PQStyle.EDGE)
		if index < 2:
			draw_line(Vector2(x + 6, 305), Vector2(x + 100, 305), PQStyle.CHIP)
