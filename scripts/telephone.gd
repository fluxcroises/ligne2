extends CanvasLayer
## Le téléphone du détective : son seul outil, et le menu du jeu.
## Applis : appareil photo, dossier, déductions, messages, plan. Pas de réseau sous terre.
## Se pilote au clavier (flèches, Entrée, Échap), à la souris ou à la manette.

const PHONE := Rect2(194, 6, 120, 228)
const SCREEN_W := 104.0
const TEXT := UiTheme.TEXT
const DIM := UiTheme.DIM
const ACCENT := UiTheme.ACCENT
const KIND_LABEL := {"photo": "Photo", "indice": "Indice", "temoignage": "Témoin"}

var is_open := false
var camera_mode := false

var _stack: Array[Callable] = []
var _phone: Panel
var _time: Label
var _network: Label
var _battery: Label
var _title: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _footer: Label
var _viewfinder: Control
var _viewfinder_info: Label
var _flash: ColorRect
var _toast: Label
var _toast_left := 0.0
var _picked: Array = []          # éléments reliés dans l'appli Déductions
var _player: Node
var _hud: CanvasLayer


func _ready() -> void:
	layer = 3
	_build_phone()
	_build_viewfinder()
	_build_toast()
	Enquete.message_received.connect(_on_message)
	_late_init.call_deferred()


func _late_init() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().current_scene.get_node_or_null("HUD")
	toast("Tab : sortir le téléphone")


