extends PacketScreen

signal retry
const ROUTER_THRESHOLDS: Array[float] = [0.5]
const WIFI_THRESHOLDS: Array[float] = [0.3, 0.6]
const MALWAREX_THRESHOLDS: Array[float] = [0.25, 0.5, 0.75]

func _ready() -> void:
	super._ready()
	title("Conexión perdida", PQStyle.MAGENTA)
	subtitle("Cada paquete cuenta. Vuelve a intentarlo.")
	var percent: float = (GameState.boss_progress if GameState.in_boss else GameState.level_progress) * 100.0
	var progress: ProgressBar = ProgressBar.new()
	progress.position = Vector2(160, 166)
	progress.size = Vector2(320, 14)
	progress.value = percent
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", PQStyle.bar(PQStyle.CHIP))
	progress.add_theme_stylebox_override("fill", PQStyle.bar(PQStyle.MAGENTA))
	panel.add_child(progress)
	if GameState.in_boss:
		var thresholds: Array[float] = ROUTER_THRESHOLDS if GameState.current_world == 1 else WIFI_THRESHOLDS
		if GameState.current_world == 5:
			thresholds = MALWAREX_THRESHOLDS
		for threshold: float in thresholds:
			var marker: ColorRect = ColorRect.new()
			marker.color = Color.WHITE
			marker.position = Vector2(159 + 320 * threshold, 162)
			marker.size = Vector2(2, 22)
			panel.add_child(marker)
	subtitle("Progreso del %s: %d %%" % ["jefe" if GameState.in_boss else "nivel", int(percent)], 192)
	PQStyle.button(panel, "Reintentar", Vector2(208, 228), _retry).grab_focus()
	PQStyle.button(panel, "Menú principal", Vector2(208, 268), GameState.menu)

func _retry() -> void:
	retry.emit()
	GameState.retry()
