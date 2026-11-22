extends RefCounted

## Prueba de rendimiento: 100 balas enemigas + 30 balas de Byte activas.
## Mide durante 300 frames de física el tiempo de proceso por frame usando dos
## instrumentos: Time.get_ticks_usec (wall-clock del paso de física, desde la
## señal physics_frame hasta process_frame) y Performance.TIME_PHYSICS_PROCESS
## (monitor del motor, que en headless queda inflado por las pausas del GC).
## El criterio se evalúa sobre el wall-clock, que es el instrumento fiable.
## También comprueba que el pool tiene capacidad suficiente sin instanciar en
## caliente.
##
## Criterio: media < 8 ms por frame de física y ningún pico > 16 ms en headless.

var finished: bool = false
var errors: PackedStringArray = []

const ENEMY_COUNT: int = 100
const PLAYER_COUNT: int = 30
const FRAMES: int = 300
const MEAN_LIMIT_MS: float = 8.0
const SPIKE_LIMIT_MS: float = 16.0

func run(tree: SceneTree) -> PackedStringArray:
	errors = PackedStringArray()
	finished = false
	# Escenario equivalente con ProjectilePool: usa las clases reales
	# ProjectilePool y Projectile para aislar el hot path de las balas (raycast
	# + GDScript por bala activa). El espacio vacío hace la medida determinista
	# y sin colisiones accidentales (el coste del raycast apenas depende del
	# impacto).
	var stage: Node2D = Node2D.new()
	var pool: ProjectilePool = ProjectilePool.new()
	stage.add_child(pool)
	tree.root.add_child(stage)
	await tree.process_frame  # _ready() del pool precarga todas las balas

	# 1) Capacidad: el pool precarga en _ready() y fire() nunca instancia en caliente.
	check(pool.enemy_capacity >= ENEMY_COUNT, "capacidad enemiga insuficiente (%d < %d)" % [pool.enemy_capacity, ENEMY_COUNT])
	check(pool.player_capacity >= PLAYER_COUNT, "capacidad de jugador insuficiente (%d < %d)" % [pool.player_capacity, PLAYER_COUNT])
	check(pool.enemy_bullets.size() == pool.enemy_capacity, "pool enemigo no precargado al 100 %")
	check(pool.player_bullets.size() == pool.player_capacity, "pool de jugador no precargado al 100 %")

	# 2) Activar 100 balas enemigas y 30 de jugador.
	var enemy_fired: int = 0
	for index: int in range(ENEMY_COUNT):
		var pos: Vector2 = Vector2(40.0 + float(index % 20) * 28.0, 50.0 + float(index / 20) * 50.0)
		if pool.fire(true, pos, Vector2(10, 0)) != null:
			enemy_fired += 1
	check(enemy_fired == ENEMY_COUNT, "solo %d/%d balas enemigas activadas" % [enemy_fired, ENEMY_COUNT])

	var player_fired: int = 0
	for index: int in range(PLAYER_COUNT):
		if pool.fire(false, Vector2(40.0 + float(index) * 18.0, 320.0), Vector2(10, 0)) != null:
			player_fired += 1
	check(player_fired == PLAYER_COUNT, "solo %d/%d balas de jugador activadas" % [player_fired, PLAYER_COUNT])
	check(_count_active(pool.enemy_bullets) == ENEMY_COUNT and _count_active(pool.player_bullets) == PLAYER_COUNT, "no hay %d+%d balas activas" % [ENEMY_COUNT, PLAYER_COUNT])

	# 3) Calentamiento y medición de 300 frames de física.
	await tree.physics_frame
	await tree.physics_frame
	var physics_samples: PackedFloat32Array = PackedFloat32Array()
	var monitor_samples: PackedFloat32Array = PackedFloat32Array()
	var t_start: int = Time.get_ticks_usec()
	for _frame: int in range(FRAMES):
		await tree.physics_frame
		var step_start: int = Time.get_ticks_usec()
		await tree.process_frame
		# Tiempo real del paso de física (physics_frame -> process_frame).
		physics_samples.append(float(Time.get_ticks_usec() - step_start) / 1000.0)
		monitor_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	var wall_total_ms: float = float(Time.get_ticks_usec() - t_start) / 1000.0

	# 4) Estadísticas y criterio.
	var mean_ms: float = 0.0
	var peak_ms: float = 0.0
	var min_ms: float = INF
	for value: float in physics_samples:
		mean_ms += value
		peak_ms = maxf(peak_ms, value)
		min_ms = minf(min_ms, value)
	mean_ms /= float(FRAMES)
	print("PERF %d balas | media=%.2f ms | pico=%.2f ms | min=%.2f ms | %d frames de física" % [ENEMY_COUNT + PLAYER_COUNT, mean_ms, peak_ms, min_ms, FRAMES])
	print("PERF wall: %.1f ms en total (%.2f ms/frame de física)" % [wall_total_ms, wall_total_ms / float(FRAMES)])
	var monitor_mean: float = 0.0
	var monitor_peak: float = 0.0
	for value: float in monitor_samples:
		monitor_mean += value
		monitor_peak = maxf(monitor_peak, value)
	monitor_mean /= float(FRAMES)
	print("PERF monitor TIME_PHYSICS_PROCESS: media=%.2f ms pico=%.2f ms" % [monitor_mean, monitor_peak])

	_print_histogram(physics_samples)

	check(mean_ms < MEAN_LIMIT_MS, "media %.2f ms supera %.2f ms" % [mean_ms, MEAN_LIMIT_MS])
	check(peak_ms <= SPIKE_LIMIT_MS, "pico %.2f ms supera %.2f ms" % [peak_ms, SPIKE_LIMIT_MS])
	check(_count_active(pool.enemy_bullets) == ENEMY_COUNT and _count_active(pool.player_bullets) == PLAYER_COUNT, "balas se desactivaron durante la medición")

	stage.queue_free()
	await tree.process_frame
	finished = true
	return errors

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _count_active(bullets: Array[Projectile]) -> int:
	var count: int = 0
	for bullet: Projectile in bullets:
		if bullet.active:
			count += 1
	return count

## Histograma de tiempos de física (ms por frame) para ver pausas de GC.
func _print_histogram(samples: PackedFloat32Array) -> void:
	var sorted: PackedFloat32Array = samples.duplicate()
	sorted.sort()
	var p50: float = sorted[int(float(FRAMES) * 0.5)]
	var p90: float = sorted[int(float(FRAMES) * 0.9)]
	var p99: float = sorted[int(float(FRAMES) * 0.99)]
	print("PERF percentiles p50=%.2f p90=%.2f p99=%.2f" % [p50, p90, p99])
	var buckets: PackedStringArray = PackedStringArray()
	for b: int in range(8):
		var low: float = float(b) * 2.0
		var high: float = float(b + 1) * 2.0
		var count: int = 0
		for value: float in samples:
			if value >= low and value < high:
				count += 1
		buckets.append("%d-%d:%d" % [int(low), int(high), count])
	var over: int = 0
	for value: float in samples:
		if value >= 16.0:
			over += 1
	buckets.append(">=16:%d" % over)
	print("PERF histograma (ms) " + " ".join(buckets))
