extends SceneTree
## Version de débogage : le menu de l'écran titre, le saut au chapitre 3, et le menu de la pause.
func _initialize() -> void:
	change_scene_to_file("res://scenes/titre.tscn")
	for f in 5: await process_frame
	var menu = current_scene._menu
	print("débogage actif : ", load("res://scripts/menu_debug.gd").enabled(), "  boutons : ", menu.get_children().map(func(b): return b.text))
	current_scene._open_debug()
	for f in 3: await process_frame
	var dbg = current_scene._debug
	var col = dbg.get_child(0)
	print("menu : ", col.get_children().filter(func(c): return c is Button).map(func(b): return b.text))
	for b in col.get_children():
		if b is Button and b.text.begins_with("Chapitre 3"):
			b.pressed.emit()
	for f in 10: await process_frame
	var E = root.get_node("Enquete")
	print("scène : ", current_scene.scene_file_path.get_file(), "  chapitre ", E.chapter, "  dossier ", E.evidence.size(),
		"  déductions ", E.solved, "  stations ", E.unlocked_stations)
	var pause = current_scene.get_node("Pause")
	pause.open()
	for f in 3: await process_frame
	print("pause : ", pause._menu.get_children().map(func(b): return b.text))
	pause._open_debug()
	for f in 3: await process_frame
	var pcol = pause._debug.get_child(0)
	for b in pcol.get_children():
		if b is Button and b.text.begins_with("Toutes les pièces"):
			b.pressed.emit()
	print("après « toutes les pièces » : dossier ", E.evidence.size(), "  vitrine ", E.has_evidence("vitrine"))
	quit()
