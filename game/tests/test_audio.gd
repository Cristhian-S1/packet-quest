extends RefCounted

const SFX_CATALOG: String = "res://scripts/audio/sfx_catalog.gd"
const MUSIC_CATALOG: String = "res://scripts/audio/music_catalog.gd"
const MUSIC_CACHE: String = "res://scripts/audio/music_cache.gd"
const TRACKS: Array[StringName] = [
	&"menu", &"world_1", &"world_2", &"world_3", &"world_4", &"world_5", &"boss", &"credits",
]
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
var finished: bool = false
var _main_usec: int = 0

func run(tree: SceneTree) -> PackedStringArray:
	_test_sfx()
	_test_mute()
	await _test_music_scenes(tree)
	await _test_music_render(tree)
	finished = true
	return errors

func _test_sfx() -> void:
	if not FileAccess.file_exists(SFX_CATALOG):
		errors.append("falta el catálogo de efectos procedural")
		return
	var catalog: GDScript = load(SFX_CATALOG) as GDScript
	var presets: Dictionary = catalog.get_script_constant_map()["PRESETS"]
	var worst_usec: int = 0
	var sounds: Dictionary[int, StringName] = {}
	for id: StringName in SFX:
		var start: int = Time.get_ticks_usec()
		var sound: AudioStreamWAV = catalog.render(id)
		worst_usec = maxi(worst_usec, Time.get_ticks_usec() - start)
		if sound == null:
			errors.append("falta SFX %s" % id)
			continue
		_check(sound.mix_rate == 22050 and not sound.stereo and sound.format == AudioStreamWAV.FORMAT_16_BITS, "%s debe ser PCM mono de 22 050 Hz" % id)
		var preset: Array = presets[id]
		var seconds: float = float(preset[3]) + float(preset[4]) + float(preset[5])
		_check(seconds >= 0.025 and seconds <= 0.65 and sound.data.size() == roundi(seconds * 22050) * 2,
			"%s debe respetar la duración de su envolvente" % id)
		_check(sound.data == (catalog.render(id) as AudioStreamWAV).data, "%s debe producir los mismos bytes" % id)
		var fingerprint: int = hash(sound.data)
		_check(not sounds.has(fingerprint), "%s comparte el audio de %s" % [id, sounds.get(fingerprint, &"")])
		sounds[fingerprint] = id
		AudioManager.play_sfx(id)
		_check(AudioManager.last_sfx == id, "%s debe registrarse en headless" % id)
	_check(worst_usec < 50000, "render síncrono de SFX tardó %.2f ms" % (worst_usec / 1000.0))
	print("Audio SFX, máximo en hilo principal: %.2f ms" % (worst_usec / 1000.0))

func _test_mute() -> void:
	for bus: StringName in [&"Music", &"SFX"]:
		var key: String = "%s_volume" % String(bus).to_lower()
		var index: int = AudioServer.get_bus_index(bus)
		var volume: float = GameState.settings[key]
		GameState.settings[key] = 0.0
		GameState.settings_changed.emit(key)
		_check(AudioServer.is_bus_mute(index), "%s debe quedar en silencio con volumen 0" % bus)
		GameState.settings[key] = volume
		GameState.settings_changed.emit(key)
		_check(not AudioServer.is_bus_mute(index) and is_equal_approx(AudioServer.get_bus_volume_db(index),
			linear_to_db(volume)), "%s debe recuperar el nivel anterior" % bus)

func _test_music_scenes(tree: SceneTree) -> void:
	var scenes: Dictionary[String, StringName] = {
		"res://scenes/main/Main.tscn": &"menu",
		"res://scenes/main/NetworkMap.tscn": &"menu",
		"res://scenes/ui/CreditsScreen.tscn": &"credits",
	}
	for index: int in range(GameState.WORLDS.size()):
		var world: Dictionary = GameState.WORLDS[index]
		scenes[world["level"]] = TRACKS[index + 1]
		scenes[world["boss"]] = &"boss"
	var start: int
	for path: String in scenes:
		AudioManager.set("last_music", &"")
		var scene: Node = (load(path) as PackedScene).instantiate()
		tree.root.add_child(scene)
		_check(AudioManager.get("last_music") == scenes[path], "%s debe pedir %s" % [path.get_file(), scenes[path]])
		scene.queue_free()
		await tree.process_frame
	_check(AudioManager.get_child_count() == 0, "headless no debe crear reproductores")
	start = Time.get_ticks_usec()
	AudioManager.play_music(&"menu")
	AudioManager.play_music(&"menu")
	_main_usec = Time.get_ticks_usec() - start
	GameState.current_world = 1
	GameState.in_boss = false

