extends RefCounted

const Motion = preload("res://scripts/art/art_motion.gd")
const SHADE: Color = Color("145976")
const MID: Color = Color("238fa8")
const GLINT: Color = Color("b7fcf5")
const RUN_FEET: Array[Vector2i] = [Vector2i(-5, 4), Vector2i(-3, 3), Vector2i(0, 1),
	Vector2i(4, -5), Vector2i(3, -3), Vector2i(1, 0)]
const DEATH_TIME: float = 0.42
const RECOIL_TIME: float = 0.10

static func frame(pose: StringName, age: float) -> int:
	match pose:
		&"idle", &"fire", &"shield":
			return Motion.frame(age, 2.0, 2)
		&"run":
			return Motion.frame(age, 10.0, 6)
		_:
			return 0

static func draw_byte(canvas: Node2D, pose: StringName, tick: int, facing: float, aim: Vector2,
		dash_direction: Vector2, recoil: float, hurt: float, protection: float,
		death_age: float, shield: bool, reduce_flashes: bool) -> void:
	if pose == &"dead":
		Motion.pixels(canvas, Vector2.ZERO, death_age / DEATH_TIME, 30.0, 16, PQStyle.CYAN, GLINT)
		return
	var offset: Vector2 = Vector2.ZERO
	var scale: Vector2 = Vector2(facing, 1.0)
	var angle: float = 0.0
	var feet: Vector2i = Vector2i(-4, 3)
	var foot_lift: Vector2i = Vector2i.ZERO
	match pose:
		&"idle", &"fire", &"shield":
			offset.y = tick
			scale.y = 1.0 - tick * 0.12
		&"run":
			feet = RUN_FEET[tick]
			offset.y = -1 if tick % 3 == 2 else 0
			foot_lift = Vector2i(1 if tick >= 3 else 0, 1 if tick < 3 else 0)
		&"jump":
			scale *= Vector2(0.86, 1.17)
			feet = Vector2i(-5, 2)
			foot_lift = Vector2i(2, 3)
		&"fall":
			scale *= Vector2(1.14, 0.83)
			feet = Vector2i(-6, 5)
		&"dash":
			scale = Vector2(1.2, 0.73)
			angle = dash_direction.angle()
			feet = Vector2i(-7, -3)
			foot_lift = Vector2i(1, 2)
		&"hurt":
			offset.x = -facing * 2
			scale *= Vector2(1.05, 0.9)
			feet = Vector2i(-6, 5)
	var tint: Color = PQStyle.CYAN.lerp(GLINT, Motion.hit_strength(hurt, reduce_flashes))
	canvas.draw_set_transform(offset, angle, scale)
	_foot(canvas, feet.x, foot_lift.x, MID)
	_foot(canvas, feet.y, foot_lift.y, tint)
	_shell(canvas, tint, pose == &"hurt")
	canvas.draw_set_transform(Vector2.ZERO)
	_cannon(canvas, aim, recoil, reduce_flashes)
	if protection > 0.0 and pose != &"dash":
		for side: float in [-1.0, 1.0]:
			canvas.draw_rect(Rect2(side * 9 - 1, -8, 2, 2), Color(PQStyle.CYAN, 0.64))
	if shield:
		_firewall(canvas, facing)

static func draw_trail(canvas: Node2D, point: Vector2, direction: Vector2, alpha: float) -> void:
	canvas.draw_set_transform(point.round(), direction.angle())
	canvas.draw_rect(Rect2(-10, -4, 18, 8), Color(SHADE, alpha))
	canvas.draw_rect(Rect2(-13, -2, 18, 4), Color(PQStyle.CYAN, alpha))
	canvas.draw_rect(Rect2(-15, 3, 4, 1), Color(GLINT, alpha))
	canvas.draw_rect(Rect2(-19, -5, 6, 1), Color(MID, alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func _shell(canvas: Node2D, tint: Color, hurt: bool) -> void:
	# La carcasa y las patas ocupan una retícula de 16 × 16 en reposo.
	canvas.draw_rect(Rect2(-5, -8, 5, 2), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-4, -8, 3, 1), GLINT)
	canvas.draw_rect(Rect2(-3, -7, 1, 2), MID)
	canvas.draw_rect(Rect2(-7, -6, 13, 13), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-8, -4, 16, 9), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-6, -5, 12, 10), SHADE)
	canvas.draw_rect(Rect2(-6, -5, 12, 6), tint)
	canvas.draw_rect(Rect2(-7, -3, 3, 7), MID)
	canvas.draw_rect(Rect2(-5, -5, 9, 1), GLINT)
	canvas.draw_rect(Rect2(-4, -3, 11, 5), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-3, -2, 8, 3), SHADE)
	canvas.draw_rect(Rect2(1, -2, 3, 2), PQStyle.RED if hurt else GLINT)
	canvas.draw_rect(Rect2(5, -2, 1, 2), tint)
	canvas.draw_rect(Rect2(-4, 3, 8, 2), MID)
	canvas.draw_rect(Rect2(-5, 3, 2, 1), GLINT)
	canvas.draw_rect(Rect2(-1, 4, 1, 1), tint)

static func _foot(canvas: Node2D, x: int, lift: int, tint: Color) -> void:
	canvas.draw_rect(Rect2(x, 4 - lift, 4, 4), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(x, 6 - lift, 3, 1), tint)

static func _cannon(canvas: Node2D, aim: Vector2, recoil: float, reduce_flashes: bool) -> void:
	var kick: float = roundf(3.0 * recoil / RECOIL_TIME)
	var origin: Vector2 = Vector2(0, 2)
	for distance: int in range(5, 13):
		var pos: Vector2 = (origin + aim * (distance - kick)).round()
		canvas.draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), PQStyle.NIGHT)
	for distance: int in range(5, 13):
		var pos: Vector2 = (origin + aim * (distance - kick)).round()
		canvas.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(3, 2)), MID if distance < 10 else PQStyle.CYAN)
	var muzzle: Vector2 = (origin + aim * (12.0 - kick)).round()
	canvas.draw_rect(Rect2(muzzle - Vector2(1, 1), Vector2(2, 2)), GLINT)
	if recoil > 0.0 and not reduce_flashes:
		var tip: Vector2 = (aim * 16.0).round()
		canvas.draw_rect(Rect2(tip - Vector2(1, 1), Vector2(2, 2)), GLINT)
		canvas.draw_rect(Rect2((tip + aim * 3.0).round(), Vector2.ONE), Color(GLINT, 0.6))

static func _firewall(canvas: Node2D, facing: float) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var contour: PackedVector2Array = [Vector2(9, -14), Vector2(13, -14), Vector2(17, -10),
		Vector2(17, -7), Vector2(20, -4), Vector2(20, 4), Vector2(17, 7),
		Vector2(17, 10), Vector2(13, 14), Vector2(9, 14)]
	canvas.draw_colored_polygon(contour, Color(PQStyle.GREEN, 0.14))
	canvas.draw_polyline(contour, PQStyle.GREEN, 2.0)
	for y: int in [-10, -4, 2, 8]:
		canvas.draw_rect(Rect2(11, y, 4, 1), Color(PQStyle.GREEN, 0.55))
	canvas.draw_set_transform(Vector2.ZERO)
