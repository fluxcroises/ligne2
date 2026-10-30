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


## Panneau de direction : une rangée par élément de `rows`, chacune ["ligne", terminus],
## ["ligne3", texte] (correspondance avec la ligne 3) ou ["sortie", texte].
## 96 px de large, 16 px par rangée.
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
			if rows[i][0] == "ligne3":
				_line_disc(vp, Vector2(21, y + 8.5), 6, "3", Color(LINE_COLORS["3"]))
			else:
				_line_disc(vp, Vector2(21, y + 8.5), 6)
			var size := 9 if rows[i][1].length() <= 8 else (8 if rows[i][1].length() <= 11 else 6)
			_text(vp, rows[i][1], NAVY, size, Vector2(29, y + 1 + (9 - size) / 2.0), true)
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


## Face avant d'une rame MF01, d'après une illustration fournie comme modèle : caisse vert
## d'eau, girouette (« 2 » et la destination en orange), grand pare-brise, bandeau gris foncé
## avec numéro de rame et feux ronds, jupe blanche et attelage. 64 × 80 px.
static func mf01_front(parent: Node, destination: String, number: String) -> ViewportTexture:
	var vp := _viewport(parent, Vector2i(64, 80))
	var teal := Color("#16a394")
	var orange := Color("#ff8a1e")
	_rect(vp, Color("#1a1d20"), Rect2(0, 0, 64, 80))
	_rect(vp, teal, Rect2(2, 0, 60, 62))
	_rect(vp, Color("#0d0f10"), Rect2(10, 3, 44, 8))                  # girouette
	_rect(vp, orange, Rect2(12, 4, 6, 6))
	_text(vp, "2", Color.BLACK, 6, Vector2(13, 2.5), true)
	_text(vp, "Pte Dauphine" if destination == "Porte Dauphine" else destination, orange, 6, Vector2(21, 2.5), false)
	_rect(vp, Color("#2a3036"), Rect2(6, 13, 52, 28))                 # cadre du pare-brise
	_rect(vp, Color("#c9d3e0"), Rect2(8, 14, 48, 25))
	_rect(vp, Color("#dfe7f0"), Rect2(8, 14, 48, 6))                  # reflet
	var wiper := Polygon2D.new()
	wiper.color = Color("#1a1d20")
	wiper.polygon = PackedVector2Array([Vector2(26, 37), Vector2(48, 31), Vector2(48, 32), Vector2(27, 38)])
	vp.add_child(wiper)
	_rect(vp, Color("#3b4247"), Rect2(4, 42, 56, 18))                 # bandeau sous le pare-brise
	_text(vp, number, Color.WHITE, 6, Vector2(8, 42), true)
	_disc(vp, Color.TRANSPARENT, teal, Vector2(32, 51), 4)
	for x in [9.0, 55.0]:
		_disc(vp, Color("#f4f4ee"), Color("#8a9096"), Vector2(x, 53), 2.2)
		_disc(vp, Color("#f4f4ee"), Color("#8a9096"), Vector2(x, 58), 1.6)
	_rect(vp, Color("#e9ece8"), Rect2(2, 62, 60, 9))                  # jupe blanche
	_rect(vp, Color("#22262a"), Rect2(22, 64, 20, 12))                # attelage
	_rect(vp, Color("#55595e"), Rect2(25, 66, 14, 3))
	_rect(vp, Color("#101214"), Rect2(0, 74, 64, 6))
	return vp.get_texture()


## Plan de ligne d'un quai, d'après une photo prise comme modèle : en-tête blanc (← Ⓜ ②
## terminus, « par » la station repère), puis les stations de la station courante (encadrée
## en bleu nuit) au terminus, les correspondances en pastilles à gauche, bande bleu nuit en bas.
## 96 × 128 px (0,96 × 1,28 m au mur).
const LINE_PLAN_SIZE := Vector2i(96, 128)
## Couleurs des lignes de correspondance (charte IDFM).
const LINE_COLORS := {"1": "#ffcd00", "3": "#9f9825", "4": "#be418d", "5": "#ff7e2e", "6": "#6eca97",
	"7": "#fa9aba", "7bis": "#6eca97", "9": "#b6bd00", "11": "#704b1c", "12": "#007852", "13": "#6ec4e8"}
## Station repère affichée sous le terminus (« Nation par Barbès – Rochechouart »).
const VIA := {"Nation": "par Barbès – Rochechouart"}


