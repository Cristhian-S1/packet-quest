extends RefCounted

static func fight(tree: SceneTree, boss: FirewallBoss) -> bool:
	var player: PacketPlayer = boss.player
	var elapsed := 0
	var last_hp := player.health.current
	var dash_pressed := 0
	var jumping := 0
	while boss.get(&"_state") != FirewallBoss.State.DEFEATED and player.health.current > 0.0 and elapsed < 18000:
		await tree.physics_frame
		elapsed += 1
		if player.health.current < last_hp:
			print("Firewall frame %d Byte %s PV %.0f jefe %.0f fase %d muro %s" % [elapsed, player.position, player.health.current, boss.health.current, boss.phase, boss.get(&"_wall").position])
			last_hp = player.health.current
		if dash_pressed > 0:
			dash_pressed -= 1
			if dash_pressed == 0:
				Input.action_release(&"dash")
		if jumping > 0:
			jumping -= 1
			if jumping == 0:
				Input.action_release(&"jump")
		Input.action_release(&"lock_aim")
		Input.action_release(&"aim_up")
		Input.action_release(&"shoot")
		var wall_x: float = boss.get(&"_wall").position.x
		var target_x: float = clampf(wall_x - 110.0, 25.0, 370.0)
		var port_y: float = boss.get(&"_port_y")
		if boss.phase == 2 and port_y >= 0.0 and port_y <= 260.0:
			target_x = clampf(wall_x - (player.position.y - port_y) - 10.0, 25.0, 435.0)
		if boss.phase == 2 and port_y > 260.0:
			target_x = minf(wall_x - 60.0, 420.0)
		for rule: RuleBar in boss.get(&"_rules"):
			if rule.visible and rule.position.x > player.position.x and 0 not in rule.get(&"_lanes"):
				target_x = minf(target_x, wall_x - 165.0)
		var dx: float = target_x - player.position.x
		if dx > 5.0:
			Input.action_press(&"move_right")
			Input.action_release(&"move_left")
		elif dx < -5.0:
			Input.action_press(&"move_left")
			Input.action_release(&"move_right")
		else:
			Input.action_release(&"move_left")
			Input.action_release(&"move_right")
		var danger := false
		for rule: RuleBar in boss.get(&"_rules"):
			if rule.visible and not bool(rule.get(&"_warning")):
				var distance: float = rule.position.x - player.position.x
				var lanes: Array = rule.get(&"_lanes")
				if distance > 0.0 and distance < 31.0 and 0 not in lanes:
					danger = true
					if player.cooldown <= 0.0 and not player.air_dash_used and dash_pressed == 0 and player.hurt_left <= 0.0:
						Input.action_release(&"move_left")
						Input.action_press(&"move_right")
						Input.action_press(&"dash")
						dash_pressed = 2
		if boss.get(&"_state") == FirewallBoss.State.TELEGRAPH and boss.get(&"_attack") == FirewallBoss.Attack.LASER and float(boss.get(&"_timer")) < 0.20 and absf(player.position.y - float(boss.get(&"_laser_y"))) < 15.0:
			danger = true
			if player.is_on_floor() and jumping == 0:
				Input.action_press(&"jump")
				jumping = 35
		if not danger and dash_pressed == 0 and absf(dx) < 7.0 and port_y >= 0.0 and not boss.core.invulnerable and (boss.phase != 3 or target_x >= wall_x - 115.0):
			Input.action_release(&"move_left")
			Input.action_press(&"move_right")
			Input.action_press(&"lock_aim")
			if port_y < 260.0:
				Input.action_press(&"aim_up")
			Input.action_press(&"shoot")
		elif not danger and dash_pressed == 0 and boss.phase == 3 and absf(dx) < 7.0:
			Input.action_release(&"move_left")
			Input.action_press(&"move_right")
			Input.action_press(&"lock_aim")
			Input.action_press(&"shoot")
	var won: bool = boss.get(&"_state") == FirewallBoss.State.DEFEATED
	if not won:
		print("Firewall FAIL frame %d jefe %.0f fase %d Byte %s PV %.0f" % [elapsed, boss.health.current, boss.phase, player.position, player.health.current])
	return won