func _test_music_render(tree: SceneTree) -> void:
	if not FileAccess.file_exists(MUSIC_CACHE) or not FileAccess.file_exists(MUSIC_CATALOG):
		errors.append("faltan el catálogo o la caché de música procedural")
		return
	var cache: RefCounted = (load(MUSIC_CACHE) as GDScript).new() as RefCounted
	var catalog: GDScript = load(MUSIC_CATALOG) as GDScript
	var rendered: Dictionary[StringName, AudioStreamWAV] = {}
	var fingerprints: Dictionary[int, StringName] = {}
	var worker_usec: int = 0
	# Cambiar de escena mientras el primer tema se prepara prioriza la última petición.
	cache.call("request", &"menu")
	for id: StringName in TRACKS.slice(1) + [&"menu"]:
		var start: int = Time.get_ticks_usec()
		cache.call("request", id)
		_main_usec = maxi(_main_usec, Time.get_ticks_usec() - start)
		var stream: AudioStreamWAV = null
		while stream == null and Time.get_ticks_usec() - start < 5000000:
			var poll_start: int = Time.get_ticks_usec()
			stream = cache.call("poll") as AudioStreamWAV
			_main_usec = maxi(_main_usec, Time.get_ticks_usec() - poll_start)
			if stream == null:
				await tree.process_frame
				OS.delay_usec(1000)
		worker_usec = maxi(worker_usec, Time.get_ticks_usec() - start)
		if stream == null:
			errors.append("%s no se renderizó en segundo plano" % id)
			continue
		rendered[id] = stream
		var bpm: int = catalog.bpm(id)
		var frames: int = stream.data.size() / 2
		var bars: float = frames * bpm / (240.0 * stream.mix_rate)
		_check(bpm >= 120 and bpm <= 140 and absf(bars - roundf(bars)) < 0.001 and bars > 7.999 and bars < 16.001,
			"%s debe durar 8 a 16 compases a 120–140 BPM" % id)
		_check(stream.mix_rate == 22050 and stream.loop_begin == 0 and stream.loop_end == frames
			and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s debe repetir el PCM completo" % id)
		var pcm: PackedByteArray = stream.data
		_check(abs(pcm.decode_s16(0)) <= 1 and abs(pcm.decode_s16(pcm.size() - 2)) <= 1,
			"%s debe empezar y acabar cerca de cero" % id)
		var peak: int = 0
		for frame: int in range(0, frames, 97):
			peak = maxi(peak, absi(pcm.decode_s16(frame * 2)))
		_check(peak > 1000 and peak < 32000, "%s debe contener audio sin saturar" % id)
		var fingerprint: int = hash(pcm)
		_check(not fingerprints.has(fingerprint), "%s debe ser un tema distinto" % id)
		fingerprints[fingerprint] = id
	for id: StringName in rendered:
		var start: int = Time.get_ticks_usec()
		cache.call("request", id)
		var cached: AudioStreamWAV = cache.call("poll") as AudioStreamWAV
		_main_usec = maxi(_main_usec, Time.get_ticks_usec() - start)
		_check(cached == rendered[id], "%s debe reutilizar el WAV renderizado" % id)
	cache.call("close")
	_check(_main_usec < 50000, "la petición/caché bloqueó %.2f ms en hilo principal" % (_main_usec / 1000.0))
	print("Audio música, máximo en hilo principal: %.2f ms, espera máxima asíncrona: %.2f ms"
		% [_main_usec / 1000.0, worker_usec / 1000.0])

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
