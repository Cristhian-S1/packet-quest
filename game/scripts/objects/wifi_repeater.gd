class_name WifiRepeater
extends StaticBody2D

const INTERACT_RANGE: float = 32.0
const DOME_RADIUS: float = 48.0
const DOME_TIME: float = 3.0
const RECHARGE_TIME: float = 6.0

var remaining: float = 0.0
var recharge: float = 0.0
var _player: PacketPlayer

func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 0
	collision_mask = 0
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = DOME_RADIUS
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = circle
	add_child(collider)
	_player = get_tree().get_first_node_in_group(&"player") as PacketPlayer

func interaction_radius() -> float:
	return INTERACT_RANGE

func interact() -> void:
	if remaining > 0.0 or recharge > 0.0 or not is_instance_valid(_player):
		return
	if global_position.distance_squared_to(_player.global_position) <= INTERACT_RANGE * INTERACT_RANGE:
		remaining = DOME_TIME
		# Solo las balas enemigas consultan la capa de escudos.
		collision_layer = 128
		queue_redraw()

func protects(point: Vector2) -> bool:
	return remaining > 0.0 and global_position.distance_squared_to(point) <= DOME_RADIUS * DOME_RADIUS

func _physics_process(delta: float) -> void:
	if remaining > 0.0:
		remaining = maxf(0.0, remaining - delta)
		if remaining <= 0.0:
			collision_layer = 0
			recharge = RECHARGE_TIME
		queue_redraw()
	elif recharge > 0.0:
		recharge = maxf(0.0, recharge - delta)
		queue_redraw()

func _draw() -> void:
	var color: Color = PQStyle.GREEN if recharge <= 0.0 else PQStyle.AMBER
	if remaining > 0.0:
		draw_circle(Vector2.ZERO, DOME_RADIUS, Color(PQStyle.GREEN, 0.13))
		draw_arc(Vector2.ZERO, DOME_RADIUS, PI, TAU, 32, PQStyle.GREEN, 2.0)
		draw_arc(Vector2.ZERO, DOME_RADIUS - 5, PI, PI + PI * remaining / DOME_TIME, 24, color, 2.0)
	draw_rect(Rect2(-12, -3, 24, 17), PQStyle.CHIP)
	draw_rect(Rect2(-12, -3, 24, 17), PQStyle.EDGE, false)
	draw_line(Vector2(0, -3), Vector2(0, -14), color, 2.0)
	draw_arc(Vector2(0, -14), 9, -2.4, -0.74, 10, color, 1.0)
	draw_rect(Rect2(-9, 7, 18, 3), PQStyle.NIGHT)
	draw_rect(Rect2(-9, 7, 18 * (1.0 - recharge / RECHARGE_TIME), 3), color)
	draw_string(ThemeDB.fallback_font, Vector2(-26, 34), "E REPETIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
