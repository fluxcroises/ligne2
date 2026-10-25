extends SceneTree
## Vérifie les vraies entrées : mouvement de souris (caméra) et touche E (examiner),
## qui passent de l'écran principal au monde 3D.
func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)
	for f in 3: await process_frame

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for f in 8: await process_frame
	var player = get_first_node_in_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var yaw0: float = player.rotation.y
	var pitch0: float = player.get_node("Head").rotation.x
	for i in 10:
		# souris capturée : le système place le pointeur au centre de la fenêtre
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(20, 8)
		ev.position = DisplayServer.window_get_size() / 2
		ev.global_position = ev.position
		Input.parse_input_event(ev)
		await process_frame
	print("souris : lacet ", snapped(rad_to_deg(player.rotation.y - yaw0), 0.1), "°, tangage ",
		snapped(rad_to_deg(player.get_node("Head").rotation.x - pitch0), 0.1), "°")
	# même chose dans le viseur de l'appareil photo
	var phone = current_scene.get_node("Telephone")
	phone.open()
	phone._open_camera()
	for f in 3: await process_frame
	yaw0 = player.rotation.y
	for i in 10:
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(-20, 0)
		ev.position = DisplayServer.window_get_size() / 2
		ev.global_position = ev.position
		Input.parse_input_event(ev)
		await process_frame
	print("souris dans le viseur : lacet ", snapped(rad_to_deg(player.rotation.y - yaw0), 0.1), "°")
	phone._leave_camera()
	phone.close()
	# touche E devant la porte de service
	player.global_position = Vector3(-35.6, -6.45, 21.4)
	player.rotation = Vector3(0, deg_to_rad(90), 0)
	player.get_node("Head").rotation.x = 0.0
	for f in 15: await physics_frame
	await press("interact")
	print("examen avec E : ", current_scene.get_node("HUD")._panel.visible, " (", current_scene.get_node("HUD")._panel_text.text.get_slice("\n", 0), ")")
	quit()
