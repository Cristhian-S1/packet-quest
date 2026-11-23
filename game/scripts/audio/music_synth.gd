class_name MusicSynth
extends RefCounted

const RATE: int = 22050
const STEPS: int = 16
const REST: int = -1
const HOLD: int = -2
const HARMONIES: Array[Array] = [[0, 4, 2, 7], [2, 7, 4, 2]]
const KICKS: Array[Array] = [[0, 8], [0, 6, 10], [0, 3, 8, 11], [0, 10]]
const HATS: Array[Array] = [[2, 6, 10, 14], [2, 5, 8, 13, 15], [2, 6, 9, 13, 15], [6, 14]]

enum Voice { LEAD, HARMONY, BASS }
enum Drum { KICK, SNARE, HAT }

class Score:
	var bpm: int
	var tonic: int
	var scale: Array
	var roots: Array
	var verse: Array
	var answer: Array
	var bass: Array
	var duty: float
	var groove: int

	func _init(tempo: int, midi: int, mode: Array, chords: Array, theme: Array,
			reply: Array, bassline: Array, pulse_width: float, drum_pattern: int) -> void:
		bpm = tempo
		tonic = midi
		scale = mode
		roots = chords
		verse = theme
		answer = reply
		bass = bassline
		duty = pulse_width
		groove = drum_pattern

static func render(score: Score) -> AudioStreamWAV:
	var step_samples: float = RATE * 15.0 / score.bpm
	var frames: int = roundi(step_samples * score.roots.size() * STEPS)
	var mix: PackedFloat32Array = []
	mix.resize(frames)
	for bar: int in range(score.roots.size()):
		var chord: int = score.roots[bar]
		var first_step: int = bar * STEPS
		var melody: Array = score.answer if bar % 4 >= 2 else score.verse
		_phrase(mix, score, melody, chord, first_step, step_samples, Voice.LEAD)
		_phrase(mix, score, score.bass, chord, first_step, step_samples, Voice.BASS)
		var harmony: Array = HARMONIES[bar % HARMONIES.size()]
		for beat: int in range(harmony.size()):
			var start: int = roundi((first_step + beat * 4 + 1) * step_samples)
			var midi: int = _note(score, chord + harmony[beat]) - 12
			_tone(mix, start, roundi(step_samples * 2.7), midi, Voice.HARMONY, 0.22)
		for step: int in KICKS[score.groove]:
			_drum(mix, roundi((first_step + step) * step_samples), Drum.KICK)
		for step: int in [4, 12]:
			_drum(mix, roundi((first_step + step) * step_samples), Drum.SNARE)
		for step: int in HATS[score.groove]:
			_drum(mix, roundi((first_step + step) * step_samples), Drum.HAT)
	return _encode_loop(mix)

static func _phrase(mix: PackedFloat32Array, score: Score, notes: Array, chord: int,
		first_step: int, step_samples: float, voice: Voice) -> void:
	for beat: int in range(notes.size()):
		var degree: int = notes[beat]
		if degree < 0:
			continue
		var length: int = 1
		while beat + length < notes.size() and notes[beat + length] == HOLD:
			length += 1
		var start: int = roundi((first_step + beat * 2) * step_samples)
		var gate: float = 0.88 if voice == Voice.LEAD else 0.72
		var duration: int = roundi((length * 2.0 - (1.0 - gate)) * step_samples)
		var midi: int = _note(score, chord + degree)
		if voice == Voice.BASS:
			midi -= 24
		_tone(mix, start, duration, midi, voice, score.duty)

static func _note(score: Score, degree: int) -> int:
	return score.tonic + int(score.scale[degree % 7]) + 12 * floori(degree / 7.0)

static func _tone(mix: PackedFloat32Array, start: int, duration: int, midi: int,
		voice: Voice, duty: float) -> void:
	var increment: float = 440.0 * pow(2.0, (midi - 69) / 12.0) / RATE
	var phase: float = 0.0
	var gain: float = [0.138, 0.055, 0.185][voice]
	for offset: int in range(mini(duration, mix.size() - start)):
		var attack: float = minf(1.0, offset / 95.0)
		var tail: float = minf(1.0, (duration - 1.0 - offset) / 390.0)
		var sample: float
		if voice == Voice.BASS:
			sample = 1.0 - 4.0 * absf(phase - 0.5)
		else:
			sample = 2.0 * ((1.0 - duty) if phase < duty else -duty)
		mix[start + offset] += sample * attack * tail * gain
		phase += increment
		if phase >= 1.0:
			phase -= 1.0

static func _drum(mix: PackedFloat32Array, start: int, drum: Drum) -> void:
	var duration: int = [2400, 1580, 680][drum]
	var state: int = 2837 + start
	var phase: float = 0.0
	for offset: int in range(mini(duration, mix.size() - start)):
		var fade: float = 1.0 - float(offset) / duration
		var sample: float
		if drum == Drum.KICK:
			phase += (42.0 + fade * fade * 104.0) / RATE
			sample = sin(TAU * phase) * 0.155
		else:
			state = (state * 1664525 + 1013904223) & 0xffffffff
			var noise: float = float(state >> 16) / 32767.5 - 1.0
			sample = noise * (0.120 if drum == Drum.SNARE else 0.051)
		var attack: float = minf(1.0, offset / 35.0)
		mix[start + offset] += sample * attack * fade * fade

static func _encode_loop(mix: PackedFloat32Array) -> AudioStreamWAV:
	const EDGE_FRAMES: float = 132.0
	var pcm: PackedByteArray = []
	pcm.resize(mix.size() * 2)
	for frame: int in range(mix.size()):
		var edge: float = minf(1.0, minf(frame, mix.size() - 1 - frame) / EDGE_FRAMES)
		pcm.encode_s16(frame * 2, roundi(clampf(mix[frame] * edge, -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = mix.size()
	return stream
