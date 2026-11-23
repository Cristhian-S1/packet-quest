class_name SfxSynth
extends RefCounted

enum Wave { SQUARE, SAW, SINE, NOISE }

const RATE: int = 22050
const EDGE_SECONDS: float = 0.003

## Slide en octavas por segundo y vibrato en fracción de octava a 18 Hz.
static func render(wave: Wave, frequency: float, slide: float, attack: float,
		sustain: float, decay: float, vibrato: float = 0.0, duty: float = 0.5) -> AudioStreamWAV:
	var frames: int = maxi(2, roundi((attack + sustain + decay) * RATE))
	var release_frame: int = roundi((attack + sustain) * RATE)
	var attack_frames: float = maxf(EDGE_SECONDS, attack) * RATE
	var decay_frames: float = maxf(EDGE_SECONDS, decay) * RATE
	var edge_frames: float = EDGE_SECONDS * RATE
	var data: PackedByteArray = []
	data.resize(frames * 2)
	var phase: float = 0.0
	var noise: int = 9377
	var current_hz: float = frequency
	var slide_step: float = pow(2.0, slide / RATE)
	for frame: int in range(frames):
		var hz: float = current_hz
		if vibrato != 0.0:
			hz *= pow(2.0, vibrato * sin(TAU * 18.0 * frame / RATE))
		phase += clampf(hz, 20.0, RATE * 0.42) / RATE
		if phase >= 1.0:
			phase -= 1.0
			noise = (noise * 1664525 + 1013904223) & 0xffffffff
		var sample: float
		match wave:
			Wave.SQUARE:
				sample = 1.0 if phase < duty else -1.0
			Wave.SAW:
				sample = 2.0 * phase - 1.0
			Wave.SINE:
				sample = sin(TAU * phase)
			Wave.NOISE:
				sample = float(noise >> 16) / 32767.5 - 1.0
		var tail: float = frames - 1.0 - frame
		var envelope: float = minf(1.0, minf(frame / attack_frames, tail / edge_frames))
		if frame >= release_frame:
			envelope = minf(envelope, tail / decay_frames)
		data.encode_s16(frame * 2, roundi(sample * envelope * 15400.0))
		current_hz *= slide_step
	var sound: AudioStreamWAV = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = RATE
	sound.data = data
	return sound
