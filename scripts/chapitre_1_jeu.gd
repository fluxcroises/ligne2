extends Node
## Le déroulé du chapitre 1 à Monceau : horaires (rondes de Sylvain, fermeture du kiosque),
## messages d'aide de Nadia quand on tourne en rond, et fin du chapitre quand le détective
## prend le métro direction Nation après les aveux de Sylvain.

var _station: Node3D
var _ronde := false
var _kiosk_open := true
var _idle := 0.0
var _progress := -1
var _ended := false
var _end_screen: CanvasLayer


func _ready() -> void:
	_station = get_parent()
	_ended = Enquete.flags.get("chapitre_1_fini", false)
	_restore.call_deferred()


## Après un chargement : remettre le détective à sa place et l'horloge à l'heure.
func _restore() -> void:
	var data := Enquete.pending_load
	Enquete.pending_load = {}
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if data.is_empty() or not player:
		return
	_station.trafic.time = float(data.get("time", 0.0))
	var p: Array = data.get("player", [])
	if p.size() == 4:
		player.global_position = Vector3(p[0], p[1], p[2])
		player.rotation.y = p[3]


func _process(delta: float) -> void:
	var m := Enquete.minutes()
	if not Enquete.in_dialogue:
		_schedule(m)
	_hints(delta)
	_check_end()


# --- Horaires --------------------------------------------------------------------

static func on_ronde(m: int) -> bool:
	return m >= Chapitre1.RONDE_FIRST and (m - Chapitre1.RONDE_FIRST) % Chapitre1.RONDE_EVERY < Chapitre1.RONDE_LENGTH


func _schedule(m: int) -> void:
	var sylvain: Personnage = _station.people.get("sylvain")
	var ronde := on_ronde(m)
	if sylvain and ronde != _ronde:
		_ronde = ronde
		if ronde:
			sylvain.move_to(_station.SYLVAIN_QUAI, -PI / 2)
		else:
			sylvain.move_to(_station.SYLVAIN_GUICHET, _station.SYLVAIN_GUICHET_YAW)
		_station.loge_door.rotation.y = deg_to_rad(_station.LOGE_DOOR_OPEN) if ronde else 0.0
	if _kiosk_open and m >= Chapitre1.KIOSK_CLOSES:
		_kiosk_open = false
		var roche: Node = _station.people.get("roche")
		if roche:
			_station.people.erase("roche")
			roche.queue_free()
		_station.kiosk_shutter.show()


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
	if _idle < Chapitre1.HINT_DELAY:
		return
	_idle = 0.0
	for hint in Chapitre1.HINTS:
		if Enquete.check(hint[0]) and not Enquete.hints_sent.has(hint[1]):
			Enquete.hints_sent.append(hint[1])
			Enquete.send_to_player("Nadia", hint[1])
			return


# --- Fin du chapitre -------------------------------------------------------------

func _check_end() -> void:
	if _ended or not Enquete.flags.get("sylvain_aveu", false):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var trafic: Trafic = _station.trafic
	var train := trafic.train_at(player.global_position) if player else null
	if train and train.destination == "Nation" and trafic.is_moving(train):
		_ended = true
		Enquete.flags["chapitre_1_fini"] = true
		if not Enquete.unlocked_stations.has("Villiers"):
			Enquete.unlocked_stations.append("Villiers")
		_show_end_screen()


func _show_end_screen() -> void:
	_end_screen = CanvasLayer.new()
	_end_screen.layer = 5
	add_child(_end_screen)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_screen.add_child(black)
	var col := VBoxContainer.new()
	col.position = Vector2(24, 54)
	col.size = Vector2(272, 140)
	col.add_theme_constant_override("separation", 6)
	col.modulate.a = 0.0
	_end_screen.add_child(col)
	for line in [["Fin du chapitre 1", UiTheme.ACCENT], ["Monceau", UiTheme.TEXT],
			["Karim n'a pas eu de malaise. Un faux agent l'a fait sortir par la porte de service, et Sylvain a regardé ailleurs pour quelques billets.", UiTheme.TEXT],
			["Prochaine station : Villiers.", UiTheme.ACCENT],
			["Entrée : continuer", UiTheme.DIM]]:
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
