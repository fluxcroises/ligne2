extends SceneTree
## Pigalle à pied : du terre-plein du boulevard de Clichy, par la bouche Guimard, la salle des
## billets, l'escalier et le couloir, jusqu'au quai ; puis le passage sous les voies et l'autre quai.
var player
var station

func walk(yaw: float, seconds: float, label: String) -> void:
	player.rotation = Vector3(0, deg_to_rad(yaw), 0)
	Input.action_press("move_forward")
	var t := 0.0
	while t < seconds:
		await physics_frame
		t += 1.0 / 60.0
	Input.action_release("move_forward")
	for i in 10: await physics_frame
	var p: Vector3 = player.global_position
	print("%-34s pos=(%.2f, %.2f, %.2f)  lieu=%s" % [label, p.x, p.y, p.z, station.place_name(p)])

func _initialize() -> void:
	change_scene_to_file("res://scenes/pigalle.tscn")
	for f in 4: await process_frame
	player = get_first_node_in_group("player")
	station = get_first_node_in_group("lieu")
	player.global_position = Vector3(10.0, 0.1, -18.0)
	await walk(180, 2.5, "terre-plein, bouche Guimard")
	await walk(180, 3.5, "escalier -> salle des billets")
	player.global_position.x = 10.6   # entre deux portillons
	await walk(180, 3.0, "portillons -> escalier")
	await walk(180, 8.0, "escalier, couloir -> quai A")
	player.global_position = Vector3(-13.0, -6.4, 20.8)
	await walk(-90, 4.0, "descente vers le passage")
	player.global_position.x = -3.3
	await walk(180, 4.2, "passage sous les voies")
	await walk(90, 4.0, "montée vers le quai Nation")
	player.global_position = Vector3(31.0, 0.1, 15.0)
	await walk(180, 4.0, "rue Frochot")
	quit()
