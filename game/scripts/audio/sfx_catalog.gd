class_name SfxCatalog
extends RefCounted

const SQUARE = SfxSynth.Wave.SQUARE
const SAW = SfxSynth.Wave.SAW
const SINE = SfxSynth.Wave.SINE
const NOISE = SfxSynth.Wave.NOISE

# Onda, Hz, octavas/s, ataque, sostenido, caída, vibrato, duty.
const PRESETS: Dictionary[StringName, Array] = {
	&"jump": [SQUARE, 180.0, 9.0, 0.005, 0.045, 0.09, 0.0, 0.28],
	&"dash": [NOISE, 2900.0, -13.0, 0.018, 0.055, 0.11, 0.12, 0.5],
	&"packet": [SQUARE, 620.0, -16.0, 0.003, 0.017, 0.055, 0.0, 0.25],
	&"triple": [SAW, 380.0, -12.0, 0.003, 0.034, 0.075, 0.25, 0.5],
	&"ping": [SINE, 940.0, 1.0, 0.004, 0.023, 0.13, 0.04, 0.5],
	&"impact": [NOISE, 1050.0, -18.0, 0.003, 0.01, 0.048, 0.0, 0.5],
	&"byte_hurt": [SAW, 270.0, -6.0, 0.012, 0.08, 0.11, 0.14, 0.5],
	&"death": [SQUARE, 330.0, -6.0, 0.016, 0.18, 0.36, 0.08, 0.17],
	&"core_collected": [SINE, 440.0, 5.0, 0.012, 0.10, 0.17, 0.035, 0.5],
	&"puzzle_solved": [SQUARE, 540.0, 2.5, 0.022, 0.16, 0.11, 0.07, 0.16],
	&"menu_click": [SQUARE, 850.0, -8.0, 0.003, 0.016, 0.028, 0.0, 0.13],
	&"menu_focus": [SINE, 550.0, 3.0, 0.006, 0.01, 0.038, 0.0, 0.5],
	&"weapon_swap": [SQUARE, 290.0, 8.0, 0.005, 0.032, 0.042, 0.08, 0.2],
	&"upgrade": [SINE, 480.0, 3.0, 0.016, 0.14, 0.2, 0.17, 0.5],
	&"cable_connected": [SQUARE, 440.0, 3.7, 0.012, 0.11, 0.14, 0.035, 0.16],
	&"firewall_connected": [SINE, 540.0, 3.8, 0.019, 0.12, 0.15, 0.06, 0.5],
	&"telegraph": [SQUARE, 330.0, 1.5, 0.016, 0.10, 0.074, 0.18, 0.17],
	&"boss_defeated": [SQUARE, 240.0, 3.6, 0.025, 0.26, 0.32, 0.05, 0.24],
	# Router: anillo, estampida y láser.
	&"router_A": [SINE, 390.0, 2.1, 0.016, 0.19, 0.20, 0.17, 0.5],
	&"router_B": [NOISE, 1950.0, -4.0, 0.048, 0.18, 0.13, 0.28, 0.5],
	&"router_C": [SAW, 230.0, 4.3, 0.027, 0.21, 0.13, 0.0, 0.5],
	&"wifi_waves": [SQUARE, 270.0, -1.5, 0.022, 0.20, 0.15, 0.22, 0.18],
	&"wifi_ping": [SINE, 1080.0, -3.0, 0.006, 0.19, 0.19, 0.03, 0.5],
	&"wifi_spiral": [SAW, 340.0, 1.9, 0.023, 0.15, 0.19, 0.3, 0.5],
	&"wifi_teleport": [SINE, 275.0, 8.0, 0.02, 0.15, 0.11, 0.09, 0.5],
	&"wifi_interference": [NOISE, 1300.0, 3.5, 0.07, 0.28, 0.18, 0.13, 0.5],
	&"firewall_rule": [SQUARE, 158.0, 2.0, 0.018, 0.21, 0.16, 0.24, 0.34],
	&"firewall_laser": [SAW, 562.0, -3.0, 0.057, 0.33, 0.15, 0.08, 0.5],
	&"trojan_jump": [SQUARE, 105.0, 4.8, 0.011, 0.22, 0.13, 0.07, 0.38],
	&"trojan_discharge": [NOISE, 2300.0, -6.9, 0.018, 0.24, 0.15, 0.19, 0.5],
	&"trojan_summon": [SQUARE, 910.0, -2.3, 0.008, 0.10, 0.21, 0.37, 0.14],
	&"trojan_mimics": [SINE, 445.0, -2.8, 0.013, 0.28, 0.11, 0.45, 0.5],
	&"malwarex_ring": [SAW, 298.0, 3.3, 0.022, 0.18, 0.19, 0.07, 0.5],
	&"malwarex_waves": [SQUARE, 192.0, -1.1, 0.024, 0.28, 0.13, 0.31, 0.22],
	&"malwarex_cables": [NOISE, 3700.0, -10.0, 0.045, 0.23, 0.14, 0.10, 0.5],
	&"malwarex_windows": [SINE, 770.0, 0.9, 0.017, 0.18, 0.12, 0.08, 0.5],
	&"malwarex_rule": [SQUARE, 120.0, 2.5, 0.04, 0.31, 0.17, 0.09, 0.34],
	&"malwarex_ping": [SINE, 1470.0, -4.5, 0.010, 0.11, 0.33, 0.10, 0.5],
	&"malwarex_double_ring": [SAW, 200.0, 2.9, 0.023, 0.26, 0.19, 0.39, 0.5],
	&"malwarex_erasure": [SQUARE, 310.0, -5.1, 0.018, 0.32, 0.17, 0.23, 0.35],
}

static func render(id: StringName) -> AudioStreamWAV:
	if not PRESETS.has(id):
		return null
	var p: Array = PRESETS[id]
	return SfxSynth.render(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7])