func _input(event: InputEvent) -> void:
	if Enquete.in_dialogue:
		return
	if camera_mode:
		if event.is_action_pressed("interact"):
			_take_photo()
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("phone"):
			_leave_camera()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("phone"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time.text = Enquete.clock_text()
	_network.text = "4G" if Enquete.has_network() else "Pas de réseau"
	_network.add_theme_color_override("font_color", TEXT if Enquete.has_network() else UiTheme.ALERT)
	_battery.text = "%d %%" % roundi(Enquete.battery)
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	if _flash.color.a > 0.0:
		_flash.color.a = maxf(0.0, _flash.color.a - delta * 4.0)
	if camera_mode:
		_viewfinder_info.text = "%s   %d %%" % [Enquete.clock_text(), roundi(Enquete.battery)]


# --- Ouvrir, fermer, naviguer --------------------------------------------------

func open() -> void:
	if Enquete.battery <= 0.0:
		toast("Batterie vide.")
		return
	is_open = true
	_phone.show()
	_lock_player(true)
	_stack.clear()
	_show(_home)


func close() -> void:
	is_open = false
	_phone.hide()
	_lock_player(false)


func back() -> void:
	_stack.pop_back()
	if _stack.is_empty():
		close()
	else:
		_stack.back().call()


func toast(text: String) -> void:
	_toast.text = text
	_toast.show()
	_toast_left = 3.0


func _show(screen: Callable) -> void:
	_stack.append(screen)
	screen.call()


func _refresh() -> void:
	if not _stack.is_empty():
		_stack.back().call()


func _lock_player(locked: bool) -> void:
	if _player:
		_player.input_locked = locked
	if _hud:
		_hud.visible = not locked and not camera_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if locked else Input.MOUSE_MODE_CAPTURED


# --- Écrans --------------------------------------------------------------------

func _home() -> void:
	_begin("Téléphone")
	_button("Appareil photo", _open_camera)
	_button("Dossier (%d)" % Enquete.evidence.size(), _show.bind(_dossier))
	var open_deductions := Chapitre1.DEDUCTIONS.filter(func(d): return not Enquete.solved.has(d.id)).size()
	_button("Déductions" + (" (%d)" % open_deductions if open_deductions > 0 else ""), _show.bind(_deductions))
	var unread := Enquete.unread_count()
	_button("Messages" + (" · %d nouveau%s" % [unread, "x" if unread > 1 else ""] if unread > 0 else ""), _show.bind(_messages))
	_button("Recherche", _show.bind(_search))
	_button("Plan", _show.bind(_plan))
	_focus_first()


func _dossier() -> void:
	_begin("Dossier")
	if Enquete.evidence.is_empty():
		_text("Rien pour l'instant. Photographiez les indices.", DIM)
	var chapter := -1
	for item in Enquete.evidence:
		if item.chapter != chapter:
			chapter = item.chapter
			_text("Chapitre %d · %s" % [chapter, Chapitre1.STATION], ACCENT)
		_button("%s · %s" % [KIND_LABEL[item.kind], item.title], _show.bind(_evidence_detail.bind(item)))
	_focus_first()


func _evidence_detail(item: Dictionary) -> void:
	_begin(KIND_LABEL[item.kind])
	if item.texture:
		_picture(item.texture)
	_text(item.title, ACCENT)
	_text(item.text)
	_focus_first()


func _messages() -> void:
	_begin("Messages")
	if not Enquete.has_network():
		_text("Pas de réseau. Les messages arriveront à la surface.", UiTheme.ALERT)
	for name in Enquete.contacts():
		var unread := Enquete.unread_count(name)
		_button(name + (" (%d)" % unread if unread > 0 else ""), _show.bind(_thread.bind(name)))
	_focus_first()


func _thread(contact: String) -> void:
	_begin(contact)
	for m in Enquete.messages:
		if m.from != contact:
			continue
		m.read = true
		_text("%s · %s" % [m.from, m.time], DIM)
		if m.evidence != "":
			_picture(Enquete.evidence_image(m.evidence))
		_text(m.text)
	_focus_last()


func _search() -> void:
	_begin("Recherche")
	if not Enquete.has_network():
		_text("Pas de réseau. Remontez à la surface pour chercher en ligne.", UiTheme.ALERT)
		_focus_first()
		return
	_text("Suggestions :", DIM)
	for s in Chapitre1.SEARCHES:
		if Enquete.check(s.if):
			_button(s.query, _run_search.bind(s))
	_focus_first()


func _run_search(s: Dictionary) -> void:
	if not Enquete.has_network():
		toast("Pas de réseau.")
		return
	if not Enquete.use_battery(Enquete.SEARCH_COST):
		toast("Batterie vide.")
		return
	_show(_search_results.bind(s))


func _search_results(s: Dictionary) -> void:
	_begin("« %s »" % s.query)
	for r in s.results:
		Enquete.apply(r)
		_text("%s · %s" % [r.author, r.time], DIM)
		var id: String = r.get("evidence", "")
		if id != "":
			_picture(Enquete.evidence_image(id))
		_text(r.text)
		if id != "" and not Enquete.has_evidence(id):
			_button("Enregistrer dans le dossier", func() -> void:
				Enquete.add_evidence(id, Enquete.evidence_image(id))
				toast("Ajouté au dossier : " + Chapitre1.EVIDENCE[id].title)
				_refresh())
	_focus_first()


func _deductions() -> void:
	_begin("Déductions")
	for d in Chapitre1.DEDUCTIONS:
		var done := Enquete.solved.has(d.id)
		_button(("Résolue · " if done else "") + d.question, _show.bind(_deduction_editor.bind(d)))
	_focus_first()


func _deduction_editor(d: Dictionary) -> void:
	_picked.clear()
	_begin("Déduction")
	_text(d.question, ACCENT)
	if Enquete.solved.has(d.id):
		_text(d.success)
		_focus_first()
		return
	_text("Reliez 2 à 4 éléments du dossier :", DIM)
	if Enquete.evidence.size() < 2:
		_text("Le dossier est encore trop mince.", DIM)
	for item in Enquete.evidence:
		var b := _button("[ ] " + item.title, Callable())
		b.toggle_mode = true
		b.toggled.connect(func(on: bool) -> void:
			if on and _picked.size() >= 4:
				b.set_pressed_no_signal(false)
				toast("Quatre éléments au plus.")
				return
			if on:
				_picked.append(item.id)
			else:
				_picked.erase(item.id)
			b.text = ("[x] " if on else "[ ] ") + item.title)
	_text("Conclusion :", DIM)
	for i in d.conclusions.size():
		_button(d.conclusions[i], _conclude.bind(d, i))
	_focus_first()


func _conclude(d: Dictionary, conclusion: int) -> void:
	if _picked.size() < 2:
		toast("Reliez au moins deux éléments.")
		return
	var result := Enquete.try_deduction(d.id, _picked, conclusion)
	if result.ok:
		_stack.pop_back()
		_show(_deduction_editor.bind(d))
	toast(result.text if not result.ok else "Déduction juste.")


func _plan() -> void:
	_begin("Plan · ligne 2")
	for s in Panneaux.LINE_2:
		var name: String = s[0]
		var here: bool = name == Chapitre1.STATION
		var unlocked := Enquete.unlocked_stations.has(name)
		var b := _button(("> " if here else "  ") + ("• " if unlocked else "- ") + name, Callable())
		b.add_theme_color_override("font_color", ACCENT if here else (TEXT if unlocked else DIM))
	var place := get_tree().get_first_node_in_group("lieu")
	var trafic: Trafic = place.trafic if place else null
	if trafic:
		_text("Prochains passages à Monceau :", ACCENT)
		for train in trafic.trains:
			var st: Dictionary = trafic.state(train)
			var wait: float = 9.0 - st.k if st.k < 9.0 else (0.0 if st.k < 27.0 else Trafic.CYCLE - st.k + 9.0)
			_text("%s : %s" % [train.destination, "à quai" if wait <= 0.0 else "%d min" % ceili(wait / 60.0)])
	_focus_first()


# --- Appareil photo ------------------------------------------------------------

func _open_camera() -> void:
	camera_mode = true
	_phone.hide()
	_viewfinder.show()
	_lock_player(false)
	if _hud:
		_hud.visible = false


func _leave_camera() -> void:
	camera_mode = false
	_viewfinder.hide()
	_phone.show()
	_lock_player(true)
	_refresh()


func _take_photo() -> void:
	if not Enquete.use_battery(Enquete.PHOTO_COST):
		toast("Batterie vide.")
		_leave_camera()
		close()
		return
	var target := _photo_target()
	Sons.play("declic")
	_viewfinder.hide()
	_toast.hide()
	await RenderingServer.frame_post_draw
	# la photo, c'est l'image du monde 3D seule, sans l'interface
	var texture := ImageTexture.create_from_image(_player.get_viewport().get_texture().get_image())
	_viewfinder.show()
	_flash.color.a = 0.8
	var item: Examinable = target.get("item")
	if item and item.evidence_id != "":
		if target.distance > item.photo_range:
			Enquete.add_photo(texture)
			toast("Trop loin pour servir de preuve.")
		elif Enquete.add_evidence(item.evidence_id, texture):
			Enquete.add_photo(texture, item.evidence_id)
			toast("Ajouté au dossier : " + Chapitre1.EVIDENCE[item.evidence_id].title)
		else:
			Enquete.add_photo(texture, item.evidence_id)
			toast("Déjà dans le dossier.")
	else:
		Enquete.add_photo(texture)
		toast("Photo enregistrée.")


## L'objet au centre du viseur, s'il y en a un, et sa distance.
func _photo_target() -> Dictionary:
	var cam := _player.get_viewport().get_camera_3d() if _player else null
	if not cam:
		return {}
	var from := cam.global_position
	# couche 1 seulement : la vitre du guichet (couche 2) ne gêne pas la photo
	var query := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * 8.0, 1)
	if _player:
		query.exclude = [_player.get_rid()]
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider is Examinable:
		return {}
	return {"item": hit.collider, "distance": from.distance_to(hit.position)}


