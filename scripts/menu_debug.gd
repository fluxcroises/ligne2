class_name MenuDebug
extends PanelContainer
## Menu de la version de débogage (et de l'éditeur) : aller directement à un chapitre, recevoir
## toutes les pièces du chapitre en cours, résoudre ses déductions. Absent de la version normale.

signal closed


## Vrai dans la version « debug » (fonctionnalité d'export « debug_menu ») et dans l'éditeur.
static func enabled() -> bool:
	return OS.has_feature("debug_menu") or OS.has_feature("editor")


func _ready() -> void:
	theme = UiTheme.make()
	add_theme_stylebox_override("panel", UiTheme.box(Color(0.12, 0.04, 0.04, 0.96), Color("#a83a3a"), 1, 3, 6))
	process_mode = Node.PROCESS_MODE_ALWAYS
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	add_child(col)
	var title := Label.new()
	title.text = "Débogage"
	title.add_theme_color_override("font_color", UiTheme.ALERT)
	col.add_child(title)
	for n in range(1, Chapitres.LAST + 1):
		_button(col, "Chapitre %d · %s" % [n, Chapitres.station(n)], _go.bind(n))
	if get_tree().get_first_node_in_group("lieu"):
		_button(col, "Toutes les pièces du chapitre en cours", func() -> void:
			Enquete.debug_give_chapter(Enquete.chapter)
			closed.emit())
		_button(col, "Résoudre les déductions du chapitre", func() -> void:
			Enquete.debug_solve_chapter(Enquete.chapter)
			closed.emit())
	_button(col, "Retour", func() -> void: closed.emit())
	visibility_changed.connect(func() -> void:
		if visible:
			(col.get_child(1) as Button).grab_focus.call_deferred())


func _button(col: VBoxContainer, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	col.add_child(b)


func _go(n: int) -> void:
	get_tree().paused = false
	Enquete.debug_start(n)
	get_tree().change_scene_to_file(Chapitres.scene(n))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
