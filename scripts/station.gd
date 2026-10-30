class_name Station
extends Node3D
## Base commune des stations de la ligne 2. Toutes sont construites dans le même repère :
## la rue à y = 0, le quai à y = -6,48, les voies selon l'axe X, la station côté +Z.
## Elle fournit le gabarit standard des stations parisiennes (quais de 75 m, voûte elliptique,
## deux voies et leurs tunnels), les matériaux PSX, les aides de construction, l'éclairage,
## le brouillard et les collisions. Chaque station en hérite et bâtit ce qui lui est propre.

# Gabarit standard des stations
const PY := -6.48         # niveau du quai
const HALF := 37.5        # demi-longueur des quais (75 m, comme à Monceau)
const X0 := -HALF
const X1 := HALF
const L := HALF * 2       # longueur du quai
const ZA := 20.0          # mur du quai direction Porte Dauphine
const ZB := 34.0          # mur du quai direction Nation
const ZT0 := 24.0         # bord du quai A
const ZT1 := 30.0         # bord du quai B
const RY := -7.5          # niveau des rails
const WT := -3.98         # naissance de la voûte
const CZ := 27.0          # axe de la voûte
const RZ := 7.0           # demi-portée de la voûte
const RV := 3.4           # flèche de la voûte
const TW := 1.2           # largeur d'un motif de carrelage
const TH := 0.6           # hauteur d'un motif de carrelage
const TUNNEL_LEN := 110.0

var M := {}
var night := true
var underground := false
var _builder := PsxBuilder.new()
## Miroir appliqué pendant la construction d'une partie retournée (voir Monceau, salle des billets).
var _mirror := Transform3D.IDENTITY
## Repère de construction : une seconde ligne (la ligne 3 à Villiers) se construit avec les mêmes
## fonctions dans un repère tourné et déplacé.
var _frame := Transform3D.IDENTITY
var _solid_side := 1.0
var _lanterns: Array[Vector3] = []
## Lampes des parties souterraines (couloirs, escaliers), éclairage par sommet.
var _under_lamps: Array[Vector3] = []
var _lamp_list: Array = []        # [position, couleur] de toutes les lampes
var _lamp_timer := 0.0
## Personnages présents, par identifiant de dialogue.
var people := {}
var _player: Node3D
var _collisions: StaticBody3D
var trafic: Trafic


## À appeler en tête du _ready() de la station : matériaux et corps des collisions.
## `chapter` : le chapitre qui se joue ici (lancé directement depuis l'éditeur, on y saute).
func _begin(chapter := 1) -> void:
	add_to_group("lieu")
	if not Enquete.started:   # lancé directement depuis l'éditeur, sans passer par le titre
		Enquete.new_game()
	if Enquete.chapter < chapter:
		Enquete.start_chapter(chapter)
	Sons.playing = true
	# les paramètres globaux survivent au changement de scène : on éteint les zones
	for z in ["zone2", "zone3"]:
		_global(z + "_min", Vector3(1e4, 1e4, 1e4))
		_global(z + "_max", Vector3(-1e4, -1e4, -1e4))
	_make_materials()
	_collisions = StaticBody3D.new()
	_collisions.name = "Collisions"
	add_child(_collisions)


## Rames et écrans : [z de la voie, côté des portes, sens, décalage dans le cycle, destination].
func _setup_trafic(tracks: Array, barriers: Array[CollisionShape3D]) -> void:
	trafic = _add_trafic("Trafic", tracks, barriers)


## Trafic d'une ligne dans le repère de construction courant (une seconde ligne en correspondance).
func _add_trafic(node_name: String, tracks: Array, barriers: Array[CollisionShape3D], line := "2", color := Color("#0055c8")) -> Trafic:
	var t := Trafic.new()
	t.name = node_name
	t.line = line
	t.line_color = color
	t.clock_start = Chapitres.start(Enquete.chapter)
	t.transform = _frame
	add_child(t)
	t.setup(M, RY, PY - RY, tracks, barriers)
	return t


## Zone éclairée par les néons du quai (blanc chaud), sur toute la longueur de la station.
func _set_platform_zone() -> void:
	_global("zone_color", Vector3(0.98, 0.97, 0.92))
	_global("zone_min", Vector3(-HALF - 1.0, -1000.0, ZA - 0.4))
	_global("zone_max", Vector3(HALF + 1.0, -0.3, ZB + 0.6))