# --- Construction de l'interface -----------------------------------------------

func _build_phone() -> void:
	_phone = Panel.new()
	_phone.position = PHONE.position
	_phone.size = PHONE.size
	_phone.theme = UiTheme.make()
	_phone.add_theme_stylebox_override("panel", UiTheme.box(Color("#0b0c0f"), Color("#3a3f48"), 2, 7))
	add_child(_phone)
	var screen := Panel.new()
	screen.position = Vector2(6, 10)
	screen.size = Vector2(PHONE.size.x - 12, PHONE.size.y - 22)
	screen.add_theme_stylebox_override("panel", UiTheme.box(Color("#12151b")))
	_phone.add_child(screen)
	var col := VBoxContainer.new()
	col.position = Vector2(2, 1)
	col.size = screen.size - Vector2(4, 2)
	col.add_theme_constant_override("separation", 1)
	screen.add_child(col)

	var status := HBoxContainer.new()
	_time = _label("23:05", TEXT)
	_network = _label("4G", TEXT)
	_network.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_network.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battery = _label("100 %", TEXT)
	for l in [_time, _network, _battery]:
		status.add_child(l)
	col.add_child(status)
	_title = _label("", ACCENT)
	col.add_child(_title)
	col.add_child(_separator())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	col.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	col.add_child(_separator())
	_footer = _label("Échap : retour", DIM)
	col.add_child(_footer)
	_phone.hide()


