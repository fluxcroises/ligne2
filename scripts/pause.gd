extends CanvasLayer
## Menu pause (Échap ou Start) : Reprendre, Réglages, Sauvegarder et revenir au titre, Quitter.
## Le jeu est figé tant qu'il est ouvert.

var _root: Control
var _menu: VBoxContainer
var _settings: PanneauReglages
var _debug: MenuDebug


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.make()
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var title := Label.new()
	title.text = "Pause"
	title.position = Vector2(0, 60)
	title.size = Vector2(320, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	_root.add_child(title)
	_menu = VBoxContainer.new()
	_menu.position = Vector2(90, 80)
	_menu.custom_minimum_size = Vector2(140, 0)
	_menu.add_theme_constant_override("separation", 3)
	_root.add_child(_menu)
	var items := [["Reprendre", close], ["Réglages", _open_settings],
			["Sauvegarder et revenir au titre", _to_title], ["Quitter le jeu", _quit]]
	if MenuDebug.enabled():
		items.insert(2, ["Débogage", _open_debug])
	for item in items:
		var b := Button.new()
		b.text = item[0]
		b.pressed.connect(item[1])
		_menu.add_child(b)
	_settings = PanneauReglages.new()
	_settings.position = Vector2(66, 10)
	_settings.hide()
	_settings.closed.connect(func() -> void:
		_settings.hide()
		_menu.show()
		(_menu.get_child(0) as Button).grab_focus())
	_root.add_child(_settings)
	if MenuDebug.enabled():
		_debug = MenuDebug.new()
		_debug.position = Vector2(66, 30)
		_debug.hide()
		_debug.closed.connect(func() -> void:
			_debug.hide()
			if is_inside_tree() and _root.visible:
				_menu.show()
				(_menu.get_child(0) as Button).grab_focus())
		_root.add_child(_debug)
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _root.visible:
		if not _settings.visible and not (_debug and _debug.visible):
			close()
	elif not Enquete.in_dialogue:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_root.show()
	_menu.show()
	_settings.hide()
	if _debug:
		_debug.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(_menu.get_child(0) as Button).grab_focus()


func close() -> void:
	_root.hide()
	get_tree().paused = false
	var phone := get_tree().current_scene.get_node_or_null("Telephone")
	if not (phone and phone.is_open):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	_menu.hide()
	_settings.show()


func _open_debug() -> void:
	_menu.hide()
	_debug.show()


func _to_title() -> void:
	Enquete.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/titre.tscn")


func _quit() -> void:
	Enquete.save_game()
	get_tree().quit()
