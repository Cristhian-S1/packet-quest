class_name InputBindings
extends RefCounted

const NAMES: Dictionary[StringName, String] = {
	&"move_left": "Moverse a la izquierda", &"move_right": "Moverse a la derecha",
	&"aim_up": "Apuntar arriba", &"aim_down": "Apuntar abajo", &"jump": "Saltar",
	&"shoot": "Disparar", &"dash": "Dash", &"shield": "Escudo",
	&"lock_aim": "Fijar la mira", &"interact": "Interactuar",
	&"swap_weapon": "Cambiar arma", &"pause": "Pausa",
}
const DEVICES: Array[String] = ["keys", "buttons"]

static func actions() -> Array[StringName]:
	var result: Array[StringName] = []
	for property: Dictionary in ProjectSettings.get_property_list():
		var path: String = property["name"]
		if path.begins_with("input/") and not path.begins_with("input/ui_"):
			result.append(StringName(path.trim_prefix("input/")))
	return result

static func action_name(action: StringName) -> String:
	return NAMES.get(action, String(action).capitalize())

static func defaults_for(action: StringName) -> Array:
	var config: Dictionary = ProjectSettings.get_setting("input/" + String(action))
	return config["events"]

static func defaults() -> Dictionary:
	var result: Dictionary = {}
	for action: StringName in actions():
		var keys: Array[int] = []
		var buttons: Array[int] = []
		for event: InputEvent in defaults_for(action):
			if event is InputEventKey:
				keys.append(key_code(event))
			elif event is InputEventJoypadButton:
				buttons.append(event.button_index)
		result[String(action)] = {"keys": keys, "buttons": buttons}
	return result

static func key_code(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

static func valid_code(device: String, code: int, action: String) -> bool:
	if device == "buttons":
		return code >= JOY_BUTTON_A and code < JOY_BUTTON_MAX
	return code > KEY_NONE and code < KEY_UNKNOWN and not OS.get_keycode_string(code as Key).is_empty() \
		and (code != KEY_ESCAPE or action == "pause")

## Un guardado corrupto vuelve al mapa de fábrica sin descartar los demás ajustes.
static func validated(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var base: Dictionary = defaults()
	var clean: Dictionary = {}
	for action: Variant in value:
		if not action is String or not base.has(action) or not value[action] is Dictionary:
			return {}
		var entry: Dictionary = value[action]
		if entry.size() != DEVICES.size():
			return {}
		var normalized: Dictionary = {}
		for device: String in DEVICES:
			var original: Array = base[action][device]
			var codes: Variant = entry.get(device)
			var allowed_size: int = maxi(1, original.size())
			if not codes is Array or codes.size() > allowed_size or device == "keys" and codes.size() != original.size():
				return {}
			var numbers: Array[int] = []
			for code: Variant in codes:
				if not (code is int or code is float) or not is_finite(float(code)) \
						or float(code) != floorf(float(code)) or absf(float(code)) > KEY_UNKNOWN \
						or not valid_code(device, int(code), action):
					return {}
				numbers.append(int(code))
			normalized[device] = numbers
		clean[action] = normalized
	base.merge(clean, true)
	for device: String in DEVICES:
		var used: Dictionary = {}
		for action: String in base:
			for code: int in base[action][device]:
				if used.has(code):
					return {}
				used[code] = true
	return clean

static func apply(bindings: Dictionary) -> void:
	var base: Dictionary = defaults()
	for action: StringName in actions():
		var original: Array = defaults_for(action)
		var custom: Dictionary = bindings.get(String(action), {})
		Input.action_release(action)
		InputMap.action_erase_events(action)
		var replace_keys: bool = custom.get("keys", base[String(action)]["keys"]) != base[String(action)]["keys"]
		var replace_buttons: bool = custom.get("buttons", base[String(action)]["buttons"]) != base[String(action)]["buttons"]
		for event: InputEvent in original:
			if not (event is InputEventKey and replace_keys or event is InputEventJoypadButton and replace_buttons):
				InputMap.action_add_event(action, event)
		if replace_keys:
			for code: int in custom["keys"]:
				var key: InputEventKey = InputEventKey.new()
				key.physical_keycode = code as Key
				InputMap.action_add_event(action, key)
		if replace_buttons:
			for code: int in custom["buttons"]:
				var button: InputEventJoypadButton = InputEventJoypadButton.new()
				button.device = -1
				button.button_index = code as JoyButton
				InputMap.action_add_event(action, button)
