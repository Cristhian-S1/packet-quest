class_name MusicCatalog
extends RefCounted

const MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const MIXOLYDIAN: Array[int] = [0, 2, 4, 5, 7, 9, 10]
const PHRYGIAN: Array[int] = [0, 1, 3, 5, 7, 8, 10]
const R: int = MusicSynth.REST
const H: int = MusicSynth.HOLD
const MALWAREX_SECTIONS: Array[StringName] = [
	&"boss_malwarex", &"boss_malwarex_cables", &"boss_malwarex_shield", &"boss_malwarex_erasure",
]

# BPM, tónica MIDI, modo, raíces de compás, motivos A/B, bajo, duty, ritmo.
# Los motivos contienen grados diatónicos por corchea. H prolonga la nota anterior.
const SCORES: Dictionary[StringName, Array] = {
	&"menu": [122, 65, MAJOR, [0, 5, 3, 4, 0, 5, 3, 4],
		[0, H, 2, 4, H, 2, 1, R], [4, H, 5, 4, 2, H, 1, R],
		[0, H, R, 4, 0, H, 7, R], 0.42, 3],
	&"world_1": [128, 62, MIXOLYDIAN, [0, 0, 3, 4, 0, 5, 6, 4],
		[0, 2, 4, R, 2, 4, 5, 4], [7, 4, 2, 1, R, 2, 4, H],
		[0, R, 0, 4, 0, R, 7, 4], 0.34, 0],
	&"world_2": [136, 66, DORIAN, [0, 6, 3, 0, 0, 3, 6, 4],
		[4, R, 7, 9, 8, H, 4, R], [2, 4, 6, R, 7, 4, 2, H],
		[0, 7, R, 0, 4, R, 0, 7], 0.23, 1],
	&"world_3": [132, 60, PHRYGIAN, [0, 1, 0, 6, 0, 3, 1, 0],
		[0, 1, 0, H, 4, 1, R, 2], [6, 4, 3, R, 1, 2, 0, H],
		[0, 0, 7, 0, 4, R, 1, 0], 0.44, 2],
	&"world_4": [124, 64, MINOR, [0, 5, 2, 6, 0, 5, 3, 4],
		[2, H, 4, 6, H, 4, 2, 1], [9, H, 7, 6, 4, R, 2, 3],
		[0, H, 4, R, 7, H, 4, 0], 0.29, 0],
	&"world_5": [134, 62, DORIAN, [0, 5, 3, 6, 0, 4, 3, 0],
		[7, 4, R, 5, 2, 4, 6, H], [9, 7, 6, 4, R, 2, 1, 0],
		[0, 4, R, 7, 0, 4, 6, R], 0.38, 1],
	&"boss_router": [134, 62, MIXOLYDIAN, [0, 0, 3, 0, 4, 3, 6, 4],
		[0, R, 4, 0, 7, H, 4, 2], [2, 3, 5, R, 7, 5, 3, H],
		[0, R, 4, 0, R, 7, 0, 4], 0.31, 0],
	&"boss_wifi_queen": [142, 66, DORIAN, [0, 3, 6, 0, 4, 3, 1, 6],
		[2, 4, 6, 9, H, 8, 6, R], [11, 9, R, 6, 7, H, 4, 2],
		[0, H, R, 7, 4, R, 7, 4], 0.17, 1],
	&"boss_firewall": [146, 61, PHRYGIAN, [0, 1, 0, 1, 3, 0, 6, 1],
		[0, 0, 1, R, 0, 0, 4, 1], [4, 4, 3, 1, 0, R, 1, 0],
		[0, 0, 0, 1, 0, 0, 7, 0], 0.44, 2],
	&"boss_trojan": [138, 67, MINOR, [0, 5, 2, 0, 3, 5, 4, 0],
		[0, H, 2, 5, H, 3, 1, H], [7, H, 5, 8, H, 6, 4, 2],
		[0, H, R, 0, H, R, 4, R], 0.26, 3],
	# Malwarex: mismo motivo de apertura y pulso en cuatro arreglos de ocho compases.
	&"boss_malwarex": [148, 64, PHRYGIAN, [0, 0, 3, 1, 0, 5, 3, 1],
		[0, 2, 1, 7, R, 4, 3, 1], [7, 5, 4, R, 3, 4, 2, 1],
		[0, R, 0, 4, 0, H, 7, 1], 0.20, 0],
	&"boss_malwarex_cables": [148, 64, PHRYGIAN, [0, 3, 0, 5, 0, 1, 4, 1],
		[0, 2, 1, 7, 6, R, 4, 2], [4, 6, 7, 9, R, 7, 4, 1],
		[0, 4, R, 7, 0, R, 4, 1], 0.16, 1],
	&"boss_malwarex_shield": [148, 64, PHRYGIAN, [0, 1, 0, 4, 0, 1, 3, 1],
		[0, 2, 1, 7, H, 4, H, 1], [1, H, 0, H, 4, R, 3, 1],
		[0, H, H, 1, 0, H, 4, H], 0.46, 3],
	&"boss_malwarex_erasure": [148, 64, PHRYGIAN, [0, 1, 0, 3, 1, 0, 1, 0],
		[0, 2, 1, 7, 8, 7, 4, 1], [9, 8, 7, 4, 3, 2, 1, 0],
		[0, 7, 1, 0, 4, 0, 7, 1], 0.21, 2],
	&"credits": [120, 64, MAJOR, [0, 4, 5, 3, 0, 2, 3, 0],
		[2, H, 4, H, 5, 4, 2, R], [7, H, 6, 4, 2, 1, 0, H],
		[0, H, H, 4, 0, H, 7, R], 0.48, 3],
}

static func bpm(id: StringName) -> int:
	return int(SCORES[id][0])

static func render(id: StringName) -> AudioStreamWAV:
	var entry: Array = SCORES[id]
	var score: MusicSynth.Score = MusicSynth.Score.new(entry[0], entry[1], entry[2],
		entry[3], entry[4], entry[5], entry[6], entry[7], entry[8])
	return MusicSynth.render(score)
