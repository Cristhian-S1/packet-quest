extends RefCounted

const OPTIONS: String = "res://scenes/ui/OptionsMenu.tscn"
const TOGGLES: Dictionary[String, bool] = {"screen_shake": false, "reduce_flashes": true, "assist_mode": true}
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_check_buses_at_restore()
	await _controls(tree)
	GameState.data = SaveManager.defaults()
	SaveManager.save_game(GameState.data)
	GameState.restore()
	finished = true
	return errors

func _check_buses_at_restore() -> void:
	GameState.data["settings"]["music_volume"] = 0.3
	GameState.data["settings"]["sfx_volume"] = 0.0
	_check(SaveManager.save_game(GameState.data) == OK, "guardar niveles para el arranque")
	GameState.restore()
	_check_bus(&"Music", 0.3)
	_check_bus(&"SFX", 0.0)
	var tone: AudioStreamWAV = AudioStreamWAV.new()
	tone.data = PackedByteArray([0, 0, 0, 0])
	AudioManager.play_sfx(&"test", tone)
	var voice: AudioStreamPlayer = AudioManager.get_child(-1) as AudioStreamPlayer
	_check(voice != null and voice.bus == &"SFX", "los efectos se reproducen en SFX")
	if voice != null:
		voice.queue_free()
	GameState.data = SaveManager.defaults()
	SaveManager.save_game(GameState.data)
	GameState.restore()

func _controls(tree: SceneTree) -> void:
	if not ResourceLoader.exists(OPTIONS):
		errors.append("falta OptionsMenu.tscn")
		return
	var menu: Node = (load(OPTIONS) as PackedScene).instantiate()
	GameState.data["data_cores"] = 5
	tree.root.add_child(menu)
	await tree.process_frame
	for key: String in TOGGLES:
		var toggle: Button = _focused(tree) as Button
		_check(toggle != null and toggle.toggle_mode, "%s no tiene foco de interruptor" % key)
		await _tap(tree, &"ui_accept")
		_check(SaveManager.load_game()["settings"][key] == TOGGLES[key], "%s debe guardarse al cambiar" % key)
		await _tap(tree, &"ui_down")
	await _slider(tree, "music_volume", &"Music", 0.8)
	await _tap(tree, &"ui_down")
	await _slider(tree, "sfx_volume", &"SFX", 0.9)
	_check(SaveManager.load_game()["data_cores"] == 5, "cambiar ajustes debe conservar el progreso")
	var path: String = SaveManager.save_path
	SaveManager.save_path = path.path_join("unwritable.json")
	await _tap(tree, &"ui_right")
	var blocked: HSlider = _focused(tree) as HSlider
	_check(GameState.save_error != OK and is_zero_approx(blocked.value), "un fallo al guardar debe revertir el control")
	_check(is_zero_approx(float(GameState.settings["sfx_volume"])), "un fallo al guardar debe revertir el ajuste en memoria")
	_check_bus(&"SFX", 0.0)
	SaveManager.save_path = path
	menu.queue_free()
	await tree.process_frame
	GameState.restore()
	menu = (load(OPTIONS) as PackedScene).instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	for key: String in TOGGLES:
		var toggle: Button = _focused(tree) as Button
		_check(toggle != null and toggle.button_pressed == TOGGLES[key], "%s debe cargarse en la interfaz" % key)
		await _tap(tree, &"ui_down")
	var music: HSlider = _focused(tree) as HSlider
	_check(music != null and is_zero_approx(music.value), "Música debe cargar el silencio guardado")
	await _tap(tree, &"ui_down")
	var sfx: HSlider = _focused(tree) as HSlider
	_check(sfx != null and is_zero_approx(sfx.value), "Efectos debe cargar el silencio guardado")
	menu.queue_free()
	await tree.process_frame

func _slider(tree: SceneTree, key: String, bus: StringName, initial: float) -> void:
	var slider: HSlider = _focused(tree) as HSlider
	if slider == null:
		errors.append("%s no tiene foco de deslizador" % key)
		return
	_check(slider.min_value == 0.0 and slider.max_value == 1.0 and is_equal_approx(slider.step, 0.1), "%s debe abarcar 0–1 en pasos de 0,1" % key)
	_check(is_equal_approx(slider.value, initial), "%s debe mostrar el valor de partida" % key)
	await _tap(tree, &"ui_right")
	_check(is_equal_approx(slider.value, initial + 0.1) and _saved_volume(key, initial + 0.1), "%s debe cambiar un paso y guardarlo" % key)
	_check_bus(bus, initial + 0.1)
	slider.value = 4.0
	await _tap(tree, &"ui_right")
	_check(slider.value == 1.0 and _saved_volume(key, 1.0), "%s debe quedar acotado a 1" % key)
	slider.value = 0.1
	await _joy_tap(tree, JOY_BUTTON_DPAD_LEFT)
	_check(is_zero_approx(slider.value), "%s debe retroceder un paso con el mando" % key)
	await _tap(tree, &"ui_left")
	slider.value = -1.0
	_check(slider.value == 0.0 and _saved_volume(key, 0.0), "%s debe quedar acotado a 0" % key)
	_check_bus(bus, 0.0)
	await _joy_tap(tree, JOY_BUTTON_DPAD_RIGHT)
	_check(is_equal_approx(slider.value, 0.1) and _saved_volume(key, 0.1), "%s debe responder al mando" % key)
	_check_bus(bus, 0.1)
	await _tap(tree, &"ui_left")

func _check_bus(bus: StringName, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index == -1:
		errors.append("falta el bus %s" % bus)
		return
	var volume: float = AudioServer.get_bus_volume_db(index)
	_check(is_finite(volume) and AudioServer.is_bus_mute(index) == is_zero_approx(value), "%s debe silenciarse solo en cero" % bus)
	if value > 0.0:
		_check(is_equal_approx(volume, linear_to_db(value)), "%s debe aplicar el volumen en dB" % bus)

func _saved_volume(key: String, expected: float) -> bool:
	return is_equal_approx(float(SaveManager.load_game()["settings"][key]), expected)

func _focused(tree: SceneTree) -> Control:
	return tree.root.gui_get_focus_owner()

func _tap(tree: SceneTree, action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	var released: InputEventAction = InputEventAction.new()
	released.action = action
	Input.parse_input_event(released)
	await tree.process_frame
	await tree.process_frame

func _joy_tap(tree: SceneTree, button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	var released: InputEventJoypadButton = InputEventJoypadButton.new()
	released.button_index = button
	Input.parse_input_event(released)
	await tree.process_frame
	await tree.process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
