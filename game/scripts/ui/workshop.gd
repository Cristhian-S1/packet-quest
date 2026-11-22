extends PacketScreen
## Taller de Mejoras: comprar con núcleos de datos y equipar armas/pasiva.

const ROW_Y: float = 64.0
const ROW_STEP: float = 30.0
var rows: Array[Button] = []
var cores_label: Label
var description: Label

func _ready() -> void:
	super._ready()
	PQStyle.label_at(panel, "TALLER DE MEJORAS", Vector2(120, 22), 22, PQStyle.CYAN)
	cores_label = PQStyle.label_at(panel, "", Vector2(420, 30), 12, PQStyle.AMBER)
	for item: UpgradeData in Catalog.upgrades():
		var row: Button = _row_button(Vector2(120, ROW_Y + rows.size() * ROW_STEP))
		row.pressed.connect(_press.bind(item.id))
		row.focus_entered.connect(_describe.bind(item))
		row.mouse_entered.connect(_describe.bind(item))
		rows.append(row)
	description = PQStyle.label_at(panel, "", Vector2(120, 278), 11, PQStyle.EDGE)
	description.size.x = 400
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PQStyle.button(panel, "Volver al mapa", Vector2(208, 316), GameState.open_map)
	_refresh()
	if not rows.is_empty():
		rows[0].grab_focus()

func _row_button(pos: Vector2) -> Button:
	var button: Button = Button.new()
	button.position = pos
	button.size = Vector2(400, 26)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 12)
	for state: String in ["normal", "hover", "focus", "pressed"]:
		var style: StyleBoxFlat = PQStyle.panel(PQStyle.CHIP if state in ["hover", "focus"] else PQStyle.BOARD,
			PQStyle.CYAN if state in ["hover", "focus"] else PQStyle.EDGE)
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		button.add_theme_stylebox_override(state, style)
	panel.add_child(button)
	return button

## Estado mostrado en la fila: Comprar, Sin núcleos, Instalada, Equipada o Equipar.
static func status(data: Dictionary, item: UpgradeData) -> String:
	if not Progression.owns(data, item.id):
		return "Comprar" if Progression.can_buy(data, item.id) else "Sin núcleos"
	match item.kind:
		UpgradeData.Kind.PERMANENT:
			return "Instalada"
		UpgradeData.Kind.WEAPON:
			return "Equipada" if item.id in Progression.equipped_weapons(data) else "Equipar"
		_:
			return "Equipada" if Progression.has_effect(data, item.id) else "Equipar"

func _press(id: StringName) -> void:
	var data: Dictionary = GameState.data
	var item: UpgradeData = Catalog.upgrade(id)
	var changed: bool = false
	if not Progression.owns(data, id):
		changed = Progression.buy(data, id)
	elif item.kind == UpgradeData.Kind.WEAPON:
		changed = Progression.toggle_weapon(data, id)
	elif item.kind == UpgradeData.Kind.PASSIVE:
		changed = Progression.set_passive(data, &"" if Progression.has_effect(data, id) else id)
	if changed:
		GameState.save()
		AudioManager.play_sfx(&"upgrade")
	_refresh()

func _describe(item: UpgradeData) -> void:
	description.text = item.description

func _refresh() -> void:
	var data: Dictionary = GameState.data
	cores_label.text = "NÚCLEOS: %d" % int(data.get("data_cores", 0))
	var items: Array[UpgradeData] = Catalog.upgrades()
	for index: int in range(rows.size()):
		var item: UpgradeData = items[index]
		rows[index].text = "%s  ·  %d  ·  %s" % [item.display_name, item.cost, status(data, item)]