func _process(delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	_lamp_timer += delta
	if _lamp_timer > 0.5 and _lamp_list.size() > 8:
		_lamp_timer = 0.0
		_update_lamps()
	var ug := _player.global_position.y < -2.0
	if ug != underground:
		underground = ug
		Enquete.underground = ug
		_apply_fog()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_night"):
		set_night(not night)



# --- Jour, nuit, brouillard ---------------------------------------------------

func set_night(on: bool) -> void:
	night = on
	_global("sun_color", Vector3(0.12, 0.14, 0.24) if on else Vector3(1.0, 0.96, 0.86))
	_global("ambient_color", Vector3(0.16, 0.18, 0.28) if on else Vector3(0.52, 0.56, 0.62))
	_lamp_list.clear()
	for p in _lanterns:
		_lamp_list.append([p, Vector3(1.5, 0.9, 0.4) if on else Vector3.ZERO])
	for p in _under_lamps:
		_lamp_list.append([p, Vector3(1.05, 1.0, 0.85)])
	_update_lamps()
	M.lanterne.set_shader_parameter("emission", Vector3(1.4, 1.0, 0.6) if on else Vector3.ZERO)
	M.cand.set_shader_parameter("emission", Vector3(0.9, 0.8, 0.5) if on else Vector3.ZERO)
	_apply_fog()


## Le shader n'éclaire qu'avec 8 lampes : s'il y en a plus, on garde les 8 plus proches du joueur.
func _update_lamps() -> void:
	var lamps := _lamp_list.duplicate()
	if _player and lamps.size() > 8:
		var at := _player.global_position
		lamps.sort_custom(func(a: Array, b: Array) -> bool:
			return (a[0] as Vector3).distance_squared_to(at) < (b[0] as Vector3).distance_squared_to(at))
	var pos: Array[Vector3] = []
	var col: Array[Vector3] = []
	for lamp in lamps.slice(0, 8):
		pos.append(lamp[0])
		col.append(lamp[1])
	while pos.size() < 8:
		pos.append(Vector3(0, -99, 0))
		col.append(Vector3.ZERO)
	_global("lamp_pos_a", _pack(pos, 0))
	_global("lamp_pos_b", _pack(pos, 4))
	_global("lamp_col_a", _pack(col, 0))
	_global("lamp_col_b", _pack(col, 4))


func _apply_fog() -> void:
	var color: Color
	if underground:
		color = Color.hex(0x121417ff)
		_global("fog_near", 26.0)
		_global("fog_far", 95.0)
	else:
		color = Color.hex(0x0a0f1cff) if night else Color.hex(0xcfdce4ff)
		_global("fog_near", 6.0 if night else 18.0)
		_global("fog_far", 42.0 if night else 78.0)
	_global("fog_color", Vector3(color.r, color.g, color.b))
	var world_env := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env:
		world_env.environment.background_color = color


func _global(param: StringName, value: Variant) -> void:
	RenderingServer.global_shader_parameter_set(param, value)


func _pack(v: Array[Vector3], start: int) -> Projection:
	return Projection(
		Vector4(v[start].x, v[start].y, v[start].z, 0), Vector4(v[start + 1].x, v[start + 1].y, v[start + 1].z, 0),
		Vector4(v[start + 2].x, v[start + 2].y, v[start + 2].z, 0), Vector4(v[start + 3].x, v[start + 3].y, v[start + 3].z, 0))


# --- Matériaux ----------------------------------------------------------------

const PSX_SHADER := preload("res://shaders/psx.gdshader")


func _mat(tex: String, color := 0xffffff, alpha := false, unlit := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PSX_SHADER
	m.set_shader_parameter("albedo_texture", load("res://textures/%s.png" % tex))
	var c := Color.hex((color << 8) | 0xff)
	m.set_shader_parameter("albedo_color", Vector3(c.r, c.g, c.b))
	m.set_shader_parameter("alpha_cut", 0.5 if alpha else 0.0)
	m.set_shader_parameter("unlit", 1.0 if unlit else 0.0)
	return m


func _make_materials() -> void:
	M = {
		"paves": _mat("paves"), "trottoir": _mat("trottoir"), "pierre": _mat("pierre_taille"), "pierreS": _mat("pierre"),
		"carrelage": _mat("carreau_blanc"), "balus": _mat("balustrade", 0xffffff, true), "enseigne": _mat("enseigne", 0xffffff, true),
		"plaque": _mat("plaque", 0xffffff, true), "plan": _mat("plan_quartier"), "plan_reseau": _mat("plan_reseau"), "globes": _mat("globes"), "lanterne": _mat("lanterne"),
		"fonte": _mat("blanc", 0x24443a), "fonteDark": _mat("blanc", 0x172a23),
		"facA": _mat("facade_a"), "facB": _mat("facade_b"), "porte": _mat("porte"), "zinc": _mat("zinc"),
		"corn": _mat("rot_corniche"), "tamb": _mat("rot_tambour"), "dome": _mat("dome"), "grille": _mat("grille"),
		"portail": _mat("portail", 0xffffff, true), "gardecorps": _mat("gardecorps", 0xffffff, true),
		"colonne": _mat("colonne"), "pierreT": _mat("pierre_taille"),
		"feuil": _mat("feuillage"), "tronc": _mat("blanc", 0x7c7464), "musee": _mat("musee", 0xffffff, true),
		"fleche": _mat("fleche"), "cand": _mat("candelabre", 0xffffff, true), "candPost": _mat("blanc", 0x4a3b33),
		"sortie": _mat("sortie", 0xffffff, true), "morris": _mat("blanc", 0x2c4b3c),
		"carreau": _mat("carreau_blanc"), "sol": _mat("sol_goudron"), "bande": _mat("bande"), "voie": _mat("voie"),
		"plinthe": _mat("carreau_marron"), "quaiFace": _mat("blanc", 0x3c3a37), "rail": _mat("blanc", 0x9a9792),
		"neon": _mat("blanc", 0xffffff, false, true), "noir": _mat("blanc", 0x040404, false, true),
		"nom": _mat("nom_quai"), "nepas": _mat("nepas"), "direction": _mat("direction"),
		"sortieQ": _mat("sortie_quai"), "alarme": _mat("alarme"), "repere": _mat("repere"), "descente": _mat("descente"),
		"seat": _mat("blanc", 0x2f7a46), "inox": _mat("blanc", 0xb4b8bc), "tunnel": _mat("pierre", 0x5e5c58),
		"service": _mat("porte_service"), "marche": _mat("sol_quai", 0xb0b0b0),
		"platre": _mat("blanc", 0xbdbab1), "frise": _mat("frise_verte"),
		"carreau_salle": _mat("carreau_blanc", 0xeef4f8),   # blanc un peu plus froid, comme sur la photo de la salle
		"frise_verte": _mat("frise_verte"), "plinthe_verte": _mat("plinthe_verte"),
		# rames MF01
		"rameCote": _mat("rame_cote", 0xffffff, true), "rameFace": _mat("rame_face"),
		"rameBlanc": _mat("blanc", 0xe6e4dc), "rameNoir": _mat("blanc", 0x1a1a1c),
		"int_paroi": _mat("int_paroi", 0xffffff, true), "porte_ext": _mat("porte_ext", 0xffffff, true),
		"porte_int": _mat("porte_int", 0xffffff, true), "int_sol": _mat("blanc", 0x55575c),
		"int_plafond": _mat("blanc", 0xe8e2cc), "siege": _mat("siege"), "int_pied": _mat("blanc", 0xd8d0b4),
		"soufflet": _mat("soufflet"), "int_plan": _mat("int_plan"), "int_cabine": _mat("blanc", 0xd6cfb6),
	}
	# l'intérieur des rames est éclairé par ses propres néons
	for k in ["int_paroi", "porte_int", "int_sol", "int_plafond", "siege", "int_pied", "soufflet", "int_plan", "int_cabine"]:
		M[k].set_shader_parameter("emission", Vector3(0.38, 0.37, 0.34))


# --- Aides de construction (mêmes signatures que dans le prototype) -----------

## Nombre de subdivisions : de petits polygones, comme sur PS1, pour l'éclairage par sommet.
static func seg(v: float, cap := 48) -> int:
	return maxi(1, mini(cap, ceili(v / 2.0)))


func add(geo: Dictionary, m: Material, pos: Vector3, rot := Vector3.ZERO, scale := Vector3.ONE) -> void:
	_builder.add(geo, m, _frame * _mirror * PsxGeo.xf(pos, rot, scale))


func add_xf(geo: Dictionary, m: Material, xform: Transform3D) -> void:
	_builder.add(geo, m, _frame * _mirror * xform)



## Rectangle horizontal ; rx = PI/2 pour un plafond.
func rect(m: Material, x0: float, z0: float, x1: float, z1: float, y: float, tile: float, rx := -PI / 2) -> void:
	var g := PsxGeo.uv_scale(PsxGeo.plane(x1 - x0, z1 - z0, seg(x1 - x0), seg(z1 - z0)), (x1 - x0) / tile, (z1 - z0) / tile)
	add(g, m, Vector3((x0 + x1) / 2, y, (z0 + z1) / 2), Vector3(rx, 0, 0))


func box(m: Material, w: float, h: float, d: float, x: float, y: float, z: float, tu := 1.0, tv := 1.0) -> void:
	add(PsxGeo.uv_scale(PsxGeo.box(w, h, d, seg(w, 24), seg(h, 24), seg(d, 24)), tu, tv), m, Vector3(x, y, z))


func plane(m: Material, w: float, h: float, x: float, y: float, z: float, ry := 0.0, tu := 1.0, tv := 1.0, rx := 0.0) -> void:
	add(PsxGeo.uv_scale(PsxGeo.plane(w, h, seg(w), seg(h)), tu, tv), m, Vector3(x, y, z), Vector3(rx, ry, 0))


func _wall(m: Material, x1: float, z1: float, x2: float, z2: float, y0: float, y1: float, tw: float, th: float) -> void:
	var length := Vector2(x2 - x1, z2 - z1).length()
	plane(m, length, y1 - y0, (x1 + x2) / 2, (y0 + y1) / 2, (z1 + z2) / 2, atan2(-(z2 - z1), x2 - x1), length / tw, (y1 - y0) / th)


# --- Quais, voûte, voies et tunnels -------------------------------------------

## Voies, faces des quais, rails et bandes d'éveil le long des deux bords.
func _build_tracks() -> void:
	rect(M.bande, X0, ZT0 - 0.55, X1, ZT0, PY + 0.006, 0.55)
	rect(M.bande, X0, ZT1, X1, ZT1 + 0.55, PY + 0.006, 0.55)
	rect(M.voie, X0, ZT0, X1, ZT1, RY, 1.2)
	plane(M.quaiFace, L, PY - RY, 0, (PY + RY) / 2, ZT0, 0, 20, 1)
	plane(M.quaiFace, L, PY - RY, 0, (PY + RY) / 2, ZT1, 0, 20, 1)
	for c in [25.5, 28.5]:
		for o in [-0.72, 0.72]:
			box(M.rail, L + 220, 0.14, 0.08, 0, RY + 0.07, c + o)


## Voûte, murs de tête, tunnels et, si `ramps`, les rampes de néons au-dessus des bords de quai.
func _build_shell(ramps := true) -> void:
	_build_vault()
	for sx in [-1.0, 1.0]:
		_build_tympan_and_tunnel(sx)

	# rampes de néons
	for z in ([23.2, 30.8] if ramps else []):
		box(M.neon, L - 2, 0.1, 0.26, 0, -1.6, z)
		box(M.inox, L - 2, 0.06, 0.36, 0, -1.52, z)


## Écrans des prochains passages, suspendus au-dessus de chaque quai aux abscisses données.
func _build_screens(xs: Array, t: Trafic = null) -> void:
	if t == null:
		t = trafic
	for screen in [[22.4, 0], [31.6, 1]]:
		var z: float = screen[0]
		var m: Material = t.siel_materials[screen[1]]
		for x in xs:
			for r in [PI / 2, -PI / 2]:
				plane(m, 1.6, 0.76, x + (0.03 if r > 0 else -0.03), -3.5, z, r)
			box(M.fonteDark, 0.04, 0.78, 1.62, x, -3.5, z)
			var screen_item := Examinable.new()
			screen_item.title = "Écran des prochains passages"
			_place(screen_item, Vector3(x, -3.5, z))
			_examinable_shape(screen_item, Vector3(0.2, 0.8, 1.7))
			add_child(screen_item)
			t.siel_examinables[screen[1]].append(screen_item)
			box(M.inox, 0.03, 1.0, 0.03, x, -2.7, z)


## Sièges « Motte » : [x, z, sens (1 face aux voies depuis le quai A, -1 depuis le quai B)].
func _build_seats(seats: Array) -> void:
	var bowl := PsxGeo.sphere(0.24, 8, 3, 0, TAU, PI / 2, PI / 2)
	for s in seats:
		var gx: float = s[0]
		var gz: float = s[1]
		var face: float = s[2]
		box(M.inox, 2.8, 0.05, 0.05, gx, PY + 0.4, gz)
		for lx in [-0.9, 0.9]:
			box(M.inox, 0.06, 0.4, 0.06, gx + lx, PY + 0.2, gz)
		for k in range(-2, 3):
			add(bowl, M.seat, Vector3(gx + k * 0.56, PY + 0.52, gz + face * 0.12), Vector3(face * 0.45, 0, 0), Vector3(1, 0.55, 1))


func _build_vault() -> void:
	var n_arc := 18
	var n_len := 38
	var g := PsxGeo.empty()
	var s_acc := 0.0
	var prev := Vector2.ZERO
	for i in n_arc + 1:
		var t := PI - PI * i / n_arc
		var z := CZ + RZ * cos(t)
		var y := WT + RV * sin(t)
		if i > 0:
			s_acc += Vector2(z, y).distance_to(prev)
		prev = Vector2(z, y)
		for j in n_len + 1:
			var x := X0 + L * j / n_len
			g.p.append(Vector3(x, y, z))
			g.n.append(Vector3(0, -sin(t), -cos(t)))
			g.uv.append(Vector2(x / TW, s_acc / TH))
	for i in n_arc:
		for j in n_len:
			var a := i * (n_len + 1) + j
			var b := a + n_len + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, M.carreau, Vector3.ZERO)


## Mur de tête (tympan) percé de la bouche du tunnel, puis le tunnel lui-même.
func _build_tympan_and_tunnel(sx: float) -> void:
	var outline := PackedVector2Array([Vector2(ZA, PY), Vector2(ZT0, PY), Vector2(ZT0, -4.6)])
	for i in range(1, 12):
		var a := PI - PI * i / 12
		outline.append(Vector2(CZ + 3 * cos(a), -4.6 + 1.7 * sin(a)))
	outline.append_array([Vector2(ZT1, -4.6), Vector2(ZT1, PY), Vector2(ZB, PY), Vector2(ZB, WT)])
	for i in range(1, 12):
		var a := PI * i / 12
		outline.append(Vector2(CZ + RZ * cos(a), WT + RV * sin(a)))
	outline.append(Vector2(ZA, WT))
	add(PsxGeo.polygon(outline, 1 / TW, 1 / TH), M.carreau, Vector3(sx * HALF, 0, 0), Vector3(0, -PI / 2, 0))

	# galerie : piédroits et voûte
	var pr := [[ZT0, RY, 0.0, 1.0], [ZT0, -4.6, 0.0, 1.0]]
	var na := 10
	for i in na + 1:
		var a := PI - PI * i / na
		pr.append([CZ + 3 * cos(a), -4.6 + 1.7 * sin(a), -sin(a), -cos(a)])
	pr.append_array([[ZT1, -4.6, 0.0, -1.0], [ZT1, RY, 0.0, -1.0]])
	var nx := 28
	var g := PsxGeo.empty()
	var acc := 0.0
	for i in pr.size():
		if i > 0:
			acc += Vector2(pr[i][0] - pr[i - 1][0], pr[i][1] - pr[i - 1][1]).length()
		for j in nx + 1:
			var x := sx * (HALF + TUNNEL_LEN * j / nx)
			g.p.append(Vector3(x, pr[i][1], pr[i][0]))
			g.n.append(Vector3(0, pr[i][2], pr[i][3]))
			g.uv.append(Vector2(x / 2.4, acc / 1.2))
	for i in pr.size() - 1:
		for j in nx:
			var a := i * (nx + 1) + j
			var b := a + nx + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, M.tunnel, Vector3.ZERO)

	rect(M.voie, HALF if sx > 0 else -HALF - TUNNEL_LEN, ZT0, HALF + TUNNEL_LEN if sx > 0 else -HALF, ZT1, RY, 1.2)
	var x := HALF + 8.0
	while x < HALF + TUNNEL_LEN:
		box(M.neon, 0.12, 0.12, 0.06, sx * x, -4.5, ZT0 + 0.04)
		box(M.neon, 0.12, 0.12, 0.06, sx * (x + 7), -4.5, ZT1 - 0.04)
		x += 14
	plane(M.noir, 6.2, 6, sx * (HALF + TUNNEL_LEN - 0.5), -4.6, CZ, PI / 2)
	# panneaux « Descente interdite » en bout de quai
	plane(M.descente, 0.55, 1.65, sx * (HALF - 0.5), PY + 0.83, ZT0 - 0.35, -sx * PI / 2)
	plane(M.descente, 0.55, 1.65, sx * (HALF - 0.5), PY + 0.83, ZT1 + 0.35, -sx * PI / 2)


