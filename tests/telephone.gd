extends SceneTree
var n := 0
func shot(label: String) -> void:
	for f in 4: await process_frame
	var img := root.get_texture().get_image()
	img.resize(640, 480, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/ph_%d.png" % [OS.get_environment("CAPTURES"), n])
	print("capture ", n, " : ", label)
	n += 1

func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	for f in 3: await process_frame

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for f in 5: await process_frame
	var phone = current_scene.get_node("Telephone")
	var player = current_scene.get_node("Player")
	var E = root.get_node("Enquete")
	print("messages au départ : ", E.messages.size(), "  dossier : ", E.evidence.map(func(e): return e.id))
	await press("phone")
	print("ouvert par Tab : ", phone.is_open, "  joueur bloqué : ", player.input_locked)
	await shot("accueil")
	phone._show(phone._messages)
	phone._show(phone._thread.bind("Nadia"))
	await shot("messages de Nadia")
	await press("ui_cancel"); await press("ui_cancel"); await press("ui_cancel")
	print("fermé par Échap x3 : ", not phone.is_open, "  joueur libre : ", not player.input_locked)

	# sous terre : pas de réseau
	player.global_position = Vector3(17.0, -6.45, 21.6)
	for f in 20: await physics_frame
	E.send_to_player("Nadia", "Vous avez trouvé quelque chose ?")
	print("sous terre, réseau=", E.has_network(), " messages=", E.messages.size())
	# photo du badge : d'abord de loin, puis bien cadrée
	player.rotation = Vector3(0, deg_to_rad(-60), 0)
	player.get_node("Head").rotation.x = deg_to_rad(-30)
	await press("phone")
	phone._open_camera()
	player.global_position = Vector3(15.5, -6.45, 22.0)
	player.look_at(Vector3(18.95, -5.0, 20.75)); player.rotation.x = 0; player.rotation.z = 0
	var head = player.get_node("Head")
	var cam = player.get_node("Head/Camera3D")
	for f in 10: await physics_frame
	head.rotation.x = -atan2(cam.global_position.y - (-6.47), Vector2(18.95 - cam.global_position.x, 20.75 - cam.global_position.z).length())
	for f in 10: await physics_frame
	await press("interact")
	for f in 10: await process_frame
	print("de loin : ", phone._toast.text)
	player.global_position = Vector3(18.95, -6.45, 21.7)
	player.rotation = Vector3.ZERO
	head.rotation.x = deg_to_rad(-58)
	for f in 15: await physics_frame
	await shot("viseur sur le badge")
	await press("interact")
	for f in 10: await process_frame
	print("bien cadrée : ", phone._toast.text, "  batterie=", E.battery)
	await press("ui_cancel")
	phone._show(phone._dossier)
	await shot("dossier")
	phone._show(phone._evidence_detail.bind(E.evidence.filter(func(e): return e.id == "badge")[0]))
	await shot("badge dans le dossier")
	phone._stack.clear(); phone._show(phone._messages)
	await shot("messages sous terre")
	# déduction
	E.add_evidence("photo_voyageur"); E.add_evidence("cahier"); E.add_evidence("serrure")
	print("faux éléments : ", E.try_deduction("faux_agent", ["badge", "karim"], 2).text)
	print("fausse conclusion : ", E.try_deduction("faux_agent", ["badge", "serrure", "photo_voyageur", "cahier"], 0).text)
	print("juste : ", E.try_deduction("faux_agent", ["cahier", "badge", "serrure", "photo_voyageur"], 2).ok)
	E.solved.clear()
	phone._stack.clear(); phone._show(phone._deductions); phone._show(phone._deduction_editor.bind(Chapitre1.DEDUCTIONS[0]))
	await shot("déduction")
	phone._stack.clear(); phone._show(phone._plan)
	await shot("plan")
	phone.close()
	# retour à la surface : le message arrive
	player.global_position = Vector3(0, 0.1, -10)
	for f in 30: await physics_frame
	print("à la surface, réseau=", E.has_network(), " messages=", E.messages.size(), " toast=", phone._toast.text)
	await shot("notification")
	quit()
