class_name PopUp
extends EnemyBase

func _draw() -> void:
	if state == State.DEAD:
		draw_bits()
		return
	var color: Color = Color.WHITE if flash > 0 and not GameState.reduce_flashes else PQStyle.MAGENTA
	draw_rect(Rect2(-10, -8, 20, 16), Color("2a0f3a"))
	draw_rect(Rect2(-10, -8, 20, 16), color, false, 1)
	var warning: Color = PQStyle.RED if GameState.reduce_flashes else (Color.WHITE if int(age * 18) % 2 == 0 else color)
	draw_rect(Rect2(-9, -7, 18, 4), warning if state == State.TELEGRAPH else color)
	draw_line(Vector2(5, -6), Vector2(7, -4), PQStyle.NIGHT, 1)
	draw_line(Vector2(7, -6), Vector2(5, -4), PQStyle.NIGHT, 1)
	draw_line(Vector2(-5, 1), Vector2(5, 1), color, 1)
	draw_line(Vector2(-5, 4), Vector2(2, 4), color, 1)
	if state == State.TELEGRAPH:
		draw_arc(Vector2.ZERO, 16 + sin(age * 20) * 2, 0, TAU, 16, PQStyle.RED, 1)
