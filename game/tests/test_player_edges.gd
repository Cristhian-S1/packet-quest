extends RefCounted

var finished: bool = false
var errors: PackedStringArray = []

func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)

func run(tree: SceneTree) -> PackedStringArray:
	var player: PacketPlayer = PacketPlayer.new()
	tree.root.add_child(player)
	player.set_physics_process(false)
	player.shield_active = true
	player._update_shield(0.5)
	check(is_equal_approx(player.shield_meter, 80.0), "escudo consume 40 por segundo")
	player.receive_projectile(1, Vector2(10, 0), Vector2.LEFT)
	check(is_equal_approx(player.shield_meter, 65.0), "bloqueo cuesta 15")
	check(player.health.current == 3, "bloqueo frontal evita daño")
	player.receive_projectile(1, Vector2(-10, 0), Vector2.RIGHT)
	check(player.health.current == 2, "proyectil posterior causa daño")
	check(player.shield_meter == 65, "impacto posterior no consume escudo")
	player.invulnerability = 0
	player.hurt_left = 0
	player.shield_active = true
	player.shield_meter = 15
	player.receive_projectile(1, Vector2(10, 0), Vector2.LEFT)
	check(player.shield_meter == 0 and not player.shield_active, "escudo se rompe al agotarse")
	check(is_equal_approx(player.shield_broken, 2.0), "rotura dura dos segundos")
	player._physics_process(1.0)
	check(is_equal_approx(player.shield_broken, 1.0), "rotura cuenta tiempo")
	player._physics_process(1.0)
	check(is_zero_approx(player.shield_broken), "rotura termina tras dos segundos")
	check(is_equal_approx(player.dash_distance, 72.0), "dash de 72 px")
	check(is_equal_approx(player.dash_iframes, 0.15), "invulnerabilidad de dash 0,15 s")
	check(is_equal_approx(player.dash_cooldown, 0.6), "enfriamiento de dash 0,6 s")
	check(is_equal_approx(player.coyote_time, 0.1), "coyote 0,10 s")
	check(is_equal_approx(player.jump_buffer, 0.1), "buffer 0,10 s")
	player.free()
	finished = true
	return errors
