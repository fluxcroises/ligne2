extends SceneTree
## Villiers : de la place à la salle des billets, du couloir en tube au quai direction Porte Dauphine, par l'escalier et le passage
## sous les voies jusqu'au quai direction Nation, puis par le couloir de correspondance
## jusqu'au quai de la ligne 3.
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
	player.global_position = Vector3(-18.8, 0.1, -16.0)
	await walk(180, 2.0, "place Prosper-Goubaux")
	await walk(180, 3.5, "escalier -> salle des billets")
	await walk(180, 3.0, "portillons -> escalier des quais")
	await walk(180, 6.0, "couloir en tube -> quai A")
	await walk(180, 2.0, "vers le bord du quai (garde-fou)")
	player.global_position = Vector3(-21.1, -3.1, -3.5)
	await walk(0, 4.0, "remontée par l'escalator")
	player.global_position = Vector3(-17.0, 0.1, -2.0)
	await walk(150, 3.5, "vers le café, rue de Lévis")
	player.global_position = Vector3(-3.0, -6.4, 20.8)
	await walk(-90, 4.0, "descente vers le passage")
	player.global_position.x = 6.7   # au milieu du passage, loin de l'ouverture du couloir
	await walk(180, 4.2, "passage sous les voies")
	await walk(90, 4.0, "montée vers le quai Nation")
	player.global_position = Vector3(-6.0, -6.4, 31.0)
	await walk(-90, 6.0, "le long de la trémie, quai Nation")
	player.global_position = Vector3(6.6, -10.8, 27.0)
	await walk(-90, 9.0, "couloir de correspondance -> ligne 3")
	await walk(0, 3.0, "le long du quai de la ligne 3")
	var t3 = station.trafic3
	t3.time = 15.0 - 20.0 + 94.0   # rame direction Pont de Levallois à quai
	for i in 60: await physics_frame
	player.global_position = Vector3(21.2, -13.9, 27.0 - 4.533)
	await walk(-90, 1.6, "montée dans la rame de la ligne 3")
	# quai direction Gallieni : par le local technique et le couloir de service jusqu'à la boucle
	player.global_position = Vector3(29.0, -13.9, 0.1)
	await walk(-90, 1.0, "devant le local technique")
	await walk(-90, 3.0, "dans le local, couloir de service")
	await walk(-90, 4.0, "boucle, voiture Sprague ouverte")
	player.global_position = Vector3(39.4, -13.9, 0.1)
	await walk(0, 6.0, "le long de la banquette")
	quit()
