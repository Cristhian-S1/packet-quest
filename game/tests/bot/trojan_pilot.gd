extends RefCounted

static func fight(tree: SceneTree, boss: TrojanBoss) -> bool:
	var player: PacketPlayer = boss.player
	var elapsed := 0
	var last_hp := player.health.current
	var jump_left := 0
	var dash_left := 0
	while boss.get(&"_state") != TrojanBoss.State.DEFEATED and player.health.current > 0.0 and elapsed < 18000:
		await tree.physics_frame
		elapsed += 1
		if player.health.current < last_hp:
			print("Troyano frame %d Byte %s PV %.0f jefe %.0f fase %d" % [elapsed, player.position, player.health.current, boss.health.current, boss.phase])
			last_hp = player.health.current
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release(&"jump")
		if dash_left > 0:
			dash_left -= 1
			if dash_left == 0:
				Input.action_release(&"dash")
		var danger := false
		var low := false
		for bullet: Projectile in boss.pool.enemy_bullets:
			if not bullet.active:
				continue
			for tick: int in range(1, 13):
				var future: Vector2 = bullet.global_position + bullet.velocity * (tick / 60.0)
				if absf(future.x - player.position.x) < 9.0 and absf(future.y - player.position.y) < 10.0:
					danger = true
					low = absf(bullet.velocity.y) < 1.0 and bullet.position.y > 280.0
					break
			if danger:
				break
		Input.action_release(&"lock_aim")
		Input.action_release(&"shoot")
		if danger and low and player.is_on_floor() and jump_left == 0:
			Input.action_press(&"jump")
			jump_left = 35
		elif danger and jump_left == 0 and player.is_on_floor() and player.cooldown <= 0.0 and not player.air_dash_used and dash_left == 0:
			Input.action_release(&"move_right")
			Input.action_press(&"move_left")
			Input.action_press(&"dash")
			dash_left = 2
		elif dash_left == 0:
			if player.position.x < 58.0:
				Input.action_release(&"move_left")
				Input.action_press(&"move_right")
			elif player.position.x > 72.0:
				Input.action_release(&"move_right")
				Input.action_press(&"move_left")
			else:
				Input.action_release(&"move_left")
				Input.action_press(&"move_right")
				Input.action_press(&"lock_aim")
				if not danger and jump_left == 0:
					Input.action_press(&"shoot")
	var won: bool = boss.get(&"_state") == TrojanBoss.State.DEFEATED
	if not won:
		print("Troyano FAIL frame %d jefe %.0f fase %d Byte %s PV %.0f" % [elapsed, boss.health.current, boss.phase, player.position, player.health.current])
	return won