func _build_viewfinder() -> void:
	_viewfinder = Control.new()
	_viewfinder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewfinder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewfinder)
	# coins du cadre et repère central
	for corner in [Vector2(20, 16), Vector2(292, 16), Vector2(20, 216), Vector2(292, 216)]:
		var horizontal := ColorRect.new()
		horizontal.size = Vector2(8, 1)
		horizontal.position = corner + Vector2(0 if corner.x < 160 else 0, 0 if corner.y < 120 else 7)
		var vertical := ColorRect.new()
		vertical.size = Vector2(1, 8)
		vertical.position = corner + Vector2(0 if corner.x < 160 else 7, 0)
		for r in [horizontal, vertical]:
			r.color = Color(1, 1, 1, 0.8)
			_viewfinder.add_child(r)
	var reticle := Panel.new()
	reticle.position = Vector2(152, 112)
	reticle.size = Vector2(16, 16)
	reticle.add_theme_stylebox_override("panel", UiTheme.box(Color.TRANSPARENT, Color(1, 1, 1, 0.8), 1))
	_viewfinder.add_child(reticle)
	var help := _label("E : photographier · Échap : retour", Color(1, 1, 1, 0.85))
	help.position = Vector2(30, 222)
	_viewfinder.add_child(help)
	_viewfinder_info = _label("", Color(1, 1, 1, 0.85))
	_viewfinder_info.position = Vector2(236, 6)
	_viewfinder.add_child(_viewfinder_info)
	var rec := ColorRect.new()
	rec.color = UiTheme.ALERT
	rec.size = Vector2(4, 4)
	rec.position = Vector2(229, 9)
	_viewfinder.add_child(rec)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_viewfinder.hide()


func _build_toast() -> void:
	_toast = _label("", TEXT)
	_toast.position = Vector2(6, 6)
	_toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	_toast.add_theme_stylebox_override("normal", UiTheme.box(Color(0, 0, 0, 0.7), Color.TRANSPARENT, 0, 0, 2))
	add_child(_toast)
	_toast.hide()


func _on_message(m: Dictionary) -> void:
	Sons.play("vibreur", -12.0)
	if is_open:
		_refresh()
	else:
		toast("Nouveau message : " + m.from)


func _begin(title: String) -> void:
	_title.text = title
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_scroll.scroll_vertical = 0
	_footer.text = "Échap : retour" if _stack.size() > 1 else "Échap : ranger"


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(SCREEN_W, 0)
	if action.is_valid():
		b.pressed.connect(action)
	_list.add_child(b)
	return b


func _text(text: String, color := TEXT) -> Label:
	var l := _label(text, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(SCREEN_W, 0)
	_list.add_child(l)
	return l


func _picture(texture: Texture2D) -> void:
	var r := TextureRect.new()
	r.texture = texture
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(SCREEN_W, 72)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_list.add_child(r)


func _focus_first() -> void:
	for child in _list.get_children():
		if child is Button:
			_grab.call_deferred(child)
			return


func _grab(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()


func _focus_last() -> void:
	_scroll.set_deferred("scroll_vertical", 100000)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", UiTheme.FONT_SIZE)
	return l


func _separator() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color("#2a2f38")
	r.custom_minimum_size = Vector2(0, 1)
	return r
