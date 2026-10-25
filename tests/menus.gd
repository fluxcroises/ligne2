extends SceneTree
var n := 0
func shot(label: String) -> void:
	for f in 4: await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 480, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/mn_%d.png" % [OS.get_environment("CAPTURES"), n])
	print("   [capture ", n, " : ", label, "]")
	n += 1
func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)
	for f in 3: await process_frame
func buttons(node: Node) -> Array:
	return node.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree())
func click(node: Node, text: String) -> void:
	for b in buttons(node):
		if b.text.begins_with(text):
			b.pressed.emit(); for f in 6: await process_frame
			return
	print("   !! bouton introuvable : ", text)

func _initialize() -> void:
	change_scene_to_file("res://scenes/titre.tscn")
	for f in 6: await process_frame
	var E = root.get_node("Enquete")
	print("titre, boutons : ", buttons(current_scene).map(func(b): return b.text))
	await shot("écran titre")
	await click(current_scene, "Réglages")
	await shot("réglages")
	await press("ui_cancel")
	await click(current_scene, "Nouvelle partie")
	for f in 10: await process_frame
	print("partie lancée : ", current_scene.name, "  dossier : ", E.evidence.map(func(e): return e.id))
	var player = current_scene.get_node("Player")
	player.global_position = Vector3(-6.0, -6.45, 22.5)
	current_scene.get_node("Monceau").trafic.time = 200.0
	for f in 10: await physics_frame
	E.add_evidence("badge")
	for f in 5: await process_frame
	var file := FileAccess.open(E.SAVE_PATH, FileAccess.READ)
	print("sauvegarde automatique : ", file != null, "  ", file.get_as_text().length() if file else 0, " octets")
	await press("pause")
	print("pause ouverte : ", paused)
	await shot("menu pause")
	await click(current_scene.get_node("Pause"), "Sauvegarder et revenir")
	for f in 10: await process_frame
	print("retour au titre : ", current_scene.name, "  boutons : ", buttons(current_scene).map(func(b): return b.text))
	await click(current_scene, "Continuer")
	for f in 15: await process_frame
	player = current_scene.get_node("Player")
	print("chargée : dossier=", E.evidence.map(func(e): return e.id), "  position=", player.global_position.snapped(Vector3.ONE * 0.1),
		"  heure=", E.clock_text(), "  messages=", E.messages.size())
	await shot("partie chargée")
	quit()
