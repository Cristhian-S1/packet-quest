extends Node

const SFX_VOICES: int = 12
const WARNING_VOICES: int = 4
const MUSIC_FADE: float = 0.28
const MUSIC_GAIN: float = 0.8

var last_sfx: StringName = &""
var last_music: StringName = &""
var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _voices: Array[AudioStreamPlayer] = []
var _warnings: Array[AudioStreamPlayer] = []
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

func _add_voices(voices: Array[AudioStreamPlayer], count: int) -> void:
	for index: int in range(count):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		voice.volume_db = -8.0
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
	last_sfx = id
	if _headless:
		return
	_play_voice(id, _warnings[_next_warning])
	_next_warning = (_next_warning + 1) % WARNING_VOICES

func play_sfx(id: StringName) -> void:
	last_sfx = id
	if _headless:
		return
	_play_voice(id, _voices[_next_voice])
	_next_voice = (_next_voice + 1) % SFX_VOICES

func _play_voice(id: StringName, voice: AudioStreamPlayer) -> void:
	if not _sounds.has(id):
		var stream: AudioStreamWAV = SfxCatalog.render(id)
		if stream == null:
			return
		_sounds[id] = stream
	voice.stream = _sounds[id]
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
