class_name ProjectilePool
extends Node2D

@export var player_capacity: int = 24
@export var enemy_capacity: int = 128
var player_bullets: Array[Projectile] = []
var enemy_bullets: Array[Projectile] = []

func _ready() -> void:
	add_to_group("projectile_pool")
	for index: int in range(player_capacity + enemy_capacity):
		var bullet: Projectile = Projectile.new()
		bullet.enemy = index >= player_capacity
		add_child(bullet)
		if bullet.enemy:
			enemy_bullets.append(bullet)
		else:
			player_bullets.append(bullet)

func fire(enemy: bool, at: Vector2, velocity: Vector2, damage: float = 1.0, gravity_vector: Vector2 = Vector2.ZERO) -> Projectile:
	var bullets: Array[Projectile] = enemy_bullets if enemy else player_bullets
	for bullet: Projectile in bullets:
		if not bullet.active:
			bullet.launch(at, velocity, damage, gravity_vector)
			return bullet
	return null

func clear_enemy() -> void:
	for bullet: Projectile in enemy_bullets:
		bullet.deactivate()
