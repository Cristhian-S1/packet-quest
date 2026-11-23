extends RefCounted

const SFX_CATALOG: String = "res://scripts/audio/sfx_catalog.gd"
const MUSIC_CATALOG: String = "res://scripts/audio/music_catalog.gd"
const MUSIC_CACHE: String = "res://scripts/audio/music_cache.gd"
const TRACKS: Array[StringName] = [
	&"menu", &"world_1", &"world_2", &"world_3", &"world_4", &"world_5", &"credits",
]
const BOSS_TRACKS: Array[StringName] = [
	&"boss_router", &"boss_wifi_queen", &"boss_firewall", &"boss_trojan", &"boss_malwarex",
]
const MALWAREX_PHASES: Array[StringName] = [
	&"boss_malwarex", &"boss_malwarex_cables", &"boss_malwarex_shield", &"boss_malwarex_erasure",
]
const ENEMY_CUES: Dictionary[String, StringName] = {
	"PopUp": &"enemy_popup",
	"ArmoredPopUp": &"enemy_popup",
	"NetworkWorm": &"enemy_worm",
	"ArmoredWorm": &"enemy_worm",
	"Spyware": &"enemy_spyware",
	"Trojan": &"enemy_trojan",
	"BotDDoS": &"enemy_ddos",
}
const TICK: float = 1.0 / 60.0
const SFX: Array[StringName] = [
	&"jump", &"dash", &"packet", &"triple", &"ping", &"impact", &"byte_hurt", &"death",
	&"core_collected", &"puzzle_solved", &"menu_click", &"menu_focus", &"weapon_swap",
	&"upgrade", &"cable_connected", &"firewall_connected", &"boss_defeated",
	&"enemy_popup", &"enemy_worm", &"enemy_spyware", &"enemy_trojan", &"enemy_ddos",
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
	await _test_enemy_cues(tree)
	await _test_trojan_cues(tree)
	await _test_music_scenes(tree)
	await _test_malwarex_music(tree)
	await _test_music_render(tree)
	finished = true
	return errors

func _test_sfx() -> void:
	if not FileAccess.file_exists(SFX_CATALOG):
		errors.append("falta el catálogo de efectos procedural")
		return
	var catalog: GDScript = load(SFX_CATALOG) as GDScript
	var presets: Dictionary = catalog.get_script_constant_map()["PRESETS"]
	_check(presets.size() == SFX.size(), "la prueba debe incluir todos los IDs de SFX")
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

func _test_enemy_cues(tree: SceneTree) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.world_2d = World2D.new()
	tree.root.add_child(viewport)
	var player: PacketPlayer = StageBuilder.player(viewport, Vector2.ZERO)
	player.set_physics_process(false)
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(1200, 420)
	camera.zoom = Vector2(1.25, 1.25)
	viewport.add_child(camera)
	camera.make_current()
	camera.force_update_scroll()
	var to_world: Transform2D = viewport.get_canvas_transform().affine_inverse()
	var center: Vector2 = to_world * Vector2(320, 180)
	var outside: Vector2 = to_world * Vector2(674, 180)
	var margin: Vector2 = to_world * Vector2(670, 180)
	var idle_cue: StringName = &"menu_focus"
	for enemy_name: String in ENEMY_CUES:
		AudioManager._physics_process(1.0)
		var enemy: EnemyBase = _spawn_warning_enemy(viewport, player, enemy_name, center)
		AudioManager.last_sfx = idle_cue
		enemy._physics_process(TICK)
		_check(enemy.visual_pose() == &"warning" and AudioManager.last_sfx == ENEMY_CUES[enemy_name],
			"%s debe emitir %s al avisar ante la cámara" % [enemy_name, ENEMY_CUES[enemy_name]])
		AudioManager.last_sfx = idle_cue
		enemy._physics_process(TICK)
		_check(AudioManager.last_sfx == idle_cue, "%s debe avisar una vez por entrada" % enemy_name)
		enemy.queue_free()

		AudioManager._physics_process(1.0)
		enemy = _spawn_warning_enemy(viewport, player, enemy_name, outside)
		AudioManager.last_sfx = idle_cue
		enemy._physics_process(TICK)
		_check(enemy.visual_pose() == &"warning" and AudioManager.last_sfx == idle_cue,
			"%s debe avisar en silencio más allá del margen de 32 px" % enemy_name)
		enemy.queue_free()

	var edge: EnemyBase = _spawn_warning_enemy(viewport, player, "Trojan", margin)
	edge._physics_process(TICK)
	_check(AudioManager.last_sfx == &"enemy_trojan", "el margen debe incluir 30 px fuera del marco")
	edge.queue_free()

	AudioManager._physics_process(1.0)
	for index: int in range(5):
		var enemy: EnemyBase = _spawn_warning_enemy(viewport, player, "PopUp", center)
		AudioManager.last_sfx = idle_cue
		enemy._physics_process(TICK)
		var expected: StringName = &"enemy_popup" if index < 2 else idle_cue
		_check(AudioManager.last_sfx == expected, "solo dos de cinco avisos simultáneos deben sonar (%d)" % index)
		enemy.queue_free()
	AudioManager._physics_process(TICK)
	var overlapping: EnemyBase = _spawn_warning_enemy(viewport, player, "BotDDoS", center)
	overlapping._physics_process(TICK)
	_check(AudioManager.last_sfx == idle_cue, "el límite se mantiene en el siguiente fotograma")
	AudioManager.play_warning(&"router_A")
	_check(AudioManager.last_sfx == &"router_A", "el aviso de jefe debe sonar con ambas voces comunes ocupadas")
	# Después de que habrían terminado los Pop-ups, el aviso de jefe aún protege la mezcla.
	AudioManager._physics_process(0.25)
	var blocked: EnemyBase = _spawn_warning_enemy(viewport, player, "PopUp", center)
	blocked._physics_process(TICK)
	_check(AudioManager.last_sfx == &"router_A", "un aviso común debe ceder mientras suena el jefe")
	AudioManager._physics_process(1.0)
	var available: EnemyBase = _spawn_warning_enemy(viewport, player, "PopUp", center)
	available._physics_process(TICK)
	_check(AudioManager.last_sfx == &"enemy_popup", "la voz común debe quedar disponible al terminar el aviso")
	AudioManager._physics_process(1.0)
	viewport.queue_free()
	await tree.process_frame

func _spawn_warning_enemy(viewport: SubViewport, player: PacketPlayer, enemy_name: String,
		spawn: Vector2) -> EnemyBase:
	var scene: PackedScene = load("res://scenes/enemies/%s.tscn" % enemy_name) as PackedScene
	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	enemy.position = spawn
	player.position = spawn + Vector2(0, 40)
	if enemy is NetworkWorm:
		(enemy as NetworkWorm).path_width = 0.0
	viewport.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.player = player
	enemy.timer = 0.0
	if enemy is NetworkWorm:
		enemy.take_damage(1.0, spawn - Vector2(20, 0))
	return enemy

func _test_trojan_cues(tree: SceneTree) -> void:
	var boss: TrojanBoss = preload("res://scenes/bosses/TrojanBoss.tscn").instantiate() as TrojanBoss
	tree.root.add_child(boss)
	boss.set_physics_process(false)
	boss.phase = 2
	boss._begin_cycle()
	_check(AudioManager.last_sfx == &"trojan_jump", "el aviso abre el salto del Troyano")
	boss._physics_process(TrojanBoss.WARNING_TIME)
	_check(AudioManager.last_sfx == &"trojan_summon" and boss._minions.is_empty(),
		"la invocación debe avisar antes de que aparezcan los Pop-ups")
	boss._physics_process(TrojanBoss.JUMP_TIME)
	_check(AudioManager.last_sfx == &"trojan_discharge" and not boss._minions.is_empty(),
		"la descarga tiene un aviso propio al abrirse el cofre")
	boss.queue_free()
	await tree.process_frame

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
		scenes[world["boss"]] = BOSS_TRACKS[index]
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

func _test_malwarex_music(tree: SceneTree) -> void:
	var boss: MalwarexBoss = preload("res://scenes/bosses/MalwarexBoss.tscn").instantiate() as MalwarexBoss
	tree.root.add_child(boss)
	boss.set_physics_process(false)
	_check(AudioManager.last_music == MALWAREX_PHASES[0], "Malwarex debe empezar con Remezcla")
	boss._advance(boss.timer)
	for index: int in range(1, MALWAREX_PHASES.size()):
		boss.body.take_damage(50.0, Vector2.ZERO)
		_check(boss.phase == index + 1 and AudioManager.last_music == MALWAREX_PHASES[index],
			"Malwarex debe pedir %s al entrar en fase %d" % [MALWAREX_PHASES[index], index + 1])
		boss._advance(boss.timer)
		for node: NetworkNode in boss.network_nodes:
			node.interact()
	boss.queue_free()
	await tree.process_frame
	GameState.current_world = 1
	GameState.in_boss = false

func _test_music_render(tree: SceneTree) -> void:
	if not FileAccess.file_exists(MUSIC_CACHE) or not FileAccess.file_exists(MUSIC_CATALOG):
		errors.append("faltan el catálogo o la caché de música procedural")
		return
	var cache: RefCounted = (load(MUSIC_CACHE) as GDScript).new() as RefCounted
	var catalog: GDScript = load(MUSIC_CATALOG) as GDScript
	var scores: Dictionary = catalog.get_script_constant_map()["SCORES"]
	var rendered: Dictionary[StringName, AudioStreamWAV] = {}
	var fingerprints: Dictionary[int, StringName] = {}
	var boss_motifs: Array[Array] = []
	var worker_usec: int = 0
	# Cambiar de escena mientras el primer tema se prepara prioriza la última petición.
	cache.call("request", &"menu")
	for id: StringName in TRACKS.slice(1) + BOSS_TRACKS + MALWAREX_PHASES.slice(1) + [&"menu"]:
		if not scores.has(id):
			errors.append("falta el tema %s en el catálogo" % id)
			continue
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
		var boss_score: bool = String(id).begins_with("boss_")
		var min_bpm: int = 130 if boss_score else 120
		var max_bpm: int = 150 if boss_score else 140
		_check(bpm >= min_bpm and bpm <= max_bpm and absf(bars - roundf(bars)) < 0.001
			and bars > 7.999 and bars < 16.001,
			"%s debe durar 8 a 16 compases a %d–%d BPM" % [id, min_bpm, max_bpm])
		if BOSS_TRACKS.has(id):
			var motif: Array = scores[id][4]
			_check(not boss_motifs.has(motif), "%s debe tener su propio motivo melódico" % id)
			boss_motifs.append(motif)
		_check(stream.mix_rate == 22050 and stream.loop_begin == 0 and stream.loop_end == frames
			and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s debe repetir el PCM completo" % id)
		var pcm: PackedByteArray = stream.data
		var first: int = pcm.decode_s16(0)
		var last: int = pcm.decode_s16(pcm.size() - 2)
		_check(absi(first) <= 1 and absi(last) <= 1,
			"%s debe empezar y acabar cerca de cero" % id)
		_check(absi(first - last) <= 2 and absi(pcm.decode_s16(2) - first) <= 16
			and absi(last - pcm.decode_s16(pcm.size() - 4)) <= 16,
			"%s debe cruzar el empalme del bucle sin salto audible de amplitud" % id)
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
	_check(_main_usec < TICK * 1000000.0,
		"la petición/caché agotó un fotograma a 60 Hz (%.2f ms)" % (_main_usec / 1000.0))
	print("Audio música, máximo en hilo principal: %.2f ms, espera máxima asíncrona: %.2f ms"
		% [_main_usec / 1000.0, worker_usec / 1000.0])

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
