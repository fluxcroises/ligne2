extends SceneTree
## Chapitre 5 à Nation, de bout en bout : arrivée, Bruno et la porte de service, la boucle, la
## grille du local 14 en photo, la déduction, Franck qui cède, Karim libre, la fin du jeu.
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
	img.save_png("%s/c5_%d.png" % [OS.get_environment("CAPTURES"), n])
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

func loop_pos(deg_offset: float, r: float, y: float) -> Vector3:
	var q: Vector2 = st._loop_point(st._loop(), st.NICHE_A + deg_to_rad(deg_offset), r)
	return Vector3(q.x, y, q.y)

func _initialize() -> void:
	await process_frame
	E = root.get_node("Enquete")
	E.debug_start(5)
	change_scene_to_file("res://scenes/nation.tscn")
	for f in 8: await process_frame
	dlg = current_scene.get_node("Dialogue")
	phone = current_scene.get_node("Telephone")
	player = get_first_node_in_group("player")
	st = get_first_node_in_group("lieu")
	print("arrivée : ", st.place_name(player.global_position), "  chapitre ", E.chapter, "  heure ", E.clock_text(), "  réseau sur le quai ", E.has_network())
	# 1. Bruno, au bout du quai d'arrivée
	await talk(Vector3(27.6, -6.43, 30.9), Vector3(27.6, -5.0, 32.6))
	await shot("Bruno")
	await pick("Il se passe"); await read_all()
	await pick("Montrer"); await pick("Témoignage de Josiane"); await read_all()
	await pick("Partir")
	for f in 5: await process_frame
	print("   porte de service : ", E.check("porte_boucle"), " / ", st.service_open)
	# 2. dans la boucle : Franck devant la grille, la grille en photo
	await aim(Vector3(30.0, -6.43, 38.0), Vector3(30.0, -5.6, 42.0))
	for f in 5: await process_frame
	print("dans le couloir : ", st.place_name(player.global_position), "  réseau ", E.has_network())
	await photo(loop_pos(1.5, 1.9, -6.43), loop_pos(0.0, 2.7, -5.4), "cadenas")
	await shot("la grille du local 14")
	await talk(loop_pos(-6.0, 2.0, -6.43), st.people.franck.global_position + Vector3(0, 1.5, 0))
	await shot("Franck")
	await pick("Ouvrez cette grille"); await read_all()
	await pick("Partir")
	# 3. la déduction, puis Franck cède
	print("déduction : ", E.try_deduction("local14", ["temoignage_josiane", "temoignage_bruno", "cadenas", "registre_travaux"], 2).ok)
	await talk(loop_pos(-6.0, 2.0, -6.43), st.people.franck.global_position + Vector3(0, 1.5, 0))
	await pick("C'est fini"); await read_all()
	await pick("Partir")
	for f in 5: await process_frame
	print("   grille ouverte : ", E.check("franck_cede"), " / ", st.niche_open, "  aveux : ", E.has_evidence("aveu_franck"))
	# 4. Karim
	await talk(loop_pos(0.0, 3.0, -6.43), st.people.karim.global_position + Vector3(0, 0.7, 0))
	await shot("Karim")
	await pick("Je viens de la part"); await read_all()
	await pick("Partir")
	for f in 30: await process_frame
	await shot("fin du jeu")
	print("Karim libre : ", E.check("karim_libre"), "  chapitre fini : ", E.flags.get("chapitre_5_fini", false))
	await press("ui_accept")
	for f in 10: await process_frame
	print("après la fin : ", current_scene.scene_file_path.get_file())
	quit()
