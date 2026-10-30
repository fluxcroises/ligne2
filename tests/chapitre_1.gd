extends SceneTree
var n := 0
func shot(label: String) -> void:
	for f in 4: await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 480, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/c6_%d.png" % [OS.get_environment("CAPTURES"), n])
	print("   [capture ", n, " : ", label, "]")
	n += 1
func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)
	for f in 2: await process_frame
func aim(player, pos: Vector3, target: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.look_at(Vector3(target.x, pos.y, target.z)); player.rotation.x = 0; player.rotation.z = 0
	for f in 5: await physics_frame
	var cam = player.get_node("Head/Camera3D")
	player.get_node("Head").rotation.x = -atan2(cam.global_position.y - target.y, Vector2(target.x - pos.x, target.z - pos.z).length())
	for f in 12: await physics_frame

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for f in 5: await process_frame
	var E = root.get_node("Enquete")
	var player = get_first_node_in_group("player")
	var phone = current_scene.get_node("Telephone")
	var st = get_first_node_in_group("lieu")
	var trafic = st.trafic
	var ch = st.get_node("Chapitre1")
	# 1. recherche à la surface
	phone.open(); phone._show(phone._search)
	print("suggestions : ", phone._list.get_children().filter(func(c): return c is Button).map(func(b): return b.text))
	phone._run_search(Chapitre1.SEARCHES[0])
	await shot("résultats de recherche")
	for b in phone._list.get_children():
		if b is Button and b.text.begins_with("Enregistrer"): b.pressed.emit()
	print("photo du voyageur au dossier : ", E.has_evidence("photo_voyageur"), "  batterie=", E.battery)
	phone.close()
	# 2. la salle des billets, avant la ronde
	await aim(player, Vector3(0.0, -3.2, 3.6), Vector3(0.5, -1.9, 9.9))
	await shot("salle des billets, Sylvain au guichet")
	await aim(player, Vector3(-2.2, -3.2, 5.15), Vector3(-3.55, -1.7, 5.15))
	print("visé à travers la vitre : ", player._focused.title if player._focused else "rien")
	await aim(player, Vector3(-0.2, -3.2, 6.0), Vector3(0.6, -2.4, 9.9))
	await shot("portillons")
	# 3. 23 h 18 : ronde
	trafic.time = (Chapitre1.RONDE_FIRST - Chapitre1.START) * 60.0 + 5.0
	for f in 5: await process_frame
	print("23:18 → Sylvain : ", st.people.sylvain.global_position, "  porte : ", rad_to_deg(st.loge_door.rotation.y))
	await aim(player, Vector3(-1.4, -3.2, 7.3), Vector3(-4.5, -2.4, 6.5))
	await shot("porte de la loge ouverte")
	# entrer dans la loge à pied
	player.global_position = Vector3(-1.6, -3.2, 7.3); player.rotation.y = deg_to_rad(90)
	Input.action_press("move_forward")
	for f in 70: await physics_frame
	Input.action_release("move_forward")
	print("dans la loge : ", player.global_position)
	await aim(player, Vector3(-4.3, -3.2, 4.9), Vector3(-5.1, -2.36, 4.7))
	print("visé : ", player._focused.title if player._focused else "rien")
	await press("interact")
	print("examen : ", current_scene.get_node("HUD")._panel_text.text.replace("\n", " / "))
	await press("interact")
	phone.open(); phone._open_camera()
	await press("interact")
	for f in 6: await process_frame
	print("photo : ", phone._toast.text)
	await press("ui_cancel"); phone.close()
	await aim(player, Vector3(-4.3, -3.2, 7.2), Vector3(-5.15, -2.3, 7.35))
	await press("interact")
	print("casier avant déduction : ", current_scene.get_node("HUD")._panel_text.text.replace("\n", " / "))
	await press("interact")
	await shot("dans la loge")
	# 4. 23 h 20 : le kiosque ferme
	trafic.time = (Chapitre1.KIOSK_CLOSES - Chapitre1.START) * 60.0 + 5.0
	for f in 5: await process_frame
	print("23:20 → Mme Roche partie : ", not st.people.has("roche"), "  rideau baissé : ", st.kiosk_shutter.visible)
	# 5. aide de Nadia
	var before: int = E.messages.size()
	player.global_position = Vector3(0, 0.1, -10)
	for f in 10: await physics_frame
	ch._idle = Chapitre1.HINT_DELAY + 1.0
	for f in 10: await process_frame
	print("aide de Nadia : ", E.messages.back().text if E.messages.size() > before else "aucune")
	# 6. déduction, casier, aveux
	for id in ["badge", "serrure"]: E.add_evidence(id)
	print("déduction : ", E.try_deduction("faux_agent", ["badge", "serrure", "photo_voyageur", "cahier"], 2).ok)
	await aim(player, Vector3(-4.3, -3.2, 7.2), Vector3(-5.15, -2.3, 7.35))
	await press("interact")
	print("casier après déduction : ", E.has_evidence("billet"))
	await press("interact")
	E.flags["sylvain_aveu"] = true
	# 7. monter dans la rame direction Nation
	trafic.time = 13.0 - 47.0 + 94.0 * 9
	for f in 30: await physics_frame
	await aim(player, Vector3(0.0, -6.45, 31.0), Vector3(0.0, -5.0, 28.0))
	player.rotation.y = 0.0
	Input.action_press("move_forward")
	for f in 100: await physics_frame
	Input.action_release("move_forward")
	print("à bord : ", trafic.train_at(player.global_position) != null)
	for f in 60 * 18: await physics_frame
	await shot("fin du chapitre")
	print("chapitre fini : ", E.flags.get("chapitre_1_fini", false), "  stations : ", E.unlocked_stations)
	# 8. Entrée : le chapitre 2 commence à Villiers
	await press("ui_accept")
	for f in 20: await process_frame
	player = get_first_node_in_group("player")
	var p: Vector3 = player.global_position
	print("suite : ", current_scene.scene_file_path.get_file(), "  chapitre=", E.chapter, "  lieu=", get_first_node_in_group("lieu").place_name(p),
		"  messages en attente de réseau=", E._outbox.size())
	quit()
