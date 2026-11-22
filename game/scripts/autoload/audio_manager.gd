extends Node

# El prototipo usa silencio deliberado y acepta recursos ausentes.
func play_sfx(_id: StringName, stream: AudioStream = null) -> void:
	if stream == null:
		return
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.stream = stream
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func play_music(_id: StringName) -> void:
	pass
