class_name PanneauReglages
extends PanelContainer
## Panneau des réglages, utilisé par l'écran titre et le menu pause.

signal closed


func _ready() -> void:
	theme = UiTheme.make()
	add_theme_stylebox_override("panel", UiTheme.box(Color(0.04, 0.05, 0.07, 0.96), Color("#3a3f48"), 1, 3, 6))
	process_mode = Node.PROCESS_MODE_ALWAYS
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	add_child(col)
	var title := Label.new()
	title.text = "Réglages"
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	col.add_child(title)

	_slider(col, "Sensibilité de la souris", 0.3, 2.5, Reglages.mouse_sensitivity,
		func(v: float) -> void: Reglages.mouse_sensitivity = v)
	_check(col, "Inverser l'axe vertical", Reglages.invert_y, func(on: bool) -> void: Reglages.invert_y = on)
	_slider(col, "Volume", 0.0, 1.0, Reglages.volume, func(v: float) -> void: Reglages.volume = v)
	_check(col, "Aides de Nadia", Reglages.hints, func(on: bool) -> void: Reglages.hints = on)
	var wobble := OptionButton.new()
	for name in Reglages.WOBBLE:
		wobble.add_item("Tremblement : " + name)
		if name == Reglages.wobble:
			wobble.select(wobble.item_count - 1)
	wobble.item_selected.connect(func(i: int) -> void:
		Reglages.wobble = Reglages.WOBBLE.keys()[i]
		Reglages.save())
	col.add_child(wobble)
	_check(col, "Plein écran", Reglages.fullscreen, func(on: bool) -> void: Reglages.fullscreen = on)
	var back := Button.new()
	back.text = "Retour"
	back.pressed.connect(func() -> void:
		Reglages.save()
		closed.emit())
	col.add_child(back)
	var first := col.get_child(2) as Control   # premier curseur
	visibility_changed.connect(func() -> void:
		if visible:
			first.grab_focus.call_deferred())


func _slider(col: VBoxContainer, label: String, lo: float, hi: float, value: float, on_change: Callable) -> void:
	var l := Label.new()
	l.text = label
	l.add_theme_color_override("font_color", UiTheme.DIM)
	col.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(170, 10)
	s.value_changed.connect(func(v: float) -> void:
		on_change.call(v)
		Reglages.save())
	col.add_child(s)


func _check(col: VBoxContainer, label: String, value: bool, on_change: Callable) -> void:
	var c := CheckButton.new()
	c.text = label
	c.button_pressed = value
	c.toggled.connect(func(on: bool) -> void:
		on_change.call(on)
		Reglages.save())
	col.add_child(c)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		Reglages.save()
		closed.emit()
		get_viewport().set_input_as_handled()
