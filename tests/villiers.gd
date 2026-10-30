extends SceneTree
## Villiers, quais de la ligne 2 : du couloir en tube au quai direction Porte Dauphine, puis par
## l'escalier et le passage sous les voies jusqu'au quai direction Nation.
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
	change_scene_to_file("res://scenes/villiers.tscn")
	await process_frame
	await process_frame
	player = get_first_node_in_group("player")
	station = get_first_node_in_group("lieu")
	player.global_position = Vector3(-19, -6.4, 13.5)
	await walk(180, 4.0, "couloir en tube -> quai A")
	await walk(180, 2.0, "vers le bord du quai (garde-fou)")
	player.global_position = Vector3(-3.0, -6.4, 20.8)
	await walk(-90, 4.0, "descente vers le passage")
	await walk(180, 4.2, "passage sous les voies")
	await walk(90, 4.0, "montée vers le quai Nation")
	player.global_position = Vector3(-6.0, -6.4, 31.0)
	await walk(-90, 6.0, "le long de la trémie, quai Nation")
	quit()
