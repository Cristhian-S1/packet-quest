extends RefCounted

const SFX_CATALOG: String = "res://scripts/audio/sfx_catalog.gd"
const SFX: Array[StringName] = [
	&"jump", &"dash", &"packet", &"triple", &"ping", &"impact", &"byte_hurt", &"death",
	&"core_collected", &"puzzle_solved", &"menu_click", &"menu_focus", &"weapon_swap",
	&"upgrade", &"cable_connected", &"firewall_connected", &"telegraph", &"boss_defeated",
	&"router_A", &"router_B", &"router_C", &"wifi_waves", &"wifi_ping", &"wifi_spiral",
	&"wifi_teleport", &"wifi_interference", &"firewall_rule", &"firewall_laser",
	&"trojan_jump", &"trojan_discharge", &"trojan_summon", &"trojan_mimics", &"malwarex_ring", &"malwarex_waves",
	&"malwarex_cables", &"malwarex_windows", &"malwarex_rule", &"malwarex_ping",
	&"malwarex_double_ring", &"malwarex_erasure",
]
var errors: PackedStringArray = []

func run(_tree: SceneTree) -> PackedStringArray:
	_test_sfx()
	return errors

func _test_sfx() -> void:
	if not FileAccess.file_exists(SFX_CATALOG):
		errors.append("falta el catálogo de efectos procedural")
		return
	var catalog: GDScript = load(SFX_CATALOG) as GDScript
	var start: int = Time.get_ticks_usec()
	var worst_usec: int = 0
	var sounds: Dictionary[int, StringName] = {}
	for id: StringName in SFX:
		start = Time.get_ticks_usec()
		var sound: AudioStreamWAV = catalog.render(id)
		worst_usec = maxi(worst_usec, Time.get_ticks_usec() - start)
		if sound == null:
			errors.append("falta SFX %s" % id)
			continue
		_check(sound.mix_rate == 22050 and not sound.stereo and sound.format == AudioStreamWAV.FORMAT_16_BITS, "%s debe ser PCM mono de 22 050 Hz" % id)
		_check(sound.get_length() >= 0.025 and sound.get_length() <= 0.65, "%s debe durar entre 25 y 650 ms" % id)
		_check(sound.data == (catalog.render(id) as AudioStreamWAV).data, "%s debe producir los mismos bytes" % id)
		var fingerprint: int = hash(sound.data)
		_check(not sounds.has(fingerprint), "%s comparte el audio de %s" % [id, sounds.get(fingerprint, &"")])
		sounds[fingerprint] = id
		AudioManager.play_sfx(id)
		_check(AudioManager.last_sfx == id, "%s debe registrarse en headless" % id)
	_check(worst_usec < 50000, "render síncrono de SFX tardó %.2f ms" % (worst_usec / 1000.0))
	print("Audio SFX, máximo en hilo principal: %.2f ms" % (worst_usec / 1000.0))

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
