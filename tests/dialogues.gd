extends SceneTree
var n := 0
var dlg
var E
func shot(label: String) -> void:
	for f in 4: await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 480, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/dl_%d.png" % [OS.get_environment("CAPTURES"), n])
	print("   [capture ", n, " : ", label, "]")
	n += 1

func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)
	for f in 2: await process_frame

## Fait défiler les répliques jusqu'aux choix, en les affichant.
func read_all() -> void:
	var guard := 0
	while dlg._speaking and guard < 30:
		await press("ui_accept")   # finit la frappe
		print("   « ", dlg._text.text, " »")
		await press("ui_accept")   # réplique suivante
		guard += 1

func choices() -> Array:
	return dlg._choices.get_children().map(func(b): return b.text)

func pick(text_start: String) -> void:
	for b in dlg._choices.get_children():
		if b.text.begins_with(text_start):
			b.pressed.emit()
			for f in 2: await process_frame
			return
	print("   !! choix introuvable : ", text_start)

func talk(who: String, pos: Vector3, look_at: Vector3) -> void:
	var player = get_first_node_in_group("player")
	player.global_position = pos
	player.look_at(Vector3(look_at.x, pos.y, look_at.z)); player.rotation.x = 0; player.rotation.z = 0
	var cam = player.get_node("Head/Camera3D")
	for f in 5: await physics_frame
	player.get_node("Head").rotation.x = -atan2(cam.global_position.y - look_at.y, Vector2(look_at.x - pos.x, look_at.z - pos.z).length())
	for f in 10: await physics_frame
	print("— ", who, " (visé : ", player._focused.title if player._focused else "rien", ")")
	await press("interact")

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for f in 5: await process_frame
	dlg = current_scene.get_node("Dialogue")
	E = root.get_node("Enquete")

	await talk("Jo", Vector3(-0.6, -3.2, 13.3), Vector3(0.85, -2.5, 13.3))
	await shot("Jo, première réplique")
	await read_all()
	print("   choix : ", choices())
	await pick("Mardi soir"); await read_all()
	await pick("Montrer"); print("   dossier : ", choices())
	await pick("Photo de Karim"); await read_all()
	E.add_evidence("photo_voyageur")
	await pick("Montrer"); await pick("Photo d'un voyageur"); await read_all()
	print("   témoignage au dossier : ", E.has_evidence("temoignage_jo"))
	await pick("Partir")

	await talk("Sylvain", Vector3(-2.2, -3.2, 5.15), Vector3(-3.55, -1.7, 5.15))
	await read_all()
	await shot("Sylvain, choix")
	await pick("Vous étiez là"); await read_all()
	E.add_evidence("cahier")
	await pick("Montrer"); await shot("montrer une pièce")
	await pick("Cahier"); await read_all()
	print("   ment : ", E.flags.get("sylvain_ment", false), "   choix : ", choices())
	E.add_evidence("badge"); E.add_evidence("serrure")
	E.try_deduction("faux_agent", ["badge", "serrure", "photo_voyageur", "cahier"], 2)
	await pick("Partir")
	await talk("Sylvain", Vector3(-2.2, -3.2, 5.15), Vector3(-3.55, -1.7, 5.15))
	print("   choix après la déduction : ", choices())
	await pick("Je sais ce qui"); await read_all()
	await pick("Partir")

	await talk("Mme Roche", Vector3(-0.1, 0.05, 19.6), Vector3(-0.1, 1.5, 22.0))
	await read_all(); await shot("Mme Roche")
	await pick("Vous avez remarqué"); await read_all()
	await pick("Partir")
	await talk("Gardien", Vector3(-10.9, 0.05, 13.6), Vector3(-12.7, 1.5, 13.6))
	await read_all(); await pick("Vous avez vu"); await read_all()
	await pick("Montrer"); await pick("Photo de Karim"); await read_all()
	await shot("le gardien")
	await pick("Partir")
	print("dossier final : ", E.evidence.map(func(e): return e.id))
	print("joueur libre : ", not get_first_node_in_group("player").input_locked)
	quit()
