extends SceneTree

const TRACKS: Array[StringName] = [
	&"menu", &"world_2", &"credits",
	&"boss_router", &"boss_wifi_queen", &"boss_firewall", &"boss_trojan",
]
const EFFECTS: Array[StringName] = [&"jump", &"dash", &"ping", &"core_collected", &"wifi_interference", &"malwarex_erasure"]

func _initialize() -> void:
	var folder: String = ProjectSettings.globalize_path("res://../docs/audio").simplify_path()
	var result: Error = DirAccess.make_dir_recursive_absolute(folder)
	if result != OK:
		push_error("No se pudo crear %s: %s" % [folder, error_string(result)])
		quit(1)
		return
	for id: StringName in TRACKS:
		if not _save(MusicCatalog.render(id), folder.path_join("music_%s.wav" % id)):
			quit(1)
			return
	if not _save(_malwarex_medley(), folder.path_join("music_boss_malwarex.wav")):
		quit(1)
		return
	for id: StringName in EFFECTS:
		if not _save(SfxCatalog.render(id), folder.path_join("sfx_%s.wav" % id)):
			quit(1)
			return
	quit()

func _malwarex_medley() -> AudioStreamWAV:
	var medley: AudioStreamWAV = MusicCatalog.render(MusicCatalog.MALWAREX_SECTIONS[0])
	var pcm: PackedByteArray = medley.data
	for id: StringName in MusicCatalog.MALWAREX_SECTIONS.slice(1):
		pcm.append_array(MusicCatalog.render(id).data)
	medley.data = pcm
	medley.loop_end = pcm.size() >> 1
	return medley

func _save(stream: AudioStreamWAV, path: String) -> bool:
	var result: Error = stream.save_to_wav(path)
	if result != OK:
		push_error("No se pudo guardar %s: %s" % [path, error_string(result)])
		return false
	print(path.get_file())
	return true
