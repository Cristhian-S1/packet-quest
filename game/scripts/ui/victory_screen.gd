extends PacketScreen

func _ready() -> void:
	super._ready()
	title("¡Conexión restaurada!", PQStyle.GREEN)
	subtitle("MUNDO 01 / RED LOCAL · Router Furioso neutralizado")
	subtitle("Núcleos de datos: %d" % int(GameState.data.get("data_cores", 0)), 160)
	subtitle("Partida guardada" if GameState.save_error == OK else "No se pudo escribir el guardado (%d)" % GameState.save_error, 184)
	PQStyle.button(panel, "Volver a jugar", Vector2(208, 224), GameState.start_run).grab_focus()
	PQStyle.button(panel, "Menú principal", Vector2(208, 264), GameState.menu)
