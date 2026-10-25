extends Control
## Écran titre : plaque émaillée « LIGNE 2 » sur une vue du quai de Monceau, puis
## Continuer (s'il y a une sauvegarde), Nouvelle partie, Réglages, Quitter.

const MAIN := "res://scenes/main.tscn"
const ENAMEL := Color("#e8d24a")     # jaune émail des plaques Guimard
const FONTE := Color("#1f3a2e")      # vert fonte

var _menu: VBoxContainer
var _settings: PanneauReglages


func _ready() -> void:
	Sons.playing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://textures/titre_fond.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.03, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	# plaque émaillée, comme l'enseigne de la bouche Guimard
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiTheme.box(ENAMEL, FONTE, 3, 12, 4))
	plate.position = Vector2(84, 34)
	plate.custom_minimum_size = Vector2(152, 0)
	add_child(plate)
	var title := Label.new()
	title.text = "LIGNE 2"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", FONTE)
	title.add_theme_font_size_override("font_size", 24)
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 1.0
	title.add_theme_font_override("font", bold)
	plate.add_child(title)
	var sub := Label.new()
	sub.text = "Chapitre 1 · Monceau"
	sub.position = Vector2(0, 82)
	sub.size = Vector2(320, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", UiTheme.TEXT)
	sub.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(sub)

	_menu = VBoxContainer.new()
	_menu.position = Vector2(110, 110)
	_menu.custom_minimum_size = Vector2(100, 0)
	_menu.add_theme_constant_override("separation", 3)
	add_child(_menu)
	if Enquete.has_save():
		_button("Continuer", _continue)
	_button("Nouvelle partie", _new_game)
	_button("Réglages", _open_settings)
	_button("Quitter", func() -> void: get_tree().quit())
	(_menu.get_child(0) as Button).grab_focus.call_deferred()

	_settings = PanneauReglages.new()
	_settings.position = Vector2(70, 24)
	_settings.hide()
	_settings.closed.connect(_close_settings)
	add_child(_settings)


func _button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	_menu.add_child(b)


func _continue() -> void:
	if Enquete.load_game():
		get_tree().change_scene_to_file(MAIN)


func _new_game() -> void:
	Enquete.new_game()
	get_tree().change_scene_to_file(MAIN)


func _open_settings() -> void:
	_menu.hide()
	_settings.show()


func _close_settings() -> void:
	_settings.hide()
	_menu.show()
	(_menu.get_child(0) as Button).grab_focus()
