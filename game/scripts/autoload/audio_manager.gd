extends Node

const SFX_VOICES: int = 12
const WARNING_VOICES: int = 4

var last_sfx: StringName = &""
var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _voices: Array[AudioStreamPlayer] = []
var _warnings: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _next_warning: int = 0
var _headless: bool

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func play_music(_id: StringName) -> void:
	pass
