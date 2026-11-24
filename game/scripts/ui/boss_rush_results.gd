class_name BossRushResults
extends PacketScreen

const BOSS_NAMES: Array[String] = ["Router", "Reina", "Firewall", "Troyano", "Malwarex"]

func _ready() -> void:
	AudioManager.play_music(&"menu")
	StageBuilder.background(self)
	super._ready()
	var defeated: int = GameState.boss_rush_defeated
	var total: int = GameState.WORLDS.size()
	var best: Dictionary = GameState.data["stats"].get("boss_rush", {})
	var complete: bool = defeated == total
	var accent: Color = PQStyle.GREEN if complete else PQStyle.AMBER
	title("BOSS RUSH", PQStyle.CYAN, 47)
	_centered("Ronda completada" if complete else "Ronda terminada", 91, 16, accent)
	for index: int in range(total):
		var x: float = 150 + index * 70
		var segment: ColorRect = ColorRect.new()
		segment.position = Vector2(x, 126)
		segment.size = Vector2(60, 5)
		segment.color = accent if index < defeated else PQStyle.CHIP
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(segment)
		var boss_name: Label = PQStyle.label_at(panel, BOSS_NAMES[index], Vector2(x, 138), 10, PQStyle.BLUE.lightened(0.3))
		boss_name.size.x = segment.size.x
		boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_centered("%d/%d jefes vencidos   ·   Tiempo %s" % [defeated, total, StageStats.format_time(GameState.boss_rush_time)],
		161, 17, Color.WHITE)
	_centered("Mejor marca   ·   %d/%d jefes   ·   Tiempo de ronda completa %s" % [
		int(best.get("best_bosses", 0)), total, StageStats.format_time(best.get("best_time_s"))],
		192, 13, PQStyle.BLUE.lightened(0.3))
	if GameState.boss_rush_record:
		var note: String = "Nuevo récord" if GameState.save_error == OK else "Nuevo récord · No se pudo guardar"
		_centered(note, 217, 13, accent)
	var retry: Button = PQStyle.button(panel, "Reintentar", Vector2(127, 263), GameState.start_boss_rush, 181)
	var map: Button = PQStyle.button(panel, "Volver al mapa", Vector2(332, 263), GameState.open_map, 181)
	retry.focus_neighbor_right = retry.get_path_to(map)
	map.focus_neighbor_left = map.get_path_to(retry)
	retry.grab_focus()

func _centered(text: String, y: float, font_size: int, color: Color) -> void:
	var label: Label = PQStyle.label_at(panel, text, Vector2(20, y), font_size, color)
	label.size.x = 600
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
