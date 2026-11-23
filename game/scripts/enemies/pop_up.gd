class_name PopUp
extends EnemyBase

const APPEAR_TIME: float = 0.18

var _appeared: bool = false

func _ready() -> void:
	super._ready()
	_warning_sfx = &"enemy_popup"
	self_modulate.a = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if on_screen and not _appeared and state != State.DEAD:
		_appeared = true
		self_modulate.a = 0.25
		var opening: Tween = create_tween().set_ignore_time_scale(true)
		opening.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		opening.tween_property(self, "self_modulate:a", 1.0, APPEAR_TIME)

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	EnemyArt.popup(self, visual_pose(), visual_frame(), art_tint())
	if state == State.TELEGRAPH:
		draw_warning(10.0)
