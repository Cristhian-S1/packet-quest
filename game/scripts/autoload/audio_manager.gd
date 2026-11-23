extends Node

const SFX_VOICES: int = 12
const WARNING_VOICES: int = 4
const ENEMY_WARNING_VOICES: int = 2
const MUSIC_FADE: float = 0.28
const MUSIC_GAIN: float = 0.8

var last_sfx: StringName = &""
var last_music: StringName = &""
var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _voices: Array[AudioStreamPlayer] = []
var _warnings: Array[AudioStreamPlayer] = []
var _enemy_warnings: Array[AudioStreamPlayer] = []
var _enemy_warning_remaining: PackedFloat32Array = []
var _boss_warning_remaining: float = 0.0
var _next_voice: int = 0
var _next_warning: int = 0
var _headless: bool
var _music_cache: MusicCache
var _music_players: Array[AudioStreamPlayer] = []
var _active_player: int = -1
var _playing_music: StringName = &""
var _music_fade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_physics_process(false)
	_enemy_warning_remaining.resize(ENEMY_WARNING_VOICES)
	_headless = DisplayServer.get_name() == "headless"
	GameState.settings_changed.connect(_apply_settings)
	Events.player_died.connect(play_sfx.bind(&"death"))
	Events.core_collected.connect(func(_id: StringName) -> void: play_sfx(&"core_collected"))
	Events.puzzle_solved.connect(_puzzle_solved)
	Events.boss_defeated.connect(func(_id: StringName) -> void: play_sfx(&"boss_defeated"))
	_apply_settings("")
	if not _headless:
		_add_voices(_voices, SFX_VOICES)
		_add_voices(_warnings, WARNING_VOICES)
		_add_voices(_enemy_warnings, ENEMY_WARNING_VOICES, -12.0)
		_music_cache = MusicCache.new()
		for index: int in range(2):
			var player: AudioStreamPlayer = AudioStreamPlayer.new()
			player.bus = &"Music"
			player.volume_linear = 0.0
			add_child(player)
			_music_players.append(player)

func _exit_tree() -> void:
	if _music_cache != null:
		_music_cache.close()

func _apply_settings(key: String) -> void:
	if key.is_empty() or key == "music_volume":
		_set_volume(&"Music", float(GameState.settings["music_volume"]))
	if key.is_empty() or key == "sfx_volume":
		_set_volume(&"SFX", float(GameState.settings["sfx_volume"]))

func _set_volume(bus: StringName, volume: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if volume <= 0.0:
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
		AudioServer.set_bus_mute(index, false)

func _add_voices(voices: Array[AudioStreamPlayer], count: int, gain_db: float = -8.0) -> void:
	for index: int in range(count):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		voice.volume_db = gain_db
		add_child(voice)
		voices.append(voice)

func _puzzle_solved(id: StringName) -> void:
	match id:
		&"w1_route":
			play_sfx(&"puzzle_solved")
		&"w3_firewall":
			play_sfx(&"firewall_connected")
		_:
			play_sfx(&"cable_connected")

func play_warning(id: StringName) -> void:
	var stream: AudioStreamWAV = _sound(id)
	if stream == null:
		return
	# Un jefe interrumpe los avisos comunes y conserva su propio banco de voces.
	_enemy_warning_remaining.fill(0.0)
	_boss_warning_remaining = maxf(_boss_warning_remaining, stream.get_length())
	set_physics_process(true)
	last_sfx = id
	if _headless:
		return
	for voice: AudioStreamPlayer in _enemy_warnings:
		voice.stop()
	_play_voice(stream, _warnings[_next_warning])
	_next_warning = (_next_warning + 1) % WARNING_VOICES

func play_enemy_warning(id: StringName) -> void:
	if _boss_warning_remaining > 0.0:
		return
	var slot: int = _enemy_warning_remaining.find(0.0)
	if slot == -1:
		return
	var stream: AudioStreamWAV = _sound(id)
	if stream == null:
		return
	_enemy_warning_remaining[slot] = stream.get_length()
	set_physics_process(true)
	last_sfx = id
	if not _headless:
		_play_voice(stream, _enemy_warnings[slot])

func _physics_process(delta: float) -> void:
	_boss_warning_remaining = maxf(0.0, _boss_warning_remaining - delta)
	var has_warning: bool = _boss_warning_remaining > 0.0
	for slot: int in range(ENEMY_WARNING_VOICES):
		_enemy_warning_remaining[slot] = maxf(0.0, _enemy_warning_remaining[slot] - delta)
		has_warning = has_warning or _enemy_warning_remaining[slot] > 0.0
	if not has_warning:
		set_physics_process(false)

func play_sfx(id: StringName) -> void:
	last_sfx = id
	if _headless:
		return
	var stream: AudioStreamWAV = _sound(id)
	if stream == null:
		return
	_play_voice(stream, _voices[_next_voice])
	_next_voice = (_next_voice + 1) % SFX_VOICES

func _sound(id: StringName) -> AudioStreamWAV:
	if not _sounds.has(id):
		var stream: AudioStreamWAV = SfxCatalog.render(id)
		if stream == null:
			return null
		_sounds[id] = stream
	return _sounds[id]

func _play_voice(stream: AudioStreamWAV, voice: AudioStreamPlayer) -> void:
	voice.stream = stream
	voice.play()

func play_music(id: StringName) -> void:
	if id == last_music or not MusicCatalog.SCORES.has(id):
		return
	last_music = id
	if not _headless:
		_music_cache.request(id)
		set_process(true)

func _process(_delta: float) -> void:
	var stream: AudioStreamWAV = _music_cache.poll()
	if stream != null and last_music != _playing_music:
		var spare: int = 0 if _active_player == -1 else 1 - _active_player
		var incoming: AudioStreamPlayer = _music_players[spare]
		# En un tercer cambio rápido, conserva el fundido en curso hasta liberar una voz.
		if _music_fade == null or not _music_fade.is_running() or incoming.stream == stream:
			_crossfade(stream, spare)
	if last_music == _playing_music and not _music_cache.is_rendering():
		set_process(false)

func _crossfade(stream: AudioStreamWAV, spare: int) -> void:
	if _music_fade != null:
		_music_fade.kill()
	var incoming: AudioStreamPlayer = _music_players[spare]
	if not incoming.playing or incoming.stream != stream:
		incoming.stream = stream
		incoming.volume_linear = 0.0
		incoming.play()
	_music_fade = create_tween().set_parallel().set_ignore_time_scale(true)
	_music_fade.tween_property(incoming, "volume_linear", MUSIC_GAIN, MUSIC_FADE)
	if _active_player != -1:
		var outgoing: AudioStreamPlayer = _music_players[_active_player]
		_music_fade.tween_property(outgoing, "volume_linear", 0.0, MUSIC_FADE)
		_music_fade.chain().tween_callback(outgoing.stop)
	_active_player = spare
	_playing_music = last_music
