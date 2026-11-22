class_name PasswordSlot
extends NetworkNode

const SYMBOLS: Array[String] = ["▲", "●", "★", "■"]

var symbol: PasswordLogic.Symbol
var accepted: bool = false

func _draw() -> void:
	var tint: Color = PQStyle.GREEN if accepted else (PQStyle.CYAN if nearby else PQStyle.EDGE)
	var panel: Rect2 = Rect2(-24, -34, 48, 36)
	draw_rect(panel, PQStyle.NIGHT)
	draw_rect(panel, tint, false, 2.0)
	draw_rect(Rect2(-20, -30, 40, 28), PQStyle.CHIP)
	draw_string(ThemeDB.fallback_font, Vector2(-20, -10), SYMBOLS[symbol], HORIZONTAL_ALIGNMENT_CENTER, 40, 22, tint)
	if nearby and not accepted:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -42), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
