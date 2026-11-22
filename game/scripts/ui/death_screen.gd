extends PacketScreen

signal retry

func _ready() -> void:
	super._ready()
	title("Conexión perdida", PQStyle.MAGENTA)
	subtitle("Cada paquete cuenta. Vuelve a intentarlo.")
	var progress: ProgressBar = ProgressBar.new()
	progress.position = Vector2(160, 166)
	progress.size = Vector2(320, 14)
	progress.value = GameState.boss_progress * 100
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", PQStyle.bar(PQStyle.CHIP))
	progress.add_theme_stylebox_override("fill", PQStyle.bar(PQStyle.MAGENTA))
	panel.add_child(progress)
	if GameState.current_level == GameState.BOSS:
		var marker: ColorRect = ColorRect.new()
		marker.color = Color.WHITE
		marker.position = Vector2(319, 162)
		marker.size = Vector2(2, 22)
		panel.add_child(marker)
	subtitle("Progreso del %s: %d %%" % ["jefe" if GameState.current_level == GameState.BOSS else "nivel", int(GameState.boss_progress * 100)], 192)
	PQStyle.button(panel, "Reintentar", Vector2(208, 228), _retry).grab_focus()
	PQStyle.button(panel, "Menú principal", Vector2(208, 268), GameState.menu)

func _retry() -> void:
	retry.emit()
	GameState.retry()
