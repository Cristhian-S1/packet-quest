extends RefCounted

## El hit-stop debe durar fotogramas, no milisegundos de reloj: si dependiera del
## reloj real, una carga de CPU cambiaría cuántos fotogramas dura y el juego dejaría
## de ser determinista con --fixed-fps (el bot e2e fallaba en sitios distintos).
var finished: bool = false

func run(tree: SceneTree) -> PackedStringArray:
	var errors: PackedStringArray = []
	var hud: PacketHUD = (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate() as PacketHUD
	tree.root.add_child(hud)
	await tree.process_frame
	Events.impact.emit(0.05, 0.0)
	if not is_equal_approx(Engine.time_scale, 0.05):
		errors.append("el impacto no ralentiza el juego")
	# Un parón de 200 ms del hilo principal no debe consumir el hit-stop.
	OS.delay_msec(200)
	await tree.process_frame
	if not is_equal_approx(Engine.time_scale, 0.05):
		errors.append("el hit-stop terminó por tiempo de reloj y no por fotogramas")
	for _frame: int in range(4):
		await tree.process_frame
	if not is_equal_approx(Engine.time_scale, 1.0):
		errors.append("el hit-stop de 0,05 s no termina tras 3 fotogramas (%.2f)" % Engine.time_scale)
	hud.queue_free()
	await tree.process_frame
	GameState.restore_speed()
	finished = true
	return errors