static func line_plan(parent: Node, from: String, terminus: String) -> ViewportTexture:
	var vp := _viewport(parent, LINE_PLAN_SIZE)
	var w := LINE_PLAN_SIZE.x
	_rect(vp, PANEL_BEIGE, Rect2(0, 0, w, 128))
	_rect(vp, Color.WHITE, Rect2(0, 0, w, 16))
	_rect(vp, NAVY, Rect2(0, 0, w, 1))
	_rect(vp, Color("#c8c4b6"), Rect2(0, 16, w, 1))
	_back_arrow(vp, NAVY, Vector2(1, 3.5))
	_metro(vp, Vector2(21, 8.5), 5)
	_line_disc(vp, Vector2(32, 8.5), 5)
	var title := "Pte Dauphine" if terminus == "Porte Dauphine" else terminus
	_text(vp, title, NAVY, 8, Vector2(39, -1), true)
	if VIA.has(terminus):
		_text(vp, VIA[terminus], NAVY, 4, Vector2(39, 9), false)
	var stations := stations_towards(from, terminus)
	var step := minf(8.0, 100.0 / stations.size())
	var y0 := 22.0
	var lx := 42.0
	_rect(vp, LINE_2_BLUE, Rect2(lx - 1, y0, 2, step * (stations.size() - 1)))
	for i in stations.size():
		var y := y0 + step * i
		var name := stations[i]
		var connections := connections_of(name)
		if connections.is_empty():
			_disc(vp, LINE_2_BLUE, Color.TRANSPARENT, Vector2(lx, y), 1.5)
		else:
			_disc(vp, Color.WHITE, NAVY, Vector2(lx, y), 1.8)
		_connection_icons(vp, connections, Vector2(lx - 5, y))
		if name == from:
			_rect(vp, NAVY, Rect2(lx + 4, y - 3, 48, 6))
		_text(vp, name, Color.WHITE if name == from else NAVY, 5, Vector2(lx + 5, y - 4.5), name == from)
	_rect(vp, NAVY, Rect2(0, 122, w, 6))
	return vp.get_texture()


## Correspondances d'une station, une par élément (« M3 », « RER A »…).
static func connections_of(station: String) -> Array[String]:
	var out: Array[String] = []
	for s in LINE_2:
		if s[0] == station and s[1] != "":
			for part in s[1].split(","):
				var t: String = part.strip_edges()
				if t.begins_with("M") or t.begins_with("RER "):
					out.append(t)
				elif t.length() == 1:   # « RER B, D, E » : les lettres suivantes sont aussi des RER
					out.append("RER " + t)
	return out


## Pastilles des correspondances, alignées à droite sur `right` (Ⓜ et couleur de ligne, ou RER).
static func _connection_icons(parent: Node, connections: Array[String], right: Vector2) -> void:
	var x := right.x - 3
	for i in range(connections.size() - 1, -1, -1):
		var t: String = connections[i]
		if t.begins_with("RER"):
			_disc(parent, Color.WHITE, Color("#e2231a"), Vector2(x, right.y), 3)
			_centered(parent, t.substr(4), Color("#e2231a"), Vector2(x, right.y), 3)
		else:
			var n := t.substr(1)
			_disc(parent, Color(LINE_COLORS.get(n, "#888888")), Color.TRANSPARENT, Vector2(x, right.y), 3)
			_centered(parent, n, Color.BLACK if n in ["1", "5", "9", "13", "7", "6", "7bis"] else Color.WHITE, Vector2(x, right.y), 3)
		x -= 7


## Description lisible d'un plan de ligne, pour l'examen.
static func line_plan_text(from: String, terminus: String) -> String:
	var parts: Array[String] = []
	for name in stations_towards(from, terminus).slice(1):
		var connections := ""
		for s in LINE_2:
			if s[0] == name:
				connections = s[1]
		parts.append(name + (" (%s)" % connections if connections != "" else ""))
	return "Ligne 2, direction %s. Après %s : %s." % [terminus, from, ", ".join(parts)]


# --- Dessin --------------------------------------------------------------------

## Les panneaux sont décrits en pixels « texture » mais dessinés DETAIL fois plus fin.
const DETAIL := 4


static func _viewport(parent: Node, size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size * DETAIL
	vp.size_2d_override = size
	vp.size_2d_override_stretch = true
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


static func _line_disc(parent: Node, center: Vector2, radius: float, number := "2", color := LINE_2_BLUE) -> void:
	_disc(parent, color, Color.TRANSPARENT, center, radius)
	_centered(parent, number, Color.WHITE, center, radius)


static func _centered(parent: Node, s: String, color: Color, center: Vector2, radius: float) -> void:
	var l := _text(parent, s, color, int(radius * 1.6), center - Vector2(radius, radius + 1), true)
	l.size = Vector2(radius, radius) * 2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Flèche « ← » de 13 × 10 px (en-tête des plans de ligne).
static func _back_arrow(parent: Node, color: Color, pos: Vector2) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = pos
	poly.polygon = PackedVector2Array([Vector2(13, 4), Vector2(5, 4), Vector2(5, 1), Vector2(0, 5),
		Vector2(5, 9), Vector2(5, 6), Vector2(13, 6)])
	parent.add_child(poly)


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
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	if bold:
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 0.8
		l.add_theme_font_override("font", f)
	parent.add_child(l)
	return l