func _sign(rows: Array) -> ShaderMaterial:
	return _sign_from_texture(Panneaux.direction(self, rows))


## Matériau d'un panneau dessiné : légèrement lumineux, comme un panneau émaillé sous les néons.
func _sign_from_texture(tex: Texture2D) -> ShaderMaterial:
	var m: ShaderMaterial = M.inox.duplicate()
	m.set_shader_parameter("albedo_texture", tex)
	m.set_shader_parameter("albedo_color", Vector3.ONE)
	m.set_shader_parameter("emission", Vector3(0.2, 0.2, 0.2))
	return m


## La station suivante pour une rame qui quitte `here` vers `destination` (ligne 2, ou les
## voisines de Villiers sur la ligne 3).
static func next_station(here: String, destination: String) -> String:
	var line3 := {"Pont de Levallois": "Malesherbes", "Gallieni": "Europe"}
	if line3.has(destination):
		return line3[destination]
	var ahead := Panneaux.stations_towards(here, destination)
	return ahead[1] if ahead.size() > 1 else destination


## Place un nœud dans le repère de construction courant.
func _place(node: Node3D, pos: Vector3) -> void:
	node.transform = _frame * Transform3D(Basis(), pos)


func _examinable_shape(item: Examinable, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	item.add_child(shape)


# --- Collisions ---------------------------------------------------------------

## Ajoute une boîte de collision ; renvoie la forme (pour les garde-fous qu'on ôte).
func _solid(size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.transform = _frame * Transform3D(Basis.from_euler(rot), Vector3(pos.x * _solid_side, pos.y, pos.z))
	_collisions.add_child(shape)
	return shape


func _post(radius: float, height: float, pos: Vector3) -> void:
	var shape := CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = radius
	shape.shape.height = height
	shape.transform = _frame * Transform3D(Basis(), pos + Vector3(0, height / 2, 0))
	_collisions.add_child(shape)


## Rampe invisible sous une volée de marches, du point haut au point bas (même largeur).
func _ramp(top: Vector3, bottom: Vector3, width: float) -> void:
	var d := bottom - top
	var length := d.length()
	if absf(d.x) > absf(d.z):
		var angle := -atan2(-d.y, absf(d.x)) * signf(d.x)
		var normal := Vector3(-sin(angle), cos(angle), 0)
		_solid(Vector3(length, 0.2, width), (top + bottom) / 2 - normal * 0.1, Vector3(0, 0, angle))
	else:
		var angle := atan2(-d.y, absf(d.z)) * signf(d.z)
		var normal := Vector3(0, cos(angle), sin(angle))
		_solid(Vector3(width, 0.2, length), (top + bottom) / 2 - normal * 0.1, Vector3(angle, 0, 0))


## Bouts d'un quai : murs de tête, garde-fous au-delà des rames ; renvoie le garde-fou
## le long des voies, ôté quand une rame est à quai.
func _platform_end_colliders(zw: float, ze: float, inward: float) -> CollisionShape3D:
	var depth := absf(ze - zw)
	for sx in [-1, 1]:
		_solid(Vector3(0.2, 4, depth), Vector3(sx * (HALF + 0.1), PY + 2, (zw + ze) / 2))
		# bouts de quai au-delà des rames : garde-fou permanent
		var gap := HALF - MF01.HALF_LENGTH + 0.3
		_solid(Vector3(gap, 2.0, 0.1), Vector3(sx * (HALF - gap / 2), PY + 1.0, ze - inward * 0.3))
	return _solid(Vector3(MF01.HALF_LENGTH * 2, 2.0, 0.1), Vector3(0, PY + 1.0, ze - inward * 0.3))


# --- Passage sous les voies ----------------------------------------------------
# Sur chaque quai, un escalier longe le mur et descend vers +x jusqu'à un passage qui file
# sous les voies d'un quai à l'autre. `u` décrit ce passage :
#   x0, x1   haut et bas des escaliers ;  x2  mur du fond du passage ;  w  largeur des escaliers ;
#   floor, ceil   sol et plafond du passage ;
#   rail, rail_h, rail_tile   garde-corps de la trémie (matériau, hauteur, largeur d'un motif) ;
#   top_rail  lisse posée sur le garde-corps (ou null) ;  curb  bordure carrelée (ou null) ;
#   risers  fresque peinte sur les contremarches (ou null) ;  frieze, plinth  habillage du passage ;
#   door  (facultatif) ouverture [z0, z1] dans le mur du fond, vers un couloir ;
#   steps  (facultatif, 15 par défaut) nombre de marches ; passage  (facultatif, vrai par défaut)
#   faux pour une station aérienne, où l'escalier descend à la rue au lieu d'un passage.

## Hauteur d'une marche (15 marches du quai au passage, sauf indication contraire).
static func _underpass_step(u: Dictionary) -> float:
	return (PY - u.floor) / u.get("steps", 15)


## Naissance de la voûte du passage.
static func _underpass_spring(u: Dictionary) -> float:
	return u.ceil - 0.45


func _build_underpass(u: Dictionary) -> void:
	var step := _underpass_step(u)
	var spring := _underpass_spring(u)
	var x0: float = u.x0
	var x1: float = u.x1
	var x2: float = u.x2
	var w: float = u.w
	var floor_y: float = u.floor
	for well in [[ZA, 1.0], [ZB, -1.0]]:
		var zw: float = well[0]          # mur du quai
		var inward: float = well[1]      # sens du mur vers les voies
		var zc := zw + inward * w / 2    # axe de l'escalier
		var zi := zw + inward * w        # bord de la trémie côté voies
		# marches grises à nez en inox, bande d'éveil en haut
		var n: int = u.get("steps", 15)
		var run := (x1 - x0) / n
		for i in n:
			var top := PY - (i + 1) * step
			var x := x0 + i * run + run / 2
			# un peu plus étroites que la cage : sinon, avec le tremblement, elles percent le carrelage
			box(M.marche, run, top - floor_y + 0.3, w - 0.06, x, (top + floor_y - 0.3) / 2, zc, 1, 2)
			box(M.inox, 0.05, 0.02, w - 0.06, x - run / 2 + 0.025, top + 0.01, zc)
			if u.risers:
				# une bande de la fresque par contremarche, pour qu'elle se lise depuis le bas
				var g := PsxGeo.plane(w, step, 2, 1)
				for k in g.uv.size():
					g.uv[k] = Vector2(g.uv[k].x, (i + g.uv[k].y) / n)
				add(g, u.risers, Vector3(x0 + i * run + 0.005, top + step / 2, zc), Vector3(0, PI / 2, 0))
		rect(M.bande, x0 - 0.6, minf(zw, zi), x0, maxf(zw, zi), PY + 0.006, 0.55)
		plane(M.marche, w, step + 0.02, x0, PY - step / 2, zc, PI / 2, 1, 0.3)   # contremarche du haut
		# murs de la trémie : carreaux
		var depth := PY - floor_y
		for z in [zw, zi]:
			plane(M.carreau, x1 - x0, depth, (x0 + x1) / 2, (PY + floor_y) / 2, z, 0, (x1 - x0) / TW, depth / TH)
		plane(M.carreau, w, PY - spring, x1, (PY + spring) / 2, zc, PI / 2, w / TW, (PY - spring) / TH)   # bout de la dalle
		if not u.get("passage", true):
			# station aérienne : sous le haut de l'escalier, un mur carrelé jusqu'au sol de la rue
			plane(M.carreau, w, depth, x0 - 0.02, (PY + floor_y) / 2, zc, PI / 2, w / TW, depth / TH)
		# main courante le long du mur
		var rail_len := Vector2(x1 - x0, depth).length()
		add(PsxGeo.box(rail_len, 0.04, 0.04), M.candPost, Vector3((x0 + x1) / 2, (PY + floor_y) / 2 + 0.9, zw + inward * 0.06),
			Vector3(0, 0, -atan2(depth, x1 - x0)))
		# bordure et garde-corps autour de la trémie
		var base := PY
		if u.curb:
			box(u.curb, x1 - x0, 0.22, 0.2, (x0 + x1) / 2, PY + 0.11, zi + inward * 0.1, (x1 - x0) / 0.6, 1)
			box(u.curb, 0.2, 0.22, w + 0.2, x1 + 0.1, PY + 0.11, zc + inward * 0.1, 1, (w + 0.2) / 0.6)
			base = PY + 0.22
		var rh: float = u.rail_h
		plane(u.rail, x1 - x0, rh, (x0 + x1) / 2, base + rh / 2, zi, 0, (x1 - x0) / u.rail_tile, 1)
		plane(u.rail, w, rh, x1, base + rh / 2, zc, PI / 2, w / u.rail_tile, 1)
		if u.top_rail:
			box(u.top_rail, x1 - x0, 0.05, 0.05, (x0 + x1) / 2, base + rh, zi)
			box(u.top_rail, 0.05, 0.05, w, x1, base + rh, zc)

	if not u.get("passage", true):
		return
	# le passage : murs carrelés, frise, plinthe, voûte blanche, sol gris foncé
	var mid := (ZA + ZB) / 2
	var wall_h := spring - floor_y
	rect(M.sol, x1, ZA, x2, ZB, floor_y, 2.4)
	var walls := [[x1, ZA + w, ZB - w]]
	for run in _underpass_far_wall(u):
		walls.append([x2, run[0], run[1]])
	for wall in walls:
		var x: float = wall[0]
		var length: float = wall[2] - wall[1]
		var zm: float = (wall[1] + wall[2]) / 2
		plane(M.carreau, length, wall_h, x, (floor_y + spring) / 2, zm, PI / 2, length / TW, wall_h / TH)
		plane(u.frieze, length, 0.14, x + (0.01 if x < x2 else -0.01), spring - 0.07, zm, PI / 2, length / 0.6, 1)
		plane(u.plinth, length, 0.2, x + (0.01 if x < x2 else -0.01), floor_y + 0.1, zm, PI / 2, length / 0.6, 1)
	for z in [ZA, ZB]:
		plane(M.carreau, x2 - x1, u.ceil - floor_y, (x1 + x2) / 2, (u.ceil + floor_y) / 2, z, 0, (x2 - x1) / TW, (u.ceil - floor_y) / TH)
	_build_underpass_vault(u)
	box(M.neon, 0.15, 0.05, ZB - ZA - 2, (x1 + x2) / 2, u.ceil - 0.03, mid)


## Tronçons [z0, z1] du mur du fond du passage, interrompu par `u.door` s'il y en a une
## (ouverture [z0, z1] vers un couloir, de la hauteur des murs).
static func _underpass_far_wall(u: Dictionary) -> Array:
	if not u.has("door"):
		return [[ZA, ZB]]
	return [[ZA, u.door[0]], [u.door[1], ZB]]


## Voûte surbaissée du passage, d'un mur à l'autre, sur toute sa longueur.
func _build_underpass_vault(u: Dictionary) -> void:
	var spring := _underpass_spring(u)
	var g := PsxGeo.empty()
	var n_arc := 8
	var n_len := 14
	var cx: float = (u.x1 + u.x2) / 2
	var half: float = (u.x2 - u.x1) / 2
	for i in n_arc + 1:
		var t := PI * i / n_arc
		var x := cx + half * cos(t)
		var y: float = spring + (u.ceil - spring) * sin(t)
		for j in n_len + 1:
			var z := ZA + (ZB - ZA) * j / n_len
			g.p.append(Vector3(x, y, z))
			g.n.append(Vector3(-cos(t), -sin(t), 0))
			g.uv.append(Vector2(z / 2.0, float(i) / n_arc))
	for i in n_arc:
		for j in n_len:
			var a := i * (n_len + 1) + j
			var b := a + n_len + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, M.platre, Vector3.ZERO)


## Sols des deux quais, percés par les trémies des escaliers du passage.
func _build_platform_floors(u: Dictionary) -> void:
	rect(M.sol, X0, ZA, u.x0, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, u.x1, ZA, X1, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, u.x0, ZA + u.w, u.x1, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, X0, ZT1 + 0.55, u.x0, ZB, PY, 2.4)
	rect(M.sol, u.x1, ZT1 + 0.55, X1, ZB, PY, 2.4)
	rect(M.sol, u.x0, ZT1 + 0.55, u.x1, ZB - u.w, PY, 2.4)


## Collisions des deux quais et du passage ; `openings` : ouvertures [x0, x1] dans le mur de
## chaque quai ([quai A, quai B]). Renvoie les garde-fous des deux voies.
func _platform_colliders(u: Dictionary, openings: Array) -> Array[CollisionShape3D]:
	var x0: float = u.x0
	var x1: float = u.x1
	var w: float = u.w
	var floor_y: float = u.floor
	var barriers: Array[CollisionShape3D] = []
	var q := 0
	for quai in [[ZA, ZT0, 1.0], [ZB, ZT1, -1.0]]:
		var zw: float = quai[0]       # mur du quai
		var ze: float = quai[1]       # bord du quai
		var inward: float = quai[2]   # sens du mur vers les voies
		var zi := zw + inward * w
		var depth := absf(ze - zw)
		_solid(Vector3(x0 - X0, 0.2, depth), Vector3((X0 + x0) / 2, PY - 0.1, (zw + ze) / 2))
		_solid(Vector3(X1 - x1, 0.2, depth), Vector3((x1 + X1) / 2, PY - 0.1, (zw + ze) / 2))
		_solid(Vector3(x1 - x0, 0.2, absf(ze - zi)), Vector3((x0 + x1) / 2, PY - 0.1, (zi + ze) / 2))
		# mur du quai, interrompu par ses ouvertures
		var start := X0
		var holes: Array = openings[q] + [[X1, X1]]
		for hole in holes:
			if hole[0] > start:
				_solid(Vector3(hole[0] - start, WT - floor_y, 0.2), Vector3((start + hole[0]) / 2, (floor_y + WT) / 2, zw - inward * 0.1))
			start = hole[1]
		barriers.append(_platform_end_colliders(zw, ze, inward))
		# trémie de l'escalier : garde-corps, mur côté voies, rampe
		_solid(Vector3(x1 - x0, 1.1, 0.06), Vector3((x0 + x1) / 2, PY + 0.55, zi))
		_solid(Vector3(0.06, 1.1, w), Vector3(x1, PY + 0.55, zw + inward * w / 2))
		_solid(Vector3(x1 - x0, PY - floor_y, 0.2), Vector3((x0 + x1) / 2, (PY + floor_y) / 2, zi + inward * 0.1))
		_ramp(Vector3(x0, PY, zw + inward * w / 2), Vector3(x1, floor_y, zw + inward * w / 2), w)
		q += 1
	if not u.get("passage", true):
		return barriers
	# passage sous les voies
	_solid(Vector3(u.x2 - x1, 0.2, ZB - ZA), Vector3((x1 + u.x2) / 2, floor_y - 0.1, (ZA + ZB) / 2))
	for run in _underpass_far_wall(u):
		_solid(Vector3(0.2, u.ceil - floor_y, run[1] - run[0]), Vector3(u.x2 + 0.1, (floor_y + u.ceil) / 2, (run[0] + run[1]) / 2))
	_solid(Vector3(0.2, u.ceil - floor_y, ZB - ZA - 2 * w), Vector3(x1 - 0.1, (floor_y + u.ceil) / 2, (ZA + ZB) / 2))
	return barriers


## Plan de la ligne 2 au mur, examinable : de `from` vers `terminus`.
func _line_plan(from: String, terminus: String, pos: Vector3, ry: float) -> void:
	var m := _sign_from_texture(Panneaux.line_plan(self, from, terminus))
	var size := Vector2(Panneaux.LINE_PLAN_SIZE) / 100.0
	plane(m, size.x, size.y, pos.x, pos.y, pos.z, ry)
	var item := Examinable.new()
	item.title = "Plan de la ligne 2"
	item.description = Panneaux.line_plan_text(from, terminus)
	_place(item, pos)
	var depth := Vector3(0.15, size.y, size.x) if absf(sin(ry)) > 0.5 else Vector3(size.x, size.y, 0.15)
	_examinable_shape(item, depth)
	add_child(item)


# --- Surface et salles des billets ----------------------------------------------

## Immeuble haussmannien : rez-de-chaussée à portes, étages, corniche et toit de zinc.
func _block(x0: float, z0: float, x1: float, z1: float, h: float, facade: String) -> void:
	var pts := [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1), Vector2(x0, z0)]
	var fm: Material = M.facA if facade == "a" else M.facB
	var tw := 6.0 if facade == "a" else 5.0
	var th := 3.4 if facade == "a" else 12.0
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		_wall(M.porte, a.x, a.y, b.x, b.y, 0, 4.2, 4.2, 4.2)
		_wall(fm, a.x, a.y, b.x, b.y, 4.2, h, tw, th)
	box(M.zinc, x1 - x0 - 0.8, 3, z1 - z0 - 0.8, (x0 + x1) / 2, h + 1.5, (z0 + z1) / 2, (x1 - x0) / 3, 1)
	box(M.pierre, x1 - x0 + 0.3, 0.35, z1 - z0 + 0.3, (x0 + x1) / 2, h, (z0 + z1) / 2, (x1 - x0) / 4, 0.2)



