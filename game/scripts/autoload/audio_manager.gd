extends Node

## Sin assets de audio propios por arma, cada id reutiliza el tono del paquete
## con un pitch distinto para que los disparos suenen diferentes.
const SFX_PITCH: Dictionary = {
	&"packet": 1.0,
	&"triple": 0.85,
	&"ping": 1.35,
}
const FIREWALL_TONES: Dictionary[StringName, PackedFloat32Array] = {
	&"firewall_connected": [440.0, 587.0, 784.0],
	&"firewall_rule": [294.0, 392.0],
	&"firewall_laser": [440.0, 330.0, 220.0],
}
var _tones: Dictionary[StringName, AudioStreamWAV] = {}

## Último sfx y pitch reproducidos (observable para tests y diagnóstico).
var last_sfx: StringName = &""
var last_pitch: float = 1.0

func play_sfx(id: StringName, stream: AudioStream = null) -> void:
	last_sfx = id
	last_pitch = float(SFX_PITCH.get(id, 1.0))
	if stream == null and id in FIREWALL_TONES:
		if id not in _tones:
			_tones[id] = _synthesize(FIREWALL_TONES[id])
		stream = _tones[id]
	if stream == null:
		return
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.stream = stream
	voice.pitch_scale = last_pitch
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func _synthesize(notes: PackedFloat32Array) -> AudioStreamWAV:
	const RATE: int = 22050
	const NOTE_SAMPLES: int = 1600
	var samples: PackedByteArray = []
	samples.resize(notes.size() * NOTE_SAMPLES * 2)
	for note: int in range(notes.size()):
		for frame: int in range(NOTE_SAMPLES):
			var envelope: float = minf(frame / 100.0, 1.0 - float(frame) / NOTE_SAMPLES)
			var sample: float = sin(TAU * notes[note] * frame / RATE) * envelope
			samples.encode_s16((note * NOTE_SAMPLES + frame) * 2, int(sample * 4500))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = samples
	return stream

func play_music(_id: StringName) -> void:
	pass
