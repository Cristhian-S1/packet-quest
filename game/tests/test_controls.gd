extends RefCounted

const CONTROLS: String = "res://scenes/ui/ControlsMenu.tscn"
const OPTIONS: PackedScene = preload("res://scenes/ui/OptionsMenu.tscn")
const LEVEL: PackedScene = preload("res://scenes/levels/World1Level1.tscn")
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	var old_save: Dictionary = SaveManager.defaults()
	old_save["data_cores"] = 7
	old_save["settings"].erase("bindings")
	_check(SaveManager.save_game(old_save) == OK, "guardar partida antigua")
	GameState.restore()
	_check(GameState.data["data_cores"] == 7 and GameState.settings.get("bindings") == {},
		"cargar una partida sin bindings conserva el progreso y usa los controles de fábrica")

	if not ResourceLoader.exists(CONTROLS):
		errors.append("falta la pantalla Controles de Opciones")
		finished = true
		return errors
	var level: Node = LEVEL.instantiate()
	tree.root.add_child(level)
	tree.paused = true
	var options: Node = OPTIONS.instantiate()
	tree.root.add_child(options)
	var controls_button: Button = _button(options, "Controles")
	if controls_button == null:
		errors.append("Opciones no abre Controles")
		options.free()
		level.free()
		tree.paused = false
		finished = true
		return errors
	controls_button.pressed.emit()
	var menu: Node = options.get_node_or_null("ControlsMenu")
	if menu == null:
		errors.append("no se abrió Controles")
		options.free()
		level.free()
		tree.paused = false
		finished = true
		return errors
	var action_count: int = 0
	for property: Dictionary in ProjectSettings.get_property_list():
		var path: String = property["name"]
		if path.begins_with("input/") and not path.begins_with("input/ui_"):
			action_count += 1
			_check(_button(menu, path.get_file()) != null, "falta acción %s" % path)
	_check(action_count == 12, "doce acciones de juego disponibles")
	_joy(tree, JOY_BUTTON_DPAD_DOWN)
	_check(tree.root.gui_get_focus_owner() != _button(menu, "move_left"), "recorrer acciones con la cruceta")

	_button(menu, "shoot").pressed.emit()
	_key(tree, KEY_R)
	_check(_has_key(&"shoot", KEY_R) and not _has_key(&"shoot", KEY_J)
		and _has_key(&"shoot", KEY_X), "reasignar tecla primaria y conservar alternativa")
	_check(_has_label(level, "R dispara"), "el letrero existente muestra la tecla nueva")
	_button(menu, "shield").pressed.emit()
	_key(tree, KEY_R)
	_check(_has_key(&"shield", KEY_R) and _has_key(&"shoot", KEY_L),
		"intercambiar teclas entre acciones")
	_check(_has_label(menu, "intercambio", true), "avisar del intercambio")

	_button(menu, "shoot").pressed.emit()
	_joy(tree, JOY_BUTTON_B)
	_check(_has_joy(&"shoot", JOY_BUTTON_B) and _has_joy(&"dash", JOY_BUTTON_X),
		"intercambiar botones del mando")
	_button(menu, "shoot").pressed.emit()
	_key(tree, KEY_ESCAPE)
	_check(not _has_key(&"shoot", KEY_ESCAPE) and _has_key(&"pause", KEY_ESCAPE)
		and _has_key(&"shoot", KEY_L) and is_instance_valid(menu), "Escape cancela la captura")

	_button(menu, "aim_up").pressed.emit()
	_joy(tree, JOY_BUTTON_Y)
	_check(_has_joy(&"aim_up", JOY_BUTTON_Y) and not _has_joy(&"interact", JOY_BUTTON_Y)
		and _has_axis(&"aim_up", JOY_AXIS_LEFT_Y), "añadir botón de apuntado conserva el eje y transfiere el botón")
	_button(menu, "pause").pressed.emit()
	_key(tree, KEY_P)
	_check(_has_key(&"pause", KEY_P) and not _has_key(&"pause", KEY_ESCAPE), "reasignar pausa")
	_button(menu, "pause").pressed.emit()
	_key(tree, KEY_ESCAPE, true)
	_check(_has_key(&"pause", KEY_ESCAPE), "Mayús + Escape permite reasignar Escape a Pausa")

	var save_path: String = SaveManager.save_path
	SaveManager.save_path = save_path.path_join("inaccesible.json")
	_button(menu, "shoot").pressed.emit()
	_key(tree, KEY_T)
	_check(not _has_key(&"shoot", KEY_T) and _has_key(&"shoot", KEY_L), "fallo de guardado revierte la captura")
	SaveManager.save_path = save_path

	var saved: Dictionary = SaveManager.load_game()
	_check(saved["data_cores"] == 7 and not saved["settings"]["bindings"].is_empty(),
		"guardar controles junto al progreso")
	_button(menu, "Restaurar predeterminados").pressed.emit()
	_check(_has_key(&"shoot", KEY_J) and _has_joy(&"shoot", JOY_BUTTON_X)
		and _has_label(level, "J dispara") and SaveManager.load_game()["settings"]["bindings"] == {},
		"restaurar controles de fábrica y guardar el cambio")
	_check(SaveManager.save_game(saved) == OK, "reponer guardado con remapeo")
	GameState.restore()
	_check(_has_key(&"shoot", KEY_L) and _has_joy(&"shoot", JOY_BUTTON_B)
		and _has_label(level, "L dispara"), "cargar y aplicar teclado y mando en restore")
	saved["settings"]["bindings"]["shoot"]["keys"] = [KEY_ESCAPE]
	_check(SaveManager.save_game(saved) == OK, "guardar bindings malformados para validar")
	GameState.restore()
	_check(GameState.settings["bindings"] == {} and GameState.data["data_cores"] == 7
		and _has_key(&"shoot", KEY_J), "bindings inválidos se descartan sin perder la partida")

	_check(_button(menu, "shoot").text.contains("J") and _button(menu, "shoot").text.contains("X"),
		"la pantalla refleja las asignaciones actuales de teclado y mando")
	_key(tree, KEY_ESCAPE)
	await tree.process_frame
	_check(tree.paused and tree.root.gui_get_focus_owner() == controls_button,
		"volver a Opciones conserva la pausa y recupera el foco")
	options.free()
	level.free()
	tree.paused = false
	finished = true
	return errors

func _button(parent: Node, id: String) -> Button:
	for child: Node in parent.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button.name == id or button.text == id:
			return button
	return null

func _has_label(parent: Node, caption: String, partial: bool = false) -> bool:
	for child: Node in parent.find_children("*", "Label", true, false):
		var text: String = (child as Label).text
		if text == caption or partial and caption in text.to_lower():
			return true
	return false

func _has_key(action: StringName, code: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == code:
			return true
	return false

func _has_joy(action: StringName, index: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == index:
			return true
	return false

func _has_axis(action: StringName, axis: JoyAxis) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis:
			return true
	return false

func _key(tree: SceneTree, code: Key, shifted: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shifted
	event.pressed = true
	tree.root.push_input(event)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	tree.root.push_input(event)

func _joy(tree: SceneTree, index: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	tree.root.push_input(event)
	event = event.duplicate() as InputEventJoypadButton
	event.pressed = false
	tree.root.push_input(event)

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
