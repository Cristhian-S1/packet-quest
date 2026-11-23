class_name InputLabels
extends RefCounted

static func for_action(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return for_key(InputBindings.key_code(event))
	return "Sin tecla"

static func for_key(code: Key) -> String:
	var key: Key = code
	if DisplayServer.get_name() != "headless":
		key = DisplayServer.keyboard_get_keycode_from_physical(code)
	if key == KEY_NONE:
		key = code
	match key:
		KEY_SPACE: return "Espacio"
		KEY_ESCAPE: return "Escape"
		KEY_SHIFT: return "Mayús"
		KEY_UP: return "↑"
		KEY_DOWN: return "↓"
		KEY_LEFT: return "←"
		KEY_RIGHT: return "→"
	return OS.get_keycode_string(key)

static func format_keys(pattern: String, actions: Array[StringName]) -> String:
	var keys: Array[String] = []
	for action: StringName in actions:
		keys.append(for_action(action))
	return pattern % keys

static func label_at(parent: Node, pattern: String, actions: Array[StringName], pos: Vector2,
		font_size: int, color: Color = Color.WHITE) -> Label:
	var label: Label = PQStyle.label_at(parent, format_keys(pattern, actions), pos, font_size, color)
	var refresh: Callable = func(key: String) -> void:
		if key.is_empty() or key == "bindings":
			label.text = format_keys(pattern, actions)
	GameState.settings_changed.connect(refresh)
	label.tree_exiting.connect(GameState.settings_changed.disconnect.bind(refresh), CONNECT_ONE_SHOT)
	return label

static func summary(action: StringName) -> String:
	var keys: PackedStringArray = []
	var pad: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(for_key(InputBindings.key_code(event)))
		elif event is InputEventJoypadButton:
			pad.append(_button_name(event.button_index))
		elif event is InputEventJoypadMotion:
			var arrow: String = "←" if event.axis_value < 0 else "→"
			if event.axis == JOY_AXIS_LEFT_Y:
				arrow = "↑" if event.axis_value < 0 else "↓"
			pad.append("Palanca " + arrow)
	return "%s   ·   %s" % [" / ".join(keys), " / ".join(pad) if not pad.is_empty() else "—"]

static func _button_name(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_BACK: return "Atrás"
		JOY_BUTTON_GUIDE: return "Guía"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_DPAD_UP: return "Cruceta ↑"
		JOY_BUTTON_DPAD_DOWN: return "Cruceta ↓"
		JOY_BUTTON_DPAD_LEFT: return "Cruceta ←"
		JOY_BUTTON_DPAD_RIGHT: return "Cruceta →"
	return "Botón %d" % (button + 1)
