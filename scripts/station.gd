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
var _solid_side := 1.0
var _lanterns: Array[Vector3] = []
## Lampes des parties souterraines (couloirs, escaliers), éclairage par sommet.
var _under_lamps: Array[Vector3] = []
## Personnages présents, par identifiant de dialogue.
var people := {}
var _player: Node3D
var _collisions: StaticBody3D
var trafic: Trafic


## À appeler en tête du _ready() de la station : matériaux et corps des collisions.
func _begin() -> void:
	add_to_group("lieu")
	if not Enquete.started:   # lancé directement depuis l'éditeur, sans passer par le titre
		Enquete.new_game()
	Sons.playing = true
	_make_materials()
	_collisions = StaticBody3D.new()
	_collisions.name = "Collisions"
	add_child(_collisions)


## Rames et écrans : [z de la voie, côté des portes, sens, décalage dans le cycle, destination].
func _setup_trafic(tracks: Array, barriers: Array[CollisionShape3D]) -> void:
	trafic = Trafic.new()
	trafic.name = "Trafic"
	add_child(trafic)
	trafic.setup(M, RY, PY - RY, tracks, barriers)


## Zone éclairée par les néons du quai (blanc chaud), sur toute la longueur de la station.
func _set_platform_zone() -> void:
	_global("zone_color", Vector3(0.98, 0.97, 0.92))
	_global("zone_min", Vector3(-HALF - 1.0, -1000.0, ZA - 0.4))
	_global("zone_max", Vector3(HALF + 1.0, -0.3, ZB + 0.6))


func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
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
	var pos: Array[Vector3] = []
	var col: Array[Vector3] = []
	for p in _lanterns:
		pos.append(p)
		col.append(Vector3(1.5, 0.9, 0.4) if on else Vector3.ZERO)
	for p in _under_lamps:
		pos.append(p)
		col.append(Vector3(1.05, 1.0, 0.85))
	while pos.size() < 8:
		pos.append(Vector3(0, -99, 0))
		col.append(Vector3.ZERO)
	_global("lamp_pos_a", _pack(pos, 0))
	_global("lamp_pos_b", _pack(pos, 4))
	_global("lamp_col_a", _pack(col, 0))
	_global("lamp_col_b", _pack(col, 4))
	M.lanterne.set_shader_parameter("emission", Vector3(1.4, 1.0, 0.6) if on else Vector3.ZERO)
	M.cand.set_shader_parameter("emission", Vector3(0.9, 0.8, 0.5) if on else Vector3.ZERO)
	_apply_fog()


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
	_builder.add(geo, m, _mirror * PsxGeo.xf(pos, rot, scale))


func add_xf(geo: Dictionary, m: Material, xform: Transform3D) -> void:
	_builder.add(geo, m, _mirror * xform)



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


## Voûte, murs de tête, tunnels et rampes de néons.
func _build_shell() -> void:
	_build_vault()
	for sx in [-1.0, 1.0]:
		_build_tympan_and_tunnel(sx)

	# rampes de néons
	for z in [23.2, 30.8]:
		box(M.neon, L - 2, 0.1, 0.26, 0, -1.6, z)
		box(M.inox, L - 2, 0.06, 0.36, 0, -1.52, z)


## Écrans des prochains passages, suspendus au-dessus de chaque quai aux abscisses données.
func _build_screens(xs: Array) -> void:
	for screen in [[22.4, 0], [31.6, 1]]:
		var z: float = screen[0]
		var m: Material = trafic.siel_materials[screen[1]]
		for x in xs:
			for r in [PI / 2, -PI / 2]:
				plane(m, 1.6, 0.76, x + (0.03 if r > 0 else -0.03), -3.5, z, r)
			box(M.fonteDark, 0.04, 0.78, 1.62, x, -3.5, z)
			var screen_item := Examinable.new()
			screen_item.title = "Écran des prochains passages"
			screen_item.position = Vector3(x, -3.5, z)
			_examinable_shape(screen_item, Vector3(0.2, 0.8, 1.7))
			add_child(screen_item)
			trafic.siel_examinables[screen[1]].append(screen_item)
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
	shape.position = Vector3(pos.x * _solid_side, pos.y, pos.z)
	shape.rotation = rot
	_collisions.add_child(shape)
	return shape


func _post(radius: float, height: float, pos: Vector3) -> void:
	var shape := CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = radius
	shape.shape.height = height
	shape.position = pos + Vector3(0, height / 2, 0)
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
