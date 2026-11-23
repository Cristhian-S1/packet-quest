extends RefCounted

static func frame(age: float, frames_per_second: float, count: int) -> int:
	return posmod(floori(age * frames_per_second), count)

static func hit_strength(remaining: float, reduce_flashes: bool) -> float:
	return 0.0 if reduce_flashes else clampf(remaining * 14.0, 0.0, 0.32)

static func warning_strength(age: float, reduce_flashes: bool) -> float:
	return 0.82 if reduce_flashes else 0.82 + sin(age * TAU * 1.5) * 0.14

## Los fragmentos se calculan desde el tiempo y el índice, sin RNG ni nodos.
static func pixels(canvas: Node2D, center: Vector2, progress: float, spread: float,
		count: int, ink: Color, light: Color) -> void:
	if progress >= 1.0:
		return
	var t: float = clampf(progress, 0.0, 1.0)
	for index: int in range(count):
		var direction: Vector2 = Vector2.from_angle(TAU * index / count)
		var length: float = spread * (0.45 + (index * 7 % 11) * 0.05)
		var drift: Vector2 = direction * lerpf(4.0, length, 1.0 - (1.0 - t) ** 2)
		drift.y += t * t * spread * 0.16
		var width: int = maxi(1, (3 if index % 3 == 0 else 2) - int(t * 2.0))
		var color: Color = light if index % 4 == 0 else ink
		canvas.draw_rect(Rect2((center + drift).round(), Vector2(width, width)),
			Color(color, 1.0 - t * t))
