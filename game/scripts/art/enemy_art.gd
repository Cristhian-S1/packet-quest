extends RefCounted

const Motion = preload("res://scripts/art/art_motion.gd")
const SHELL: Color = Color("492348")
const SHADOW: Color = Color("25152f")
const LIGHT: Color = Color("ffb3eb")
const METAL: Color = Color("8799b8")
const STEP: Array[int] = [0, -1, -2, -1]

static func tint(flash: float, reduce_flashes: bool) -> Color:
	return PQStyle.MAGENTA.lerp(LIGHT, Motion.hit_strength(flash, reduce_flashes))

static func warning(canvas: Node2D, age: float, progress: float, half_width: float,
		reduce_flashes: bool) -> void:
	var y: float = -18.0
	var bright: Color = Color(PQStyle.RED, Motion.warning_strength(age, reduce_flashes))
	canvas.draw_rect(Rect2(-half_width - 2, y - 1, half_width * 2 + 4, 5), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-half_width, y, half_width * 2, 3), PQStyle.RED.darkened(0.63))
	canvas.draw_rect(Rect2(-half_width, y, ceilf(half_width * 2 * progress), 3), bright)
	for side: float in [-1.0, 1.0]:
		var edge: Vector2 = Vector2(side * (half_width + 4), -9)
		canvas.draw_line(edge, edge + Vector2(-side * 4, 4), bright, 2.0)
		canvas.draw_line(edge + Vector2(-side * 4, 4), edge + Vector2(0, 8), bright, 2.0)

static func popup(canvas: Node2D, pose: StringName, tick: int, ink: Color) -> void:
	var lift: int = STEP[tick] if pose != &"active" else 1
	canvas.draw_set_transform(Vector2(0, lift))
	canvas.draw_rect(Rect2(-12, -8, 24, 16), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-11, -9, 22, 16), SHELL)
	canvas.draw_rect(Rect2(-11, -8, 22, 4), PQStyle.RED if pose == &"warning" else ink)
	canvas.draw_rect(Rect2(-9, -7, 2, 1), LIGHT)
	canvas.draw_rect(Rect2(-6, -7, 2, 1), SHADOW)
	canvas.draw_line(Vector2(6, -8), Vector2(9, -5), PQStyle.NIGHT)
	canvas.draw_line(Vector2(9, -8), Vector2(6, -5), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-9, -3, 18, 8), SHADOW)
	canvas.draw_rect(Rect2(-7, -1, 3, 2), ink)
	canvas.draw_rect(Rect2(4, -1, 3, 2), ink)
	canvas.draw_rect(Rect2(-3, 2, 5 + tick, 1), METAL)
	canvas.draw_rect(Rect2(-8, 6, 16, 1), ink)
	canvas.draw_set_transform(Vector2.ZERO)

static func worm(canvas: Node2D, pose: StringName, tick: int, ink: Color, facing: float) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	for index: int in range(4):
		var x: int = index * 6 - 12
		var y: int = STEP[(tick + index) % 4]
		if pose == &"active" and index % 2 == 0:
			y -= 3
		canvas.draw_rect(Rect2(x - 1, y - 2, 9, 8), PQStyle.NIGHT)
		canvas.draw_rect(Rect2(x, y - 3, 7, 7), SHELL)
		canvas.draw_rect(Rect2(x + 1, y - 4, 5, 2), ink)
		canvas.draw_rect(Rect2(x + 1, y + 4, 2, 2), METAL)
		canvas.draw_rect(Rect2(x + 4, y, 2, 2), ink if index == 3 else LIGHT.darkened(0.32))
	canvas.draw_rect(Rect2(10, -3, 2, 1), LIGHT)
	canvas.draw_set_transform(Vector2.ZERO)
	if pose == &"warning":
		for side: int in [-1, 1]:
			canvas.draw_line(Vector2(side * 5, -9), Vector2(side * 9, -13), PQStyle.RED, 2)

