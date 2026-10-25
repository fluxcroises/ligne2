class_name Panneaux
## Panneaux RATP dessinés par le jeu, d'après des photos prises comme modèles :
## panneau de direction (blanc, Ⓜ, pastille de la ligne, terminus, flèche ; bande « Sortie »)
## et plan de ligne affiché sur les quais. Chaque panneau est rendu une fois dans une
## petite texture, à la résolution des autres textures du jeu.

const NAVY := Color("#1b2a6b")
const LINE_2_BLUE := Color("#0055c8")
const PANEL_BEIGE := Color("#e6e2d4")

## Les stations de la ligne 2, de Porte Dauphine à Nation, avec leurs correspondances
## (plan de ligne RATP, novembre 2023).
const LINE_2 := [
	["Porte Dauphine", "RER C"], ["Victor Hugo", ""], ["Charles de Gaulle – Étoile", "M1, M6, RER A"],
	["Ternes", ""], ["Courcelles", ""], ["Monceau", ""], ["Villiers", "M3"], ["Rome", ""],
	["Place de Clichy", "M13"], ["Blanche", ""], ["Pigalle", "M12"], ["Anvers", "funiculaire de Montmartre"],
	["Barbès – Rochechouart", "M4"], ["La Chapelle", "RER B, D, E, Gare du Nord"], ["Stalingrad", "M5, M7"],
	["Jaurès", "M5, M7bis"], ["Colonel Fabien", ""], ["Belleville", "M11"], ["Couronnes", ""],
	["Ménilmontant", ""], ["Père Lachaise", "M3"], ["Philippe Auguste", ""], ["Alexandre Dumas", ""],
	["Avron", ""], ["Nation", "M1, M6, M9, RER A"],
]


## Les stations à partir de `from` jusqu'au terminus `terminus` (inclus).
static func stations_towards(from: String, terminus: String) -> Array[String]:
	var names: Array[String] = []
	for s in LINE_2:
		names.append(s[0])
	if terminus == LINE_2[0][0]:
		names.reverse()
	return names.slice(names.find(from))


## Panneau de direction : une rangée par élément de `rows`, chacune ["ligne", terminus] ou
## ["sortie", texte]. 96 px de large, 16 px par rangée.
static func direction(parent: Node, rows: Array) -> ViewportTexture:
	var vp := _viewport(parent, Vector2i(96, 16 * rows.size()))
	for i in rows.size():
		var y := 16.0 * i
		if rows[i][0] == "sortie":
			_rect(vp, NAVY, Rect2(0, y, 96, 16))
			_text(vp, rows[i][1], Color.WHITE, 9, Vector2(5, y + 1), true)
			_arrow(vp, Color.WHITE, Vector2(81, y + 3))
		else:
			_rect(vp, Color.WHITE, Rect2(0, y, 96, 16))
			_rect(vp, NAVY, Rect2(0, y, 96, 1))
			_metro(vp, Vector2(8, y + 8.5), 6)
			_line_disc(vp, Vector2(21, y + 8.5), 6)
			_text(vp, rows[i][1], NAVY, 9 if rows[i][1].length() <= 8 else 8, Vector2(29, y + 1), true)
			_arrow(vp, NAVY, Vector2(81, y + 3))
	return vp.get_texture()


## Bandeau lumineux turquoise des guichets (« Services », « Tickets ») : pastille blanche
## avec une lettre, texte blanc. 128 × 16 px.
static func band(parent: Node, letter: String, text: String) -> ViewportTexture:
	var vp := _viewport(parent, Vector2i(128, 16))
	_rect(vp, Color("#18b0a8"), Rect2(0, 0, 128, 16))
	_disc(vp, Color.TRANSPARENT, Color.WHITE, Vector2(9, 8), 6)
	_centered(vp, letter, Color.WHITE, Vector2(9, 8), 6)
	_text(vp, text, Color.WHITE, 10, Vector2(19, 0), true)
	return vp.get_texture()


