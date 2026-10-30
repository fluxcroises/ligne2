extends SceneTree
## Chapitre 4 à Jaurès, de bout en bout : arrivée, Sami et le portail du dépôt, le locotracteur
## et le registre en photo, la déduction, Delorme confronté, Josiane, la fin en reprenant la 2.
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
	img.save_png("%s/c4_%d.png" % [OS.get_environment("CAPTURES"), n])
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
	E.debug_start(4)
	change_scene_to_file("res://scenes/jaures.tscn")
	for f in 8: await process_frame
	dlg = current_scene.get_node("Dialogue")
	phone = current_scene.get_node("Telephone")
	player = get_first_node_in_group("player")
	st = get_first_node_in_group("lieu")
	print("arrivée : ", st.place_name(player.global_position), "  chapitre ", E.chapter, "  heure ", E.clock_text(), "  réseau ", E.has_network())
	# 1. Sami, devant le portail du dépôt
	await talk(Vector3(42.6, 0.05, 28.6), Vector3(44.6, 1.5, 28.6))
	await shot("Sami")
	await pick("Il y a des chantiers"); await read_all()
	await pick("Montrer"); await pick("Planning"); await read_all()
	await pick("Partir")
	for f in 5: await process_frame
	print("   portail ouvert : ", E.check("depot_ouvert"), " / ", st.depot_open)
	# 2. le locotracteur, le registre
	await photo(Vector3(56.0, 0.05, 30.5), Vector3(61.2, 1.5, 27.0), "draisine")
	await shot("le locotracteur")
	await photo(Vector3(78.45, 0.05, 30.4), Vector3(80.2, 0.86, 31.6), "registre_travaux")
	# 3. la déduction, Delorme
	print("déduction : ", E.try_deduction("delorme", ["planning_travaux", "registre_travaux", "draisine", "temoignage_sami"], 2).ok)
	await talk(Vector3(78.45, 0.05, 30.2), Vector3(76.8, 1.4, 31.4))
	await shot("Delorme")
	await pick("Je sais ce que"); await read_all()
	await pick("Partir")
	print("   Delorme confronté : ", E.check("delorme_confronte"))
	# 4. Josiane, sur le quai
	await talk(Vector3(-20.0, 6.05, 23.2), Vector3(-20.0, 7.3, 21.4))
	await pick("Vous voyez passer"); await read_all()
	await pick("Montrer"); await pick("Photo de Karim"); await read_all()
	await pick("Partir")
	print("   témoignage de Josiane : ", E.has_evidence("temoignage_josiane"))
	# 5. reprendre la 2 direction Nation
	var trafic = st.trafic
	trafic.time = 13.0 - 47.0 + 94.0 * 9
	for f in 30: await physics_frame
	await aim(Vector3(0.0, 6.05, 31.0), Vector3(0.0, 7.5, 28.0))
	player.rotation.y = 0.0
	Input.action_press("move_forward")
	for f in 100: await physics_frame
	Input.action_release("move_forward")
	print("à bord : ", trafic.train_at(player.global_position) != null)
	for f in 60 * 18: await physics_frame
	await shot("fin du chapitre 4")
	print("chapitre fini : ", E.flags.get("chapitre_4_fini", false), "  stations : ", E.unlocked_stations)
	quit()
