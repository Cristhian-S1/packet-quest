extends RefCounted

static func fight(tree: SceneTree, queen: WifiQueenBoss) -> bool:
	var player: PacketPlayer = queen.player
	var guard := 0
	var previous_health: float = player.health.current
	var jump_left := 0
	var jump_x := 0.0
	var dash_pressed := false
	var ping_until := 0
	var ping_target := 0.0
	var previous_state: int = -1
	var previous_phase := 0
	while queen.state != WifiQueenBoss.State.DEFEATED and player.health.current > 0.0 and guard < 12000:
		await tree.physics_frame
		guard += 1
		if queen.phase != previous_phase:
			print("Reina fase %d frame %d PV %.0f" % [queen.phase, guard, queen.health.current])
			previous_phase = queen.phase
		if player.health.current < previous_health:
			print("Reina: frame %d Byte %s PV %.0f estado %d ataque %d interferencia %.2f carriles %s" % [guard, player.global_position, player.health.current, queen.state, queen.attack, queen.get(&"_interference_age"), queen.get(&"_lanes")])
			for bullet: Projectile in queen.pool.enemy_bullets:
				if bullet.active and bullet.global_position.distance_to(player.global_position) < 50.0:
					print("  bala %s velocidad %s" % [bullet.global_position, bullet.velocity])
			previous_health = player.health.current
		if dash_pressed:
			Input.action_release(&"dash")
			dash_pressed = false
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release(&"jump")
		var x: float = player.global_position.x
		var target: float = queen.body.global_position.x
		if queen.phase == 2 and queen.state == WifiQueenBoss.State.TELEGRAPH and queen.attack == WifiQueenBoss.Attack.TELEPORT:
			target = WifiQueenBoss.ANTENNAS[int(queen.get(&"_destination"))].x
		if queen.phase == 3 and queen.state != WifiQueenBoss.State.PHASE_TRANSITION:
			var lanes: Array = queen.get(&"_lanes")
			if float(queen.get(&"_interference_age")) >= 2.5:
				lanes = WifiQueenBoss.interference_lanes(int(queen.get(&"_interference_index")) + 1)
			var best := INF
			var boss_x: float = target
			for lane: int in range(4):
				if lane in lanes:
					continue
				var candidate: float = clampf(boss_x, lane * 160.0 + 18.0, (lane + 1) * 160.0 - 18.0)
				var score: float = absf(candidate - x) + absf(candidate - boss_x) * 0.6
				if score < best:
					best = score
					target = candidate
		if queen.state == WifiQueenBoss.State.TELEGRAPH and queen.attack == WifiQueenBoss.Attack.PING and previous_state != WifiQueenBoss.State.TELEGRAPH:
			var ping_x: float = queen.get(&"_ping_x")
			ping_target = clampf(ping_x + (16.0 if x < 600.0 else -16.0), 20.0, 620.0)
			ping_until = guard + 145
		previous_state = queen.state
		if guard < ping_until:
			target = ping_target
		var danger := false
		var low_wave := false
		for bullet: Projectile in queen.pool.enemy_bullets:
			if not bullet.active:
				continue
			for tick: int in range(1, 13):
				var future: Vector2 = bullet.global_position + bullet.velocity * (float(tick) / 60.0)
				var byte_future: Vector2 = player.global_position + player.velocity * (float(tick) / 60.0)
				if absf(future.x - byte_future.x) < 9.0 and absf(future.y - byte_future.y) < 10.0:
					danger = true
					low_wave = absf(bullet.velocity.y) < 1.0 and bullet.global_position.y > 280.0
					break
			if danger:
				break
		if danger and player.invulnerability <= 0.0:
			if low_wave and player.is_on_floor() and jump_left == 0:
				Input.action_press(&"jump")
				jump_left = 36
				jump_x = x
			elif player.cooldown <= 0.0 and not player.air_dash_used and player.hurt_left <= 0.0:
				target = clampf(x + (80.0 if x < 320.0 else -80.0), 20.0, 620.0)
				Input.action_release(&"aim_up")
				Input.action_press(&"dash")
				dash_pressed = true
		if jump_left > 0:
			target = jump_x
		if queen.phase == 3 and queen.state != WifiQueenBoss.State.PHASE_TRANSITION:
			var lanes: Array = queen.get(&"_lanes")
			if float(queen.get(&"_interference_age")) >= 2.5:
				lanes = WifiQueenBoss.interference_lanes(int(queen.get(&"_interference_index")) + 1)
			if clampi(floori(target / 160.0), 0, 3) in lanes:
				var best_distance := INF
				for lane: int in range(4):
					if lane not in lanes:
						var safe: float = clampf(x, lane * 160.0 + 18.0, (lane + 1) * 160.0 - 18.0)
						if absf(safe - x) < best_distance:
							best_distance = absf(safe - x)
							target = safe
		var dx: float = target - x
		if dx > 2.0:
			Input.action_press(&"move_right")
			Input.action_release(&"move_left")
		elif dx < -2.0:
			Input.action_press(&"move_left")
			Input.action_release(&"move_right")
		else:
			Input.action_release(&"move_left")
			Input.action_release(&"move_right")
		Input.action_release(&"lock_aim")
		if not danger and not dash_pressed and absf(x - queen.body.global_position.x) < 32.0 and absf(dx) <= 2.0 and not queen.body.invulnerable:
			Input.action_press(&"aim_up")
			Input.action_press(&"shoot")
		else:
			Input.action_release(&"shoot")
			if not dash_pressed:
				Input.action_release(&"aim_up")
	var won: bool = queen.state == WifiQueenBoss.State.DEFEATED
	if not won:
		print("Reina FAIL: PV %.0f fase %d frame %d Byte %s PV %.0f" % [queen.health.current, queen.phase, guard, player.global_position, player.health.current])
	return won
