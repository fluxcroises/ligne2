extends CanvasLayer
## Boîte de dialogue : répliques qui s'affichent lettre à lettre, puis choix de questions.
## À tout moment, on peut montrer une pièce du dossier. Les dialogues sont décrits dans
## Chapitre1.DIALOGUES ; les conditions et effets passent par Enquete.check et Enquete.apply.

const BOX_SPEECH := Rect2(8, 160, 304, 74)
const BOX_CHOICES := Rect2(8, 104, 304, 130)
const CHARS_PER_SECOND := 55.0

var active := false

var _who: Personnage
var _data: Dictionary
var _lines: Array = []           # répliques restant à dire
var _then: Callable              # ce qui suit la dernière réplique
var _speaking := false           # une réplique est affichée, on attend la suite
var _box: Panel
var _name: Label
var _text: Label
var _more: Label
var _scroll: ScrollContainer
var _choices: VBoxContainer
var _typing := false
var _player: Node
var _hud: CanvasLayer


func _ready() -> void:
	layer = 4
	_build()
	_connect_player.call_deferred()


func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().current_scene.get_node_or_null("HUD")
	if _player:
		_player.examined.connect(func(target: Examinable) -> void:
			if target is Personnage:
				start(target))


func start(who: Personnage) -> void:
	_who = who
	_data = Chapitre1.DIALOGUES[who.dialogue_id]
	active = true
	Enquete.in_dialogue = true
	_box.show()
	_name.text = _data.name
	if _player:
		_player.input_locked = true
		who.face(_player.global_position)
	if _hud:
		_hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var first := "hub" if Enquete.flags.get("vu_" + who.dialogue_id, false) else "debut"
	Enquete.flags["vu_" + who.dialogue_id] = true
	_go(first)


func finish() -> void:
	active = false
	_speaking = false
	_typing = false
	_lines.clear()
	_set_choices()
	Enquete.in_dialogue = false
	_box.hide()
	if _player:
		_player.input_locked = false
	if _hud:
		_hud.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if not active:
		return
	var advance := event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	if _speaking:
		if advance:
			if _typing:
				_text.visible_ratio = 1.0
				_typing = false
			else:
				_next_line()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _typing:
		var total := maxi(1, _text.get_total_character_count())
		_text.visible_ratio = minf(1.0, _text.visible_ratio + delta * CHARS_PER_SECOND / total)
		_typing = _text.visible_ratio < 1.0
	_more.visible = active and _speaking and not _typing


# --- Déroulé -------------------------------------------------------------------

## Aller à un nœud : appliquer ses effets, dire ses répliques, puis proposer ses choix
## (ou passer au nœud suivant : `goto`, sinon le nœud « hub »).
func _go(node_id: String) -> void:
	if not active:
		return
	var node: Dictionary = _data.nodes[node_id]
	for title in Enquete.apply(node):
		_notify("Ajouté au dossier : " + title)
	if node.has("choices"):
		_then = _show_choices.bind(node_id)
	else:
		_then = _go.bind(node.get("goto", "hub"))
	_lines = node.get("lines", []).duplicate()
	_next_line()


func _next_line() -> void:
	if _lines.is_empty():
		_then.call()
		return
	var line: String = _lines.pop_front()
	_set_speech(line, UiTheme.DIM if line.begins_with("(") else UiTheme.TEXT)


func _show_choices(node_id: String) -> void:
	var node: Dictionary = _data.nodes[node_id]
	_set_choices()
	for c in node.choices:
		if Enquete.check(c[2]):
			var key := "lu_%s_%s" % [_who.dialogue_id, c[1]]
			var b := _choice(c[0], func() -> void:
				Enquete.flags[key] = true
				_go(c[1]))
			if Enquete.flags.get(key, false):
				b.add_theme_color_override("font_color", UiTheme.DIM)
	_choice("Montrer une pièce du dossier…", _show_picker)
	_choice("Partir", finish)
	_focus_first()


func _show_picker() -> void:
	_set_choices()
	_text.text = "Montrer quoi ?"
	if Enquete.evidence.is_empty():
		_text.text = "Le dossier est vide."
	for item in Enquete.evidence:
		_choice(item.title, _show_evidence.bind(item.id))
	_choice("Retour", _show_choices.bind("hub"))
	_focus_first()


func _show_evidence(id: String) -> void:
	var reaction: Variant = _data.show.get(id, _data.show.default)
	if reaction is Array:
		for option in reaction:
			if Enquete.check(option[0]):
				reaction = option[1]
				break
	_go(reaction)


# --- Interface -----------------------------------------------------------------

func _set_speech(line: String, color: Color) -> void:
	_resize(BOX_SPEECH)
	_scroll.hide()
	_text.text = line
	_text.add_theme_color_override("font_color", color)
	_text.visible_ratio = 0.0
	_typing = true
	_speaking = true


func _set_choices() -> void:
	_resize(BOX_CHOICES)
	_typing = false
	_speaking = false
	_text.visible_ratio = 1.0
	_scroll.show()
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()


func _choice(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(286, 0)
	b.pressed.connect(action)
	_choices.add_child(b)
	return b


func _focus_first() -> void:
	if _choices.get_child_count() > 0:
		_grab.call_deferred(_choices.get_child(0))


func _grab(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()


func _notify(text: String) -> void:
	var phone := get_tree().current_scene.get_node_or_null("Telephone")
	if phone:
		phone.toast(text)


func _resize(r: Rect2) -> void:
	_box.position = r.position
	_box.size = r.size
	_text.size.x = r.size.x - 16
	_scroll.position = Vector2(8, 46)
	_scroll.size = Vector2(r.size.x - 12, r.size.y - 52)
	_more.position = Vector2(r.size.x - 18, r.size.y - 14)


func _build() -> void:
	_box = Panel.new()
	_box.theme = UiTheme.make()
	_box.add_theme_stylebox_override("panel", UiTheme.box(Color(0.04, 0.05, 0.07, 0.94), Color("#3a3f48"), 1, 3))
	add_child(_box)
	_name = Label.new()
	_name.position = Vector2(8, 4)
	_name.add_theme_color_override("font_color", UiTheme.ACCENT)
	_box.add_child(_name)
	_text = Label.new()
	_text.position = Vector2(8, 16)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(288, 0)
	_box.add_child(_text)
	_more = Label.new()
	_more.text = "▼"
	_more.add_theme_color_override("font_color", UiTheme.ACCENT)
	_box.add_child(_more)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_box.add_child(_scroll)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 2)
	_scroll.add_child(_choices)
	_resize(BOX_SPEECH)
	_box.hide()
