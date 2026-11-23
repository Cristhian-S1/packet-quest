class_name MusicCache
extends RefCounted

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _thread: Thread
var _rendering: StringName = &""
var _requested: StringName = &""

func request(id: StringName) -> void:
	if not MusicCatalog.SCORES.has(id):
		return
	_requested = id
	_start_pending()

func poll() -> AudioStreamWAV:
	if _thread != null and not _thread.is_alive():
		_streams[_rendering] = _thread.wait_to_finish() as AudioStreamWAV
		_thread = null
		_start_pending()
	return _streams.get(_requested) as AudioStreamWAV

func is_rendering() -> bool:
	return _thread != null

func close() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

func _start_pending() -> void:
	if _thread != null or _streams.has(_requested):
		return
	_rendering = _requested
	_thread = Thread.new()
	if _thread.start(MusicCatalog.render.bind(_rendering), Thread.PRIORITY_LOW) != OK:
		_thread = null
		push_error("No se pudo iniciar el render de música: %s" % _rendering)
