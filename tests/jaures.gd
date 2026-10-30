extends SceneTree
## Jaurès à pied : du boulevard de la Villette à la salle des billets sous le viaduc, les
## portillons, les escaliers jusqu'aux deux quais ; le dépôt, fermé.
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
	change_scene_to_file("res://scenes/jaures.tscn")
	for f in 4: await process_frame
	player = get_first_node_in_group("player")
	station = get_first_node_in_group("lieu")
	player.global_position = Vector3(-12.2, 0.1, 14.0)
	await walk(180, 3.0, "boulevard -> salle des billets")
	player.global_position.z = 30.4   # entre deux portillons
	await walk(-90, 3.0, "portillons")
	player.global_position = Vector3(6.6, 0.1, 33.2)
	await walk(90, 7.0, "escalier -> quai Nation")
	await walk(0, 1.5, "vers le bord du quai (garde-fou)")
	player.global_position = Vector3(6.6, 0.1, 20.8)
	await walk(90, 7.0, "escalier -> quai Porte Dauphine")
	player.global_position = Vector3(38.0, 0.1, 37.0)
	await walk(-90, 3.0, "le long du dépôt")
	player.global_position = Vector3(42.0, 0.1, 27.0)
	await walk(-90, 2.0, "portail du dépôt fermé")
	quit()
