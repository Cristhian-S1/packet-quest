class_name Projectile
extends Area2D

@export var enemy: bool = false
@export var damage: float = 1.0
@export var rolling_floor_y: float = 300.0
const MARK_BONUS: float = 1.25
## Multiplica el delta de las balas enemigas (mejora Ralentizador).
static var enemy_time_scale: float = 1.0
var homing_turn_rad: float = 0.0
var marks: bool = false
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var active: bool = false
var age: float = 0.0
var rolling: bool = false
var can_hop: bool = false
var hopped: bool = false

func _ready() -> void:
	collision_layer = 16 if enemy else 8
	collision_mask = 131 if enemy else 5
	monitoring = false
	monitorable = false
	add_child(PQStyle.box_shape(Vector2(8, 6)))
	var notifier: VisibleOnScreenNotifier2D = VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-5, -5, 10, 10)
	add_child(notifier)
	deactivate()

func launch(at: Vector2, speed: Vector2, amount: float, gravity_vector: Vector2 = Vector2.ZERO) -> void:
	global_position = at
	velocity = speed
	damage = amount
	acceleration = gravity_vector
	active = true
	age = 0.0
	rolling = false
	can_hop = false
	hopped = false
	homing_turn_rad = 0.0
	marks = false
	visible = true
	set_physics_process(true)
	queue_redraw()

func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not active:
		return
	if enemy:
		delta *= enemy_time_scale
	elif homing_turn_rad > 0.0:
		var target: Node2D = _nearest_target()
		if target != null:
			velocity = steer(velocity, target.global_position - global_position, homing_turn_rad * delta)
	age += delta
	if rolling and can_hop and not hopped and absf(global_position.x - 320.0) < 75.0:
		hopped = true
		velocity.y = -180.0
		acceleration.y = 600.0
	velocity += acceleration * delta
	var next: Vector2 = global_position + velocity * delta
	if rolling and next.y > rolling_floor_y:
		next.y = rolling_floor_y
		velocity.y = 0.0
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, next, collision_mask)
	ray.collide_with_areas = not enemy
	ray.hit_from_inside = true
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var target: Object = hit["collider"] as Object
		var amount: float = damage
		if marks and "marked" in target:
			if bool(target.get("marked")):
				amount *= MARK_BONUS
			target.set("marked", true)
		if target.has_method("receive_projectile"):
			target.call("receive_projectile", amount, global_position, velocity)
		elif target.has_method("take_damage"):
			target.call("take_damage", amount, global_position)
		deactivate()
		return
	global_position = next
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: Vector2 = camera.get_screen_center_position() if camera != null else Vector2(320, 180)
	if age > 12.0 or not Rect2(center - Vector2(348, 208), Vector2(696, 416)).has_point(global_position):
		deactivate()

## Direcciones de un abanico de `count` balas entre -angle_deg y +angle_deg.
static func spread_directions(aim: Vector2, count: int, angle_deg: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 1:
		result.append(aim)
		return result
	var spread: float = deg_to_rad(angle_deg)
	for index: int in range(count):
		result.append(aim.rotated(lerpf(-spread, spread, float(index) / float(count - 1))))
	return result

## Gira `velocity` hacia `to_target` como máximo `max_turn_rad`, conservando el módulo.
static func steer(velocity: Vector2, to_target: Vector2, max_turn_rad: float) -> Vector2:
	if to_target == Vector2.ZERO or velocity == Vector2.ZERO:
		return velocity
	var turn: float = clampf(velocity.angle_to(to_target), -max_turn_rad, max_turn_rad)
	return velocity.rotated(turn)

func _nearest_target() -> Node2D:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: Vector2 = camera.get_screen_center_position() if camera != null else Vector2(320, 180)
	var view: Rect2 = Rect2(center - Vector2(320, 180), Vector2(640, 360))
	var best: Node2D = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group("homing_target"):
		var candidate: Node2D = node as Node2D
		if candidate == null or not candidate.is_visible_in_tree() or not view.has_point(candidate.global_position):
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func _draw() -> void:
	if enemy:
		draw_rect(Rect2(-5, -4, 10, 8), PQStyle.PINK)
		draw_rect(Rect2(-2, -2, 4, 4), Color.WHITE)
	else:
		draw_line(-velocity.normalized() * 7, Vector2.ZERO, Color(PQStyle.CYAN, 0.3), 4)
		draw_rect(Rect2(-3, -2, 6, 4), PQStyle.CYAN)
