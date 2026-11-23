extends RefCounted

const Motion = preload("res://scripts/art/art_motion.gd")
const STEEL: Color = Color("263950")
const BEVEL: Color = Color("58718e")
const PCB: Color = Color("1b273b")
const RESTORE_TIME: float = 0.6

static func restoration_stage(elapsed: float) -> int:
	return clampi(floori((elapsed - 0.10) / 0.13), 0, 3)

static func show_restoration(card: Label, text: String = "SEGMENTO RESTAURADO") -> void:
	card.text = text
	card.position.y = 102.0
	card.modulate = PQStyle.GREEN
	card.show()

static func restored(canvas: Node2D, center: Vector2, elapsed: float, phase_ink: Color,
		reduce_flashes: bool) -> void:
	if elapsed >= RESTORE_TIME:
		return
	var progress: float = elapsed / RESTORE_TIME
	Motion.pixels(canvas, center, progress, 118.0, 30 if not reduce_flashes else 18,
		phase_ink, PQStyle.GREEN)
	# El frente de la explosión se expande y pierde intensidad una sola vez.
	var radius: float = lerpf(10.0, 70.0, progress)
	var wave: PackedVector2Array = [center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)]
	canvas.draw_polyline(wave, Color(PQStyle.GREEN, 0.65 * (1.0 - progress)), 2.0)
	var width: float = floorf(190.0 * minf(elapsed / 0.13, 1.0))
	canvas.draw_rect(Rect2(320 - width, 97, 2 * width, 49), Color(PQStyle.NIGHT, 0.93))
	canvas.draw_rect(Rect2(320 - width, 97, 2 * width, 49), BEVEL, false)
	var active: int = restoration_stage(elapsed)
	for index: int in range(3):
		var x: float = 290 + index * 30
		if index < 2:
			canvas.draw_rect(Rect2(x + 4, 136, 26, 2), PQStyle.GREEN.darkened(0.63))
			var charge: float = clampf((elapsed - (0.23 + 0.13 * index)) / 0.13, 0.0, 1.0)
			canvas.draw_rect(Rect2(x + 4, 136, floorf(charge * 26.0), 2), PQStyle.GREEN)
		canvas.draw_rect(Rect2(x - 3, 134, 7, 6), PQStyle.GREEN if index < active else BEVEL)

static func router(canvas: Node2D, center: Vector2, phase: int, age: float, flash: float,
		reduce_flashes: bool) -> void:
	var ink: Color = PQStyle.GREEN if phase == 0 else PQStyle.RED
	var shell: Color = STEEL.lerp(ink, Motion.hit_strength(flash, reduce_flashes))
	var tick: int = Motion.frame(age, 5.0, 8)
	canvas.draw_set_transform(center)
	canvas.draw_rect(Rect2(-80, -41, 160, 81), PQStyle.NIGHT)
	canvas.draw_rect(Rect2(-74, -49, 148, 98), BEVEL)
	canvas.draw_rect(Rect2(-77, -44, 154, 88), shell)
	canvas.draw_rect(Rect2(-73, -39, 146, 75), PCB)
	canvas.draw_rect(Rect2(-70, -34, 140, 4), STEEL)
	for side: float in [-1.0, 1.0]:
		for index: int in range(2):
			var x: float = side * (24 + index * 35)
			var tip: Vector2 = Vector2(x + side * (7 + phase * 4), -73 + index * 5 + (tick + index) % 3)
			canvas.draw_line(Vector2(x, -48), tip, PQStyle.NIGHT, 7)
			canvas.draw_line(Vector2(x, -48), tip, BEVEL, 3)
			canvas.draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)), ink)
		var eye_x: float = -55 if side < 0 else 23
		canvas.draw_rect(Rect2(eye_x, -23, 32, 19), PQStyle.NIGHT)
		canvas.draw_rect(Rect2(eye_x + 4, -20 + phase * 2, 24, 6 + phase * 2), ink)
		canvas.draw_rect(Rect2(eye_x + 7, -19 + phase * 2, 9, 2), ink.lightened(0.43))
		var vent_x: float = -66 if side < 0 else 49
		for slat: int in range(4):
			canvas.draw_rect(Rect2(vent_x, 5 + slat * 5, 17, 2), BEVEL.darkened(0.35))
	canvas.draw_rect(Rect2(-36, 5, 72, 27), PQStyle.NIGHT)
	for index: int in range(6):
		var x: float = -31 + index * 11
		canvas.draw_rect(Rect2(x, 10, 8, 12), STEEL)
		canvas.draw_rect(Rect2(x + 2, 16, 4, 4), PQStyle.NIGHT)
		canvas.draw_rect(Rect2(x + 1, 25, 6, 2), ink if tick % 6 == index else BEVEL)
	for index: int in range(8):
		canvas.draw_rect(Rect2(-61 + index * 16, 39, 9, 2), ink if index <= tick else BEVEL)
	canvas.draw_set_transform(Vector2.ZERO)