## Bouche Guimard : deux arcs de fonte et leurs lanternes, l'enseigne « Métropolitain », au
## bord haut de l'escalier (z = at.z), centrée en at.x.
func _build_guimard(at: Vector3) -> void:
	for s in [-1.0, 1.0]:
		add(PsxGeo.tube([Vector3(at.x + 1.45 * s, 0, at.z), Vector3(at.x + 1.5 * s, 1.4, at.z), Vector3(at.x + 1.38 * s, 2.6, at.z),
			Vector3(at.x + 1.1 * s, 3.25, at.z), Vector3(at.x + 0.9 * s, 3.32, at.z)], 10, 0.055, 5), M.fonte, Vector3.ZERO)
		add(PsxGeo.tube([Vector3(at.x + 1.5 * s, 0, at.z), Vector3(at.x + 1.62 * s, 1.8, at.z), Vector3(at.x + 1.68 * s, 3.3, at.z),
			Vector3(at.x + 1.5 * s, 4.0, at.z), Vector3(at.x + 1.22 * s, 4.02, at.z)], 10, 0.045, 5), M.fonte, Vector3.ZERO)
		box(M.fonteDark, 0.22, 0.32, 0.22, at.x + 1.47 * s, 0.16, at.z)
		add(PsxGeo.sphere(0.17, 6, 4), M.lanterne, Vector3(at.x + 1.2 * s, 3.84, at.z), Vector3.ZERO, Vector3(1, 1.25, 1))
		add(PsxGeo.cone(0.2, 0.16, 5), M.fonteDark, Vector3(at.x + 1.2 * s, 4.04, at.z))
		_lanterns.append(Vector3(at.x + 1.2 * s, 3.84, at.z))
	box(M.fonte, 1.96, 0.56, 0.06, at.x, 3.28, at.z)
	plane(M.enseigne, 1.84, 0.46, at.x, 3.28, at.z - 0.035, PI)
	plane(M.enseigne, 1.84, 0.46, at.x, 3.28, at.z + 0.035, 0)


