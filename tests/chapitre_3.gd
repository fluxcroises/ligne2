extends SceneTree
## Chapitre 3 à Pigalle, de bout en bout : arrivée, Rémi l'accordéoniste, Lulu le portier, la
## vitrine de Marchetti en photo, la déduction, les aveux de Marchetti, la fin en reprenant la 2.
var n := 0
var dlg
var E
var player
var phone
var st

func shot(label: String) -> void:
	for f in 4: await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 480, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/c3_%d.png" % [OS.get_environment("CAPTURES"), n])
	print("   [capture ", n, " : ", label, "]")
	n += 1

func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)
	for f in 2: await process_frame

func aim(pos: Vector3, target: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.look_at(Vector3(target.x, pos.y, target.z)); player.rotation.x = 0; player.rotation.z = 0
	for f in 5: await physics_frame
	var cam = player.get_node("Head/Camera3D")
	player.get_node("Head").rotation.x = -atan2(cam.global_position.y - target.y, Vector2(target.x - pos.x, target.z - pos.z).length())
	for f in 12: await physics_frame

func read_all() -> void:
	var guard := 0
	while dlg._speaking and guard < 30:
		await press("ui_accept")
		print("   « ", dlg._text.text, " »")
		await press("ui_accept")
		guard += 1

func pick(text_start: String) -> void:
	for b in dlg._choices.get_children():
		if b.text.begins_with(text_start):
			b.pressed.emit()
			for f in 2: await process_frame
			return
	print("   !! choix introuvable : ", text_start, "  (", dlg._choices.get_children().map(func(c): return c.text), ")")

func talk(pos: Vector3, target: Vector3) -> void:
	await aim(pos, target)
	print("— ", player._focused.title if player._focused else "personne en vue")
	await press("interact")
	await read_all()

func photo(pos: Vector3, target: Vector3, id: String) -> void:
	await aim(pos, target)
	print("visé : ", player._focused.title if player._focused else "rien")
	phone.open(); phone._open_camera()
	for f in 3: await process_frame
	phone._take_photo()
	for f in 3: await process_frame
	phone._leave_camera(); phone.close()
	print("   ", id, " au dossier : ", E.has_evidence(id))

func _initialize() -> void:
	await process_frame
	E = root.get_node("Enquete")
	E.new_game()
	for id in ["photo_voyageur", "caisse", "avis_vol"]:   # trouvées aux chapitres 1 et 2
		E.add_evidence(id)
	E.start_chapter(2)
	E.start_chapter(3)
	change_scene_to_file("res://scenes/pigalle.tscn")
	for f in 8: await process_frame
	dlg = current_scene.get_node("Dialogue")
	phone = current_scene.get_node("Telephone")
	player = get_first_node_in_group("player")
	st = get_first_node_in_group("lieu")
	print("arrivée : ", st.place_name(player.global_position), "  chapitre ", E.chapter, "  heure ", E.clock_text())
	# 1. Rémi, dans le couloir
	await talk(Vector3(10.9, -6.43, 12.0), Vector3(9.3, -5.9, 12.0))
	await shot("Rémi, l'accordéoniste")
	await pick("(Donner"); await read_all()
	await pick("Vous voyez passer"); await read_all()
	print("   témoignage de Rémi : ", E.has_evidence("temoignage_remi"))
	await pick("Partir")
	# 2. Lulu, devant le Chat Rouge
	await talk(Vector3(16.4, 0.05, 7.4), Vector3(16.4, 1.5, 9.3))
	await shot("Lulu")
	await pick("Je ne viens pas"); await read_all()
	await pick("Une camionnette"); await read_all()
	print("   témoignage de Lulu : ", E.has_evidence("temoignage_lulu"))
	await pick("Partir")
	# 3. la vitrine, rue Frochot
	await photo(Vector3(31.0, 0.05, 29.0), Vector3(28.1, 1.5, 29.0), "vitrine")
	await shot("la vitrine de Marchetti")
	# 4. Marchetti nie, puis la déduction, puis les aveux
	await talk(Vector3(30.6, 0.05, 32.0), Vector3(28.6, 1.4, 32.0))
	await pick("Montrer"); await pick("Vitrine"); await read_all()
	await pick("Partir")
	print("déduction : ", E.try_deduction("receleur", ["caisse", "avis_vol", "vitrine", "temoignage_lulu"], 2).ok)
	await talk(Vector3(30.6, 0.05, 32.0), Vector3(28.6, 1.4, 32.0))
	await pick("Je sais d'où"); await read_all()
	await pick("Parlez-moi"); await read_all()
	print("   livre de police : ", E.has_evidence("livre_police"), "  Jaurès : ", E.check("marchetti_jaures"))
	await pick("Partir")
	# 5. reprendre la 2 direction Nation
	var trafic = st.trafic
	trafic.time = 13.0 - 47.0 + 94.0 * 9
	for f in 30: await physics_frame
	await aim(Vector3(0.0, -6.45, 31.0), Vector3(0.0, -5.0, 28.0))
	player.rotation.y = 0.0
	Input.action_press("move_forward")
	for f in 100: await physics_frame
	Input.action_release("move_forward")
	print("à bord : ", trafic.train_at(player.global_position) != null)
	for f in 60 * 18: await physics_frame
	await shot("fin du chapitre 3")
	print("chapitre fini : ", E.flags.get("chapitre_3_fini", false), "  stations : ", E.unlocked_stations)
	quit()
