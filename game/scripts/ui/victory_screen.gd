extends PacketScreen

func _ready() -> void:
	super._ready()
	title("¡Conexión restaurada!", PQStyle.GREEN)
	subtitle("MUNDO 01 / RED LOCAL · Router Furioso neutralizado")
	for boss: bool in [false, true]:
		var record: bool = GameState.boss_record if boss else GameState.level_record
		var line: Label = PQStyle.label_at(panel, StageStats.summary(GameState.data, 1, boss, record),
			Vector2(20, 163 if boss else 143), 12, PQStyle.GREEN if record else Color.WHITE)
		line.size.x = 600
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle("Núcleos de datos: %d" % int(GameState.data.get("data_cores", 0)), 188)
	subtitle("Partida guardada" if GameState.save_error == OK else "No se pudo escribir el guardado (%d)" % GameState.save_error, 208)
	PQStyle.button(panel, "Continuar al mapa", Vector2(208, 244), GameState.open_map).grab_focus()
	PQStyle.button(panel, "Menú principal", Vector2(208, 284), GameState.menu)
