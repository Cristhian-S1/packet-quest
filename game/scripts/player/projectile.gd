class_name Projectile
extends Area2D

@export var enemy: bool = false
@export var damage: float = 1.0
@export var rolling_floor_y: float = 300.0
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
		if target.has_method("receive_projectile"):
			target.call("receive_projectile", damage, global_position, velocity)
		elif target.has_method("take_damage"):
			target.call("take_damage", damage, global_position)
		deactivate()
		return
	global_position = next
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: Vector2 = camera.get_screen_center_position() if camera != null else Vector2(320, 180)
	if age > 12.0 or not Rect2(center - Vector2(348, 208), Vector2(696, 416)).has_point(global_position):
		deactivate()

func _draw() -> void:
	if enemy:
		draw_rect(Rect2(-5, -4, 10, 8), PQStyle.PINK)
		draw_rect(Rect2(-2, -2, 4, 4), Color.WHITE)
	else:
		draw_line(-velocity.normalized() * 7, Vector2.ZERO, Color(PQStyle.CYAN, 0.3), 4)
		draw_rect(Rect2(-3, -2, 6, 4), PQStyle.CYAN)
