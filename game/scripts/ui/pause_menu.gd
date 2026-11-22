extends PacketScreen

func _ready() -> void:
	super._ready()
	title("Conexión en pausa")
	subtitle("La red puede esperar.")
	PQStyle.button(panel, "Continuar", Vector2(208, 172), _resume).grab_focus()
	PQStyle.button(panel, "Reiniciar checkpoint", Vector2(208, 212), GameState.retry)
	PQStyle.button(panel, "Menú principal", Vector2(208, 252), GameState.menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_resume()

func _resume() -> void:
	get_tree().paused = false
	queue_free()
