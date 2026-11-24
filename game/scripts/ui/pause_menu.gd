extends PacketScreen

const OPTIONS: PackedScene = preload("res://scenes/ui/OptionsMenu.tscn")

var _options_button: Button

func _ready() -> void:
	super._ready()
	title("Conexión en pausa")
	subtitle("La red puede esperar.")
	PQStyle.button(panel, "Continuar", Vector2(208, 156), _resume).grab_focus()
	_options_button = PQStyle.button(panel, "Opciones", Vector2(208, 196), _open_options)
	if GameState.boss_rush_active:
		PQStyle.button(panel, "Terminar ronda", Vector2(208, 236), GameState.end_boss_rush)
	else:
		PQStyle.button(panel, "Reiniciar checkpoint", Vector2(208, 236), GameState.retry)
		PQStyle.button(panel, "Menú principal", Vector2(208, 276), GameState.menu)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_resume()

func _open_options() -> void:
	hide()
	var options: OptionsMenu = OPTIONS.instantiate() as OptionsMenu
	options.closed.connect(_restore_options_focus)
	add_child(options)

func _restore_options_focus() -> void:
	show()
	_options_button.grab_focus()

func _resume() -> void:
	get_tree().paused = false
	queue_free()
