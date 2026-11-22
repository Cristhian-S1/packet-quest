extends Node2D
## Mapa de la red: seis segmentos en línea; solo el Mundo 1 tiene contenido.

const WORLDS: Array[String] = ["Red Local", "Wi-Fi", "Firewall", "Servidor", "Nube", "Centro de datos"]
const NODE_Y: float = 150.0
var age: float = 0.0

func _ready() -> void:
	StageBuilder.background(self)
	PQStyle.label_at(self, "MAPA DE LA RED", Vector2(36, 28), 22, PQStyle.CYAN)
	PQStyle.label_at(self, "NÚCLEOS: %d" % int(GameState.data.get("data_cores", 0)), Vector2(500, 36), 12, PQStyle.AMBER)
	var unlocked: Array = GameState.data.get("unlocked_worlds", [1])
	for index: int in range(WORLDS.size()):
		var x: float = node_x(index)
		var name_label: Label = PQStyle.label_at(self, "%02d\n%s" % [index + 1, WORLDS[index]], Vector2(x - 44, NODE_Y + 22), 10)
		name_label.size.x = 88
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if index > 0:
			var status: String = "PRÓXIMAMENTE" if float(index + 1) in unlocked or (index + 1) in unlocked else "BLOQUEADO"
			var status_label: Label = PQStyle.label_at(self, status, Vector2(x - 44, NODE_Y + 56), 8, PQStyle.EDGE)
			status_label.size.x = 88
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PQStyle.button(self, "Entrar: Red Local  →", Vector2(36, 250), GameState.start_run, 240).grab_focus()
	PQStyle.button(self, "Taller", Vector2(292, 250), GameState.open_workshop, 120)
	PQStyle.button(self, "Menú", Vector2(428, 250), GameState.menu, 120)

static func node_x(index: int) -> float:
	return 70.0 + index * 100.0

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	for index: int in range(WORLDS.size()):
		var center: Vector2 = Vector2(node_x(index), NODE_Y)
		if index < WORLDS.size() - 1:
			draw_line(center + Vector2(12, 0), Vector2(node_x(index + 1) - 12, NODE_Y), PQStyle.CHIP, 2)
		var color: Color = PQStyle.GREEN if index == 0 else PQStyle.EDGE
		var pulse: float = 12.0 + (sin(age * 3.0) * 2.0 if index == 0 else 0.0)
		draw_arc(center, pulse, 0, TAU, 32, color, 2)
		draw_rect(Rect2(center - Vector2(5, 5), Vector2(10, 10)), color)