## Platane : tronc et deux masses de feuillage ; `i` varie la taille.
func _tree(x: float, z: float, i: int) -> void:
	var s := 0.9 + ((i * 37) % 5) / 12.0
	add(PsxGeo.cylinder(0.22 * s, 0.32 * s, 5 * s, 5), M.tronc, Vector3(x, 2.5 * s, z))
	add(PsxGeo.uv_scale(PsxGeo.icosahedron(2.6 * s), 2, 2), M.feuil, Vector3(x, 6 * s, z), Vector3(0, x * 1.7, 0))
	add(PsxGeo.uv_scale(PsxGeo.icosahedron(2.0 * s), 2, 2), M.feuil, Vector3(x + 1.2 * s, 7.2 * s, z - 0.6 * s), Vector3(0, 0, z * 0.9))


## Ligne de contrôle d'une salle des billets, en travers de la salle (de xl à xr, en z, sol y) :
## à gauche les deux portes de sortie inox (fermées dans ce sens), puis `n` caissons de
## portillons et leurs passages, les poteaux des portes anti-fraude, et un caisson jusqu'au mur.
## On entre par le côté -z.
func _build_gate_row(xl: float, xr: float, z: float, y: float, n := 4) -> void:
	var steel := _mat("blanc", 0x6e7174)
	var steel_light := _mat("blanc", 0xb2b5b8)
	var green := _mat("blanc", 0x2fa38a)
	var arrow := _mat("blanc", 0x39d06a, false, true)
	var red := _mat("blanc", 0xc8281e)
	var purple := _mat("blanc", 0xb69ad8)
	# portes de sortie
	var exit_x := xl + 0.975
	for px in [xl + 0.1, xl + 1.85]:
		box(steel_light, 0.08, 2.1, 0.1, px, y + 1.05, z)
	box(steel_light, 1.95, 0.1, 0.1, exit_x, y + 2.1, z)
	box(M.noir, 0.7, 0.12, 0.02, exit_x, y + 2.25, z - 0.06)
	for k in 2:
		box(red, 0.08, 0.08, 0.01, exit_x - 0.25 + k * 0.5, y + 2.25, z - 0.075)
	for leaf_x in [xl + 0.55, xl + 1.4]:
		box(steel, 0.8, 1.45, 0.05, leaf_x, y + 0.85, z)
	_solid(Vector3(1.95, 2.1, 0.12), Vector3(exit_x, y + 1.05, z))
	# portillons
	var last := xl
	for i in n:
		var x := xl + 2.05 + i * 1.05
		last = x
		box(steel, 0.3, 0.9, 1.2, x, y + 0.45, z)
		box(steel_light, 0.32, 0.12, 1.22, x, y + 0.96, z)               # dessus
		box(steel_light, 0.32, 0.18, 0.3, x, y + 1.08, z - 0.45)          # tête arrondie
		add(PsxGeo.cylinder(0.08, 0.08, 0.01, 8), purple, Vector3(x, y + 1.03, z - 0.15))   # lecteur Navigo
		box(M.noir, 0.01, 0.16, 0.08, x - 0.155, y + 0.6, z - 0.5)
		box(arrow, 0.012, 0.04, 0.05, x - 0.157, y + 0.62, z - 0.5)
		box(red, 0.01, 0.1, 0.1, x - 0.155, y + 0.42, z - 0.5)
		if i < n - 1:
			# bras du tripode, en travers du passage
			add(PsxGeo.cylinder(0.02, 0.02, 0.45, 4), M.inox, Vector3(x + 0.38, y + 0.88, z - 0.2), Vector3(0, 0, PI / 2))
		# poteau de la porte anti-fraude, vert en haut, battant ouvert
		box(steel_light, 0.08, 1.7, 0.18, x, y + 0.85, z + 0.75)
		box(green, 0.085, 0.35, 0.185, x, y + 1.55, z + 0.75)
		add(PsxGeo.cylinder(0.14, 0.14, 0.28, 8), steel_light, Vector3(x + (0.2 if i < n - 1 else -0.2), y + 1.1, z + 0.75))
		_solid(Vector3(0.3, 1.0, 1.2), Vector3(x, y + 0.5, z))
	var end_x := last + 1.0
	if xr > end_x:
		_solid(Vector3(xr - end_x, 1.0, 1.2), Vector3((end_x + xr) / 2, y + 0.5, z))   # bout de ligne
