extends SceneTree

const TRACKS: Array[StringName] = [&"menu", &"world_2", &"boss", &"credits"]
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
	for id: StringName in EFFECTS:
		if not _save(SfxCatalog.render(id), folder.path_join("sfx_%s.wav" % id)):
			quit(1)
			return
	quit()

func _save(stream: AudioStreamWAV, path: String) -> bool:
	var result: Error = stream.save_to_wav(path)
	if result != OK:
		push_error("No se pudo guardar %s: %s" % [path, error_string(result)])
		return false
	print(path.get_file())
	return true
