extends CanvasLayer
## Réticule, nom de l'objet visé et fenêtre d'examen.

const TEXT_COLOR := Color(0.92, 0.9, 0.82)

var _prompt: Label
var _panel: PanelContainer
var _panel_text: Label


func _ready() -> void:
	layer = 2
	var crosshair := ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.7)
	crosshair.size = Vector2(1, 1)
	crosshair.position = Vector2(160, 120)
	add_child(crosshair)

	_prompt = _label(8)
	_prompt.position = Vector2(0, 128)
	_prompt.size = Vector2(320, 12)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.88)
	style.border_color = Color(0.5, 0.5, 0.45)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.position = Vector2(16, 168)
	_panel.custom_minimum_size = Vector2(288, 0)
	_panel_text = _label(8)
	_panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_text.custom_minimum_size = Vector2(276, 0)
	_panel.add_child(_panel_text)
	_panel.hide()
	add_child(_panel)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.focus_changed.connect(_on_focus_changed)
		player.examined.connect(_on_examined)


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label


func _on_focus_changed(target: Examinable) -> void:
	_prompt.text = target.title if target else ""
	if not target:
		_panel.hide()


func _on_examined(target: Examinable) -> void:
	_panel_text.text = "%s\n%s" % [target.title.to_upper(), target.description]
	_panel.visible = not _panel.visible
