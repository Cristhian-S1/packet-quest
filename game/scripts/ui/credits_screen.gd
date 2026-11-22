class_name CreditsScreen
extends PacketScreen

const SECONDARY_TEXT: Color = Color("9db4cd")

var _save_status: Label

static func cores_line(data: Dictionary) -> String:
	var found: Dictionary = {}
	for id: Variant in data.get("collected_cores", []):
		if String(id) in GameState.ALL_CORE_IDS:
			found[String(id)] = true
	return "Núcleos de datos: %d/%d" % [found.size(), GameState.ALL_CORE_IDS.size()]

static func format_time(seconds: float) -> String:
	var whole: int = maxi(0, floori(seconds))
	@warning_ignore("integer_division")
	var minutes: int = whole / 60
	return "%02d:%02d" % [minutes, whole % 60]

func _ready() -> void:
	StageBuilder.background(self)
	super._ready()
	var stats: Dictionary = GameState.data.get("stats", {})
	var deaths: Dictionary = stats.get("deaths", {})
	var total_deaths: int = 0
	for count: Variant in deaths.values():
		total_deaths += int(count)
	_centered("PACKET QUEST  /  LA RED ROTA", 0, 38, 640, 11, PQStyle.CYAN)
	title("INTERNET RESTAURADA", PQStyle.GREEN)
	_centered("Byte detuvo a Malwarex en el centro de datos.\nDe la red local al último servidor, los paquetes vuelven a llegar.",
		0, 119, 640, 13, SECONDARY_TEXT)
	_divider(163)
	_centered("ESTADÍSTICAS", 0, 171, 640, 11, SECONDARY_TEXT)
	_centered(cores_line(GameState.data),
		60, 191, 188, 14, PQStyle.AMBER)
	_centered("Muertes: %d" % total_deaths, 250, 191, 140, 14, Color.WHITE)
	_centered("Tiempo: %s" % format_time(float(stats.get("play_time_s", 0.0))), 392, 191, 188, 14, Color.WHITE)
	_divider(222)
	_centered("CRÉDITOS", 0, 232, 640, 11, SECONDARY_TEXT)
	_centered("Diseño, programación y arte procedural · Equipo de Packet Quest", 0, 250, 640, 12, Color.WHITE)
	PQStyle.button(panel, "Menú principal", Vector2(128, 280), GameState.menu, 180).grab_focus()
	PQStyle.button(panel, "Nueva partida", Vector2(332, 280), _new_game, 180)
	_save_status = _centered("", 0, 319, 640, 11, PQStyle.AMBER)

func _centered(text: String, x: float, y: float, width: float, font_size: int, color: Color) -> Label:
	var label: Label = PQStyle.label_at(panel, text, Vector2(x, y), font_size, color)
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _divider(y: float) -> void:
	var divider: ColorRect = ColorRect.new()
	divider.position = Vector2(64, y)
	divider.size = Vector2(512, 1)
	divider.color = PQStyle.CHIP
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

func _new_game() -> void:
	if GameState.new_game() != OK:
		_save_status.text = "No se pudo guardar la nueva partida. Vuelve a intentarlo."
