extends SceneTree
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
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	player = get_first_node_in_group("player")
	station = get_first_node_in_group("lieu")
	var trafic = station.trafic
	# 1. de la rue au quai A
	player.global_position = Vector3(0.225, 0.1, -8)
	await walk(180, 14.0, "rue -> quai A (escaliers, couloir)")
	# 2. quai A -> passage -> quai Nation
	player.global_position = Vector3(6, -6.4, 20.8)
	await walk(-90, 4.0, "descente vers le passage")
	await walk(180, 4.2, "passage sous les voies")
	await walk(90, 4.0, "montée vers le quai Nation")
	await walk(0, 1.5, "vers le bord du quai (garde-fou)")
	# 3. rame direction Nation à quai, portes ouvertes
	trafic.time = 60.0 - 47.0 + 94.0 * 0   # k = 13 pour la rame Nation (décalage 47) -> 60 - 47 = 13
	trafic.time = 13.0 - 47.0 + 94.0
	for i in 120: await physics_frame
	player.global_position = Vector3(0.0, -6.4, 31.0)
	await walk(0, 1.6, "montée dans la rame (porte x=0)")
	print("à bord : ", trafic.train_at(player.global_position) != null, "  portes=", snapped(trafic.trains[1].doors_amount, 0.01))
	var x0: float = player.global_position.x
	for i in 60 * 16: await physics_frame
	var p: Vector3 = player.global_position
	print("après 16 s : pos=(%.2f, %.2f, %.2f) rame x=%.2f  lieu=%s" % [p.x, p.y, p.z, trafic.trains[1].position.x, station.place_name(p)])
	for i in 60 * 14: await physics_frame
	p = player.global_position
	print("après 30 s : pos=(%.2f, %.2f, %.2f) rame x=%.2f  à bord=%s" % [p.x, p.y, p.z, trafic.trains[1].position.x, trafic.train_at(p) != null])
	for i in 60 * 30: await physics_frame
	p = player.global_position
	print("après 60 s : pos=(%.2f, %.2f, %.2f) rame x=%.2f  à bord=%s lieu=%s" % [p.x, p.y, p.z, trafic.trains[1].position.x, trafic.train_at(p) != null, station.place_name(p)])
	await walk(180, 1.6, "descente de la rame")
	quit()
