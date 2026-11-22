extends Node

## Sin assets de audio propios por arma, cada id reutiliza el tono del paquete
## con un pitch distinto para que los disparos suenen diferentes.
const SFX_PITCH: Dictionary = {
	&"packet": 1.0,
	&"triple": 0.85,
	&"ping": 1.35,
}

## Último sfx y pitch reproducidos (observable para tests y diagnóstico).
var last_sfx: StringName = &""
var last_pitch: float = 1.0

# El prototipo usa silencio deliberado y acepta recursos ausentes.
func play_sfx(id: StringName, stream: AudioStream = null) -> void:
	last_sfx = id
	last_pitch = float(SFX_PITCH.get(id, 1.0))
	if stream == null:
		return
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.stream = stream
	voice.pitch_scale = last_pitch
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func play_music(_id: StringName) -> void:
	pass