static func spyware(canvas: Node2D, pose: StringName, tick: int, ink: Color, facing: float) -> void:
	var crouch: float = 2.0 if pose == &"warning" else 0.0
	var sweep: int = -3 if pose == &"active" else STEP[tick]
	canvas.draw_set_transform(Vector2(0, crouch), 0.0, Vector2(facing, 1))
	canvas.draw_rect(Rect2(-9, -5, 18, 11), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-6, -8, 13, 13), SHELL)
	canvas.draw_rect(Rect2(-4, -9, 9, 2), ink)
	canvas.draw_rect(Rect2(-5, -5, 12, 5), SHADOW)
	canvas.draw_rect(Rect2(0, -4, 5, 2), PQStyle.RED if pose == &"warning" else LIGHT)
	for side: int in [-1, 1]:
		canvas.draw_rect(Rect2(side * 8 - 2, sweep - 4, 4, 6), ink)
		canvas.draw_rect(Rect2(side * 10 - 2, sweep - 6, 4, 2), SHELL)
		canvas.draw_rect(Rect2(side * 7 - 2, 5, 4, 2), METAL)
	canvas.draw_rect(Rect2(-4, 3, 7, 2), ink)
	canvas.draw_set_transform(Vector2.ZERO)

static func trojan(canvas: Node2D, pose: StringName, tick: int, ink: Color) -> void:
	var helmet: int = -3 if pose == &"active" else STEP[tick]
	canvas.draw_rect(Rect2(-11, -8, 22, 15), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-9, -7, 18, 12), SHELL)
	canvas.draw_rect(Rect2(-10, -11 + helmet, 20, 7), PQStyle.CHIP)
	canvas.draw_rect(Rect2(-8, -12 + helmet, 16, 2), ink)
	canvas.draw_rect(Rect2(-6, -7 + helmet, 12, 3), SHADOW)
	canvas.draw_rect(Rect2(-4, -6 + helmet, 8, 1), PQStyle.RED if pose == &"warning" else ink)
	for side: int in [-1, 1]:
		canvas.draw_rect(Rect2(side * 10 - 2, -5, 4, 7), METAL)
		canvas.draw_rect(Rect2(side * 7 - 2, 5 - (tick % 2 if side == 1 else 0), 5, 3), ink)
	canvas.draw_rect(Rect2(-4, 0, 8, 4), SHADOW)
	canvas.draw_rect(Rect2(-2, 1, 4, 2), LIGHT if pose == &"active" else ink)

static func bot(canvas: Node2D, pose: StringName, tick: int, ink: Color) -> void:
	var wing: int = 5 if pose == &"warning" else 3 - STEP[tick]
	for side: int in [-1, 1]:
		canvas.draw_rect(Rect2(side * 10 - 3, -wing, 6, 9), SHADOW)
		canvas.draw_rect(Rect2(side * 13 - 2, -wing - 2, 4, 5), SHELL)
		canvas.draw_rect(Rect2(side * 13 - 2, -wing - 2, 4, 1), ink)
		canvas.draw_rect(Rect2(side * 13 - 1, 6, 2, 2 + tick % 2), METAL)
	canvas.draw_rect(Rect2(-9, -7, 18, 14), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-8, -6, 16, 12), SHELL)
	canvas.draw_rect(Rect2(-6, -7, 12, 2), ink)
	canvas.draw_rect(Rect2(-6, -3, 12, 6), SHADOW)
	var eye: Color = PQStyle.RED if pose == &"warning" else ink
	canvas.draw_rect(Rect2(-4, -2, 8, 3), eye)
	canvas.draw_rect(Rect2(-2, -2, 3, 1), LIGHT)
	canvas.draw_rect(Rect2(-5, 4, 10, 1), METAL)

static func armor(canvas: Node2D, center: Vector2, height: float, facing: float) -> void:
	var top: Vector2 = center - Vector2(3, height / 2)
	canvas.draw_rect(Rect2(top, Vector2(6, height)), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(top + Vector2(1, 1), Vector2(4, height - 2)), PQStyle.EDGE)
	canvas.draw_rect(Rect2(top + Vector2(2 + facing, 2), Vector2(1, height - 4)), METAL)
	for y: float in [3.0, height - 5.0]:
		canvas.draw_rect(Rect2(top + Vector2(2, y), Vector2(2, 2)), LIGHT)
