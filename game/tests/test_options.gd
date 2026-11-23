extends RefCounted

const OPTIONS: String = "res://scenes/ui/OptionsMenu.tscn"
const TOGGLES: Dictionary[String, bool] = {"screen_shake": false, "reduce_flashes": true, "assist_mode": true}
var errors: PackedStringArray = []
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	_check_buses_at_restore()
	await _controls(tree)
	await _main_roundtrip(tree)
	await _pause_roundtrip(tree)
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
	AudioManager.play_sfx(&"menu_click")
	_check(AudioManager.last_sfx == &"menu_click" and AudioManager.get_child_count() == 0,
		"headless registra efectos sin crear reproductores")
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

func _main_roundtrip(tree: SceneTree) -> void:
	var main: Node = preload("res://scenes/main/Main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	var play: Button = _focused(tree) as Button
	_check(play != null and play.text.begins_with("Jugar"), "Jugar debe conservar el foco inicial")
	await _joy_tap(tree, JOY_BUTTON_DPAD_RIGHT)
	var opener: Button = _focused(tree) as Button
	if opener == null or opener.text != "Opciones":
		errors.append("el mando debe enfocar Opciones entre Jugar y Salir")
	else:
		await _tap(tree, &"ui_right")
		var exit_button: Button = _focused(tree) as Button
		_check(exit_button != null and exit_button.text == "Salir", "Salir debe quedar después de Opciones")
		await _tap(tree, &"ui_left")
		_check(_focused(tree) == opener, "Izquierda debe regresar a Opciones desde Salir")
		await _joy_tap(tree, JOY_BUTTON_A)
		await _close_options(tree, main.get_node_or_null("OptionsMenu"), opener, "menú principal")
	main.queue_free()
	await tree.process_frame

func _pause_roundtrip(tree: SceneTree) -> void:
	var world: World1Level1 = preload("res://scenes/levels/World1Level1.tscn").instantiate() as World1Level1
	tree.root.add_child(world)
	await tree.physics_frame
	await _tap(tree, &"pause")
	_check(tree.paused, "la entrada pause debe pausar el nivel")
	await _tap(tree, &"ui_down")
	var opener: Button = _focused(tree) as Button
	if opener == null or opener.text != "Opciones":
		errors.append("la pausa debe ofrecer Opciones debajo de Continuar")
	else:
		await _tap(tree, &"ui_accept")
		var menu: Node = world.find_child("OptionsMenu", true, false)
		_check(tree.paused, "abrir Opciones debe mantener la pausa")
		if menu != null:
			Events.impact.emit(0.0, 4.0)
			_check(world.player.shake_left == 0.0, "la sacudida desactivada debe ignorar impactos")
			await _tap(tree, &"ui_accept")
			Events.impact.emit(0.0, 4.0)
			_check(world.player.shake_left > 0.0, "activar la sacudida debe afectar al nivel en curso")
			world.player.camera.offset = Vector2(4, 4)
			await _tap(tree, &"ui_accept")
			_check(world.player.shake_left == 0.0 and world.player.camera.offset == Vector2.ZERO, "desactivar la sacudida debe limpiar el desplazamiento")
			await _tap(tree, &"ui_down")
			await _tap(tree, &"ui_down")
			await _tap(tree, &"ui_accept")
			_check(not bool(GameState.data["settings"]["assist_mode"]) and Engine.time_scale == 1.0, "desactivar asistencia debe restaurar la velocidad")
			_check(world.player.health.max_health == world.player.max_hp, "desactivar asistencia debe retirar el PV adicional")
			await _tap(tree, &"ui_up")
			await _tap(tree, &"ui_up")
		await _close_options(tree, menu, opener, "pausa")
		_check(tree.paused, "volver a la pausa debe mantener el juego pausado")
		await _tap(tree, &"ui_up")
		await _tap(tree, &"ui_accept")
		_check(not tree.paused, "Continuar debe reanudar después de volver")
	tree.paused = false
	world.queue_free()
	await tree.process_frame

func _close_options(tree: SceneTree, menu: Node, opener: Button, source: String) -> void:
	if menu == null:
		var focus: Button = _focused(tree) as Button
		errors.append("Opciones no se abrió desde %s; foco %s" % [source, focus.text if focus != null else str(_focused(tree))])
		return
	for index: int in range(6):
		await _tap(tree, &"ui_down")
	var back: Button = _focused(tree) as Button
	_check(back != null and back.text == "Volver", "Volver debe tener foco tras los ajustes y Controles")
	await _tap(tree, &"ui_accept")
	_check(not is_instance_valid(menu) and _focused(tree) == opener, "Volver debe cerrar Opciones y restaurar el foco")

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
