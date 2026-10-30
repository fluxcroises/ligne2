class_name ChapitreJeu
extends Node
## Ce que tous les chapitres ont en commun pendant le jeu : remettre le détective à sa place
## après un chargement, les messages d'aide de Nadia quand on tourne en rond, et l'écran de fin.
## Chaque chapitre en hérite (Chapitre1Jeu…) et y ajoute ses horaires et sa fin.

## Numéro du chapitre (son contenu : Chapitres.content(number)).
var number := 1
var _station: Node3D
var _idle := 0.0
var _progress := -1
var _ended := false
var _end_screen: CanvasLayer
var _on_continue := Callable()


func _ready() -> void:
	_station = get_parent()
	_ended = Enquete.flags.get("chapitre_%d_fini" % number, false)
	_restore.call_deferred()


## Après un chargement : remettre le détective à sa place et l'horloge à l'heure.
## Renvoie false s'il n'y avait rien à rétablir.
func _restore() -> bool:
	var data := Enquete.pending_load
	Enquete.pending_load = {}
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if data.is_empty() or not player:
		return false
	_station.trafic.time = float(data.get("time", 0.0))
	var p: Array = data.get("player", [])
	if p.size() == 4:
		player.global_position = Vector3(p[0], p[1], p[2])
		player.rotation.y = p[3]
	return true


func _process(delta: float) -> void:
	_hints(delta)


# --- Aides de Nadia ----------------------------------------------------------------

func _hints(delta: float) -> void:
	# toute avancée (pièce, fait appris, déduction) remet le compteur à zéro
	var progress := Enquete.evidence.size() + Enquete.flags.size() + Enquete.solved.size()
	if progress != _progress:
		_progress = progress
		_idle = 0.0
	if not Enquete.hints_enabled or _ended:
		return
	_idle += delta
	var content := Chapitres.content(number)
	if _idle < content.HINT_DELAY:
		return
	_idle = 0.0
	for hint in content.HINTS:
		if Enquete.check(hint[0]) and not Enquete.hints_sent.has(hint[1]):
			Enquete.hints_sent.append(hint[1])
			Enquete.send_to_player("Nadia", hint[1])
			return


# --- Fin du chapitre -------------------------------------------------------------

## Le chapitre est fini : la station suivante se débloque, puis l'écran de fin.
func _finish(next_station: String, summary: String, on_continue := Callable()) -> void:
	_ended = true
	Enquete.flags["chapitre_%d_fini" % number] = true
	if not Enquete.unlocked_stations.has(next_station):
		Enquete.unlocked_stations.append(next_station)
	_on_continue = on_continue
	_show_end_screen([["Fin du chapitre %d" % number, UiTheme.ACCENT], [Chapitres.station(number), UiTheme.TEXT],
		[summary, UiTheme.TEXT], ["Prochaine station : %s." % next_station, UiTheme.ACCENT], ["Entrée : continuer", UiTheme.DIM]])


func _show_end_screen(lines: Array) -> void:
	_end_screen = CanvasLayer.new()
	_end_screen.layer = 5
	add_child(_end_screen)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_screen.add_child(black)
	var col := VBoxContainer.new()
	col.position = Vector2(24, 54)
	col.size = Vector2(272, 140)
	col.add_theme_constant_override("separation", 6)
	col.modulate.a = 0.0
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_screen.add_child(col)
	for line in lines:
		var l := Label.new()
		l.text = line[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(272, 0)
		l.add_theme_color_override("font_color", line[1])
		l.add_theme_font_size_override("font_size", UiTheme.FONT_SIZE + 1)
		col.add_child(l)
	var tween := create_tween()
	tween.tween_property(black, "color:a", 0.92, 2.0)
	tween.tween_property(col, "modulate:a", 1.0, 1.0)


func _input(event: InputEvent) -> void:
	if _end_screen and _end_screen.visible and event.is_action_pressed("ui_accept"):
		_end_screen.hide()
		get_viewport().set_input_as_handled()
		if _on_continue.is_valid():
			_on_continue.call()


## Passe au chapitre suivant : son prologue, une sauvegarde, puis sa scène.
func _next_chapter() -> void:
	Enquete.start_chapter(number + 1)
	Enquete.flags["chapitre_%d_arrivee" % (number + 1)] = false
	get_tree().change_scene_to_file(Chapitres.scene(number + 1))