## Plan de ligne d'un quai : en-tête (Ⓜ ② terminus →), stations jusqu'au terminus,
## la station courante en surbrillance, bande bleu nuit en bas. 72 × 128 px.
static func line_plan(parent: Node, from: String, terminus: String) -> ViewportTexture:
	var vp := _viewport(parent, Vector2i(72, 128))
	_rect(vp, PANEL_BEIGE, Rect2(0, 0, 72, 128))
	_rect(vp, Color.WHITE, Rect2(0, 0, 72, 14))
	_rect(vp, NAVY, Rect2(0, 0, 72, 1))
	_metro(vp, Vector2(7, 7.5), 5)
	_line_disc(vp, Vector2(18, 7.5), 5)
	var title := "Pte Dauphine" if terminus == "Porte Dauphine" else terminus
	_text(vp, title, NAVY, 8 if title.length() <= 8 else 7, Vector2(25, 1), true)
	var stations := stations_towards(from, terminus)
	var step := minf(9.0, 100.0 / stations.size())
	var y0 := 20.0
	_rect(vp, NAVY, Rect2(13, y0, 2, step * (stations.size() - 1)))
	for i in stations.size():
		var y := y0 + step * i
		_disc(vp, Color.WHITE, NAVY, Vector2(14, y), 2)
		if stations[i] == from:
			_rect(vp, NAVY, Rect2(18, y - 3, 44, 6))
		_text(vp, stations[i], Color.WHITE if stations[i] == from else NAVY, 5, Vector2(19, y - 4.5), false)
	_rect(vp, NAVY, Rect2(0, 122, 72, 6))
	return vp.get_texture()


## Description lisible d'un plan de ligne, pour l'examen.
static func line_plan_text(from: String, terminus: String) -> String:
	var parts: Array[String] = []
	for name in stations_towards(from, terminus).slice(1):
		var connections := ""
		for s in LINE_2:
			if s[0] == name:
				connections = s[1]
		parts.append(name + (" (%s)" % connections if connections != "" else ""))
	return "Ligne 2, direction %s. Après Monceau : %s." % [terminus, ", ".join(parts)]


# --- Dessin --------------------------------------------------------------------

static func _viewport(parent: Node, size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	# Rendu continu quelques instants, le temps que tout soit prêt, puis l'image est figée.
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(vp)
	parent.get_tree().create_timer(0.5).timeout.connect(
		func(): vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	return vp


static func _rect(parent: Node, color: Color, r: Rect2) -> void:
	var c := ColorRect.new()
	c.color = color
	c.position = r.position
	c.size = r.size
	parent.add_child(c)


static func _disc(parent: Node, fill: Color, ring: Color, center: Vector2, radius: float) -> Panel:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(radius) + 1)
	if ring.a > 0.0:
		style.border_color = ring
		style.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", style)
	p.position = center - Vector2(radius, radius)
	p.size = Vector2(radius, radius) * 2
	parent.add_child(p)
	return p


static func _metro(parent: Node, center: Vector2, radius: float) -> void:
	_disc(parent, Color.WHITE, NAVY, center, radius)
	_centered(parent, "M", NAVY, center, radius)


static func _line_disc(parent: Node, center: Vector2, radius: float) -> void:
	_disc(parent, LINE_2_BLUE, Color.TRANSPARENT, center, radius)
	_centered(parent, "2", Color.WHITE, center, radius)


static func _centered(parent: Node, s: String, color: Color, center: Vector2, radius: float) -> void:
	var l := _text(parent, s, color, int(radius * 1.6), center - Vector2(radius, radius + 1), true)
	l.size = Vector2(radius, radius) * 2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Flèche « → » de 11 × 10 px.
static func _arrow(parent: Node, color: Color, pos: Vector2) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = pos
	poly.polygon = PackedVector2Array([Vector2(0, 4), Vector2(6, 4), Vector2(6, 1), Vector2(11, 5),
		Vector2(6, 9), Vector2(6, 6), Vector2(0, 6)])
	parent.add_child(poly)


static func _text(parent: Node, s: String, color: Color, font_size: int, pos: Vector2, bold: bool) -> Label:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if bold:
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 0.8
		l.add_theme_font_override("font", f)
	parent.add_child(l)
	return l
