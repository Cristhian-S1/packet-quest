class_name QosPuzzle
extends RefCounted

const PRIORITY: Array[StringName] = [&"voz", &"video", &"correo", &"descarga"]
const LABELS: Dictionary[StringName, String] = {
	&"voz": "VOZ", &"video": "VÍDEO", &"correo": "CORREO", &"descarga": "DESCARGA",
}

static func urgency(id: StringName) -> int:
	var index: int = PRIORITY.find(id)
	return PRIORITY.size() - index if index >= 0 else 0

static func is_correct_order(activated: Array[StringName]) -> bool:
	return activated == PRIORITY

static func next_expected(activated: Array[StringName]) -> StringName:
	return PRIORITY[activated.size()] if activated.size() < PRIORITY.size() else &""
