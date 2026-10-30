extends SceneTree
## Chapitre 2 à Villiers, de bout en bout : arrivée, Inès et le signalement, le patron et le
## ticket, l'agent de sécurité qui ouvre le local, le planning et la caisse en photo, Franck
## qui s'enfuit, l'avis de vol en ligne, la déduction, la fin en reprenant la 2.
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
	img.save_png("%s/c2_%d.png" % [OS.get_environment("CAPTURES"), n])
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
	E.add_evidence("photo_voyageur")   # trouvée au chapitre 1
	E.start_chapter(2)
	change_scene_to_file("res://scenes/villiers.tscn")
	for f in 8: await process_frame
	dlg = current_scene.get_node("Dialogue")
	phone = current_scene.get_node("Telephone")
	player = get_first_node_in_group("player")
	st = get_first_node_in_group("lieu")
	print("arrivée : ", st.place_name(player.global_position), "  chapitre ", E.chapter, "  heure ", E.clock_text())
	# 1. en surface, les messages de Nadia arrivent ; Inès au café
	await aim(Vector3(-19.0, 0.05, -14.0), Vector3(-19.0, 1.5, -20.0))
	for f in 5: await process_frame
	print("messages : ", E.messages.slice(-2).map(func(m): return m.text.left(40)))
	await talk(Vector3(-21.4, 0.05, 11.2), Vector3(-23.1, 0.6, 10.6))
	await shot("Inès au café")
	await pick("Je viens de la part"); await read_all()
	await pick("Karim vous parlait"); await read_all()
	await pick("Il a fait quelque chose"); await read_all()
	await pick("Qui est Delorme"); await read_all()
	print("   signalement : ", E.has_evidence("signalement"), "  témoignage : ", E.has_evidence("temoignage_ines"))
	await pick("Partir")
	# 2. le patron, le gilet orange, le ticket
	await talk(Vector3(-22.2, 0.05, 6.4), Vector3(-24.0, 1.4, 6.4))
	await pick("Montrer"); await pick("Photo d'un voyageur"); await read_all()
	print("   ticket : ", E.has_evidence("ticket"))
	await pick("Partir")
	# 3. l'agent de sécurité ouvre le local technique de la ligne 3
	await talk(Vector3(-18.2, -3.19, 0.2), Vector3(-16.1, -1.8, 0.2))
	await shot("l'agent de sécurité")
	await pick("Vos rondes"); await read_all()
	await pick("Montrer"); await pick("Signalement de Karim"); await read_all()
	await pick("Partir")
	for f in 5: await process_frame
	print("   local ouvert : ", E.check("local_ouvert"), "  porte : ", st.local_open)
	# 4. le planning, dans le local ; la caisse, dans la boucle ; Franck
	await photo(Vector3(31.0, -13.93, 0.1), Vector3(31.97, -12.48, 1.0), "planning_travaux")
	await aim(Vector3(37.4, -13.93, 0.1), Vector3(44.0, -13.0, -8.0))
	for f in 30: await process_frame
	await shot("Franck s'enfuit")
	for f in 240: await process_frame
	print("Franck vu : ", E.check("franck_vu"), "  encore là : ", st.people.has("franck"))
	await photo(Vector3(41.6, -13.93, 0.4), Vector3(41.5, -13.6, -1.6), "caisse")
	await shot("la caisse")
	# 5. en surface : l'avis de vol en ligne
	await aim(Vector3(-19.0, 0.05, -14.0), Vector3(-19.0, 1.5, -20.0))
	for f in 5: await process_frame
	phone.open(); phone._show(phone._search)
	print("suggestions : ", phone._list.get_children().filter(func(c): return c is Button).map(func(b): return b.text))
	for s in Chapitres.searches(2):
		if s.query.begins_with("statuette"):
			phone._run_search(s)
	for b in phone._list.get_children():
		if b is Button and b.text.begins_with("Enregistrer"): b.pressed.emit()
	await shot("avis de vol")
	phone.close()
	print("avis de vol : ", E.has_evidence("avis_vol"))
	# 6. la déduction
	print("déduction fausse : ", E.try_deduction("trafic", ["signalement", "caisse", "avis_vol", "planning_travaux"], 1).text)
	print("déduction : ", E.try_deduction("trafic", ["signalement", "caisse", "avis_vol", "planning_travaux"], 2).ok)
	# 7. la sauvegarde mène à Villiers
	E.save_game()
	print("scène à charger : ", Chapitres.scene(E.chapter).get_file())
	# 8. reprendre la 2 direction Nation (quai B, rame à quai)
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
	await shot("fin du chapitre 2")
	print("chapitre fini : ", E.flags.get("chapitre_2_fini", false), "  stations : ", E.unlocked_stations)
	quit()
