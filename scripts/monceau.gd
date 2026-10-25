extends Node3D
## Station Monceau et ses abords, reconstruits d'après le prototype navigateur « Monceau PS1 » :
## boulevard de Courcelles, bouche Guimard, Rotonde et grilles du parc, deux escaliers,
## couloir, quai, deux voies et tunnels.
## Mêmes coordonnées que le prototype : la rue est à y = 0, le quai à y = -6,48,
## les voies suivent l'axe X, la station est côté +Z.

# Bouche de métro et rue
const HX := 1.12          # demi-largeur de l'escalier
const Z0 := -3.0          # haut du premier escalier
const Z1 := 3.0           # bas du premier escalier
const ISLAND := [-9.0, -9.0, 9.0, 12.0]   # îlot central (x0, z0, x1, z1)
const W := 46.0           # demi-taille du quartier
const ROT := Vector3(-14, 0, 5)           # centre de la Rotonde

# Station
const PY := -6.48         # niveau du quai
const X0 := -30.0
const X1 := 30.0
const L := 60.0           # longueur du quai
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

# Passage sous les voies, entre les deux quais
const PX0 := 9.0          # haut des escaliers, sur chaque quai
const PX1 := 16.5         # bas des escaliers
const PX2 := 18.9         # mur du fond du passage
const PW := 1.6           # largeur des escaliers
const PFLOOR := -10.5     # sol du passage
const PCEIL := -8.2       # plafond du passage

var M := {}
var night := true
var underground := false
var _builder := PsxBuilder.new()
var _lanterns: Array[Vector3] = []
var _under_lamps: Array[Vector3] = [Vector3(0, -1.1, 5.5), Vector3(0, -1.1, 9.5), Vector3(0, -1.1, 13.2), Vector3(0, -3.0, 17.2)]
var _player: Node3D
var _collisions: StaticBody3D
var trafic: Trafic


func _ready() -> void:
	_make_materials()
	var barriers := _build_colliders()
	trafic = Trafic.new()
	trafic.name = "Trafic"
	add_child(trafic)
	# [z de la voie, côté des portes, sens, décalage dans le cycle, destination]
	trafic.setup(M, RY, PY - RY, [[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], barriers)
	_build_street()
	_build_entrance()
	_build_station()
	_build_guimard()
	_build_totem()
	_build_candelabra()
	_build_rotonde()
	_build_buildings()
	_build_trees()
	_build_passage()
	_build_clues()
	_builder.build(self)
	RenderingServer.global_shader_parameter_set("zone_color", Vector3(0.98, 0.97, 0.92))
	RenderingServer.global_shader_parameter_set("zone_min", Vector3(-31.0, -1000.0, 19.6))
	RenderingServer.global_shader_parameter_set("zone_max", Vector3(31.0, -0.3, 34.6))
	set_night(night)


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


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame MF01 · prochaine station : Monceau"
		return "Rame MF01 · direction %s" % train.destination
	if pos.y < PFLOOR + 0.3:
		return "Passage sous les voies · Monceau"
	if pos.y < PY - 0.2 and pos.x > PX0 - 0.5:
		return "Escalier · Monceau"
	if pos.y < -6.3:
		return "Quai · direction Nation" if pos.z > CZ else "Quai · direction Porte Dauphine"
	if pos.y < -3.3:
		return "Escalier · Monceau"
	if pos.y < -2.6:
		return "Couloir · Monceau"
	if pos.y < -0.1:
		return "Escalier · Monceau"
	if Vector2(pos.x - ROT.x, pos.z - ROT.z).length() < 11.0:
		return "Rotonde · parc Monceau"
	if pos.z > 18.0:
		return "Boulevard de Courcelles"
	return "Station Monceau"


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
		"carrelage": _mat("carrelage"), "balus": _mat("balustrade", 0xffffff, true), "enseigne": _mat("enseigne", 0xffffff, true),
		"plaque": _mat("plaque"), "plan": _mat("plan"), "globes": _mat("globes"), "lanterne": _mat("lanterne"),
		"fonte": _mat("blanc", 0x24443a), "fonteDark": _mat("blanc", 0x172a23),
		"facA": _mat("facade_a"), "facB": _mat("facade_b"), "porte": _mat("porte"), "zinc": _mat("zinc"),
		"corn": _mat("rot_corniche"), "tamb": _mat("rot_tambour"), "dome": _mat("dome"), "grille": _mat("grille"),
		"portail": _mat("portail", 0xffffff, true), "gardecorps": _mat("gardecorps", 0xffffff, true),
		"colonne": _mat("colonne"), "pierreT": _mat("pierre_taille"),
		"feuil": _mat("feuillage"), "tronc": _mat("blanc", 0x7c7464), "musee": _mat("musee", 0xffffff, true),
		"fleche": _mat("fleche"), "cand": _mat("candelabre", 0xffffff, true), "candPost": _mat("blanc", 0x4a3b33),
		"sortie": _mat("sortie", 0xffffff, true), "morris": _mat("blanc", 0x2c4b3c),
		"carreau": _mat("carreau"), "sol": _mat("sol_quai"), "bande": _mat("bande"), "voie": _mat("voie"),
		"plinthe": _mat("plinthe"), "quaiFace": _mat("blanc", 0x3c3a37), "rail": _mat("blanc", 0x9a9792),
		"neon": _mat("blanc", 0xffffff, false, true), "noir": _mat("blanc", 0x040404, false, true),
		"nom": _mat("nom_quai"), "nepas": _mat("nepas"), "direction": _mat("direction"),
		"sortieQ": _mat("sortie_quai"), "alarme": _mat("alarme"), "repere": _mat("repere"), "descente": _mat("descente"),
		"seat": _mat("blanc", 0xec7a1c), "inox": _mat("blanc", 0xb4b8bc), "tunnel": _mat("pierre", 0x5e5c58),
		"service": _mat("porte_service"), "marche": _mat("sol_quai", 0xb0b0b0),
		"platre": _mat("blanc", 0xbdbab1), "frise": _mat("frise"),
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
	_builder.add(geo, m, PsxGeo.xf(pos, rot, scale))


func add_xf(geo: Dictionary, m: Material, xform: Transform3D) -> void:
	_builder.add(geo, m, xform)


## Rectangle horizontal ; rx = PI/2 pour un plafond.
func rect(m: Material, x0: float, z0: float, x1: float, z1: float, y: float, tile: float, rx := -PI / 2) -> void:
	var g := PsxGeo.uv_scale(PsxGeo.plane(x1 - x0, z1 - z0, seg(x1 - x0), seg(z1 - z0)), (x1 - x0) / tile, (z1 - z0) / tile)
	add(g, m, Vector3((x0 + x1) / 2, y, (z0 + z1) / 2), Vector3(rx, 0, 0))


func box(m: Material, w: float, h: float, d: float, x: float, y: float, z: float, tu := 1.0, tv := 1.0) -> void:
	add(PsxGeo.uv_scale(PsxGeo.box(w, h, d, seg(w, 24), seg(h, 24), seg(d, 24)), tu, tv), m, Vector3(x, y, z))


func plane(m: Material, w: float, h: float, x: float, y: float, z: float, ry := 0.0, tu := 1.0, tv := 1.0, rx := 0.0) -> void:
	add(PsxGeo.uv_scale(PsxGeo.plane(w, h, seg(w), seg(h)), tu, tv), m, Vector3(x, y, z), Vector3(rx, ry, 0))


# --- Rue ----------------------------------------------------------------------

func _build_street() -> void:
	var I: Array = ISLAND
	rect(M.trottoir, I[0], I[1], -HX, I[3], 0, 3)
	rect(M.trottoir, HX, I[1], I[2], I[3], 0, 3)
	rect(M.trottoir, -HX, I[1], HX, Z0, 0, 3)
	rect(M.trottoir, -HX, Z1, HX, I[3], 0, 3)
	rect(M.paves, -W, -W, W, I[1], -0.02, 2.5)
	rect(M.paves, -W, I[3], W, W, -0.02, 2.5)
	rect(M.paves, -W, I[1], I[0], I[3], -0.02, 2.5)
	rect(M.paves, I[2], I[1], W, I[3], -0.02, 2.5)
	# bordures de l'îlot
	box(M.pierre, 18.3, 0.12, 0.15, 0, -0.06, I[1] - 0.075, 30, 0.2)
	box(M.pierre, 18.3, 0.12, 0.15, 0, -0.06, I[3] + 0.075, 30, 0.2)
	box(M.pierre, 0.15, 0.12, 21.0, I[0] - 0.075, -0.06, 1.5, 0.2, 35)
	box(M.pierre, 0.15, 0.12, 21.0, I[2] + 0.075, -0.06, 1.5, 0.2, 35)
	# Sous-couche : l'accrochage des sommets ouvre de fines fissures entre les dalles ;
	# on y verrait le ciel sans ce second sol, percé lui aussi par la trémie.
	rect(M.paves, -W, -W, W, Z0, -0.1, 2.5)
	rect(M.paves, -W, Z1, W, W, -0.1, 2.5)
	rect(M.paves, -W, Z0, -HX, Z1, -0.1, 2.5)
	rect(M.paves, HX, Z0, W, Z1, -0.1, 2.5)
	# trottoirs au pied des immeubles
	rect(M.trottoir, -W, 21, W, 25, 0.03, 3)
	rect(M.trottoir, -W, -25, W, -21, 0.03, 3)
	rect(M.trottoir, 19, -21, 23, 21, 0.03, 3)


# --- Trémie, escaliers et couloir ---------------------------------------------

func _build_entrance() -> void:
	box(M.pierre, 0.36, 0.45, 6.36, -1.3, 0.225, 0, 6, 0.5)
	box(M.pierre, 0.36, 0.45, 6.36, 1.3, 0.225, 0, 6, 0.5)
	box(M.pierre, 2.96, 0.45, 0.36, 0, 0.225, 3.0, 3, 0.5)
	plane(M.balus, 6.3, 0.95, -1.3, 0.93, 0, PI / 2, 8.4, 1)
	plane(M.balus, 6.3, 0.95, 1.3, 0.93, 0, PI / 2, 8.4, 1)
	plane(M.balus, 2.95, 0.95, 0, 0.93, 3.0, 0, 3.9, 1)
	box(M.fonte, 0.05, 0.05, 6.3, -1.3, 1.41, 0)
	box(M.fonte, 0.05, 0.05, 6.3, 1.3, 1.41, 0)
	box(M.fonte, 2.95, 0.05, 0.05, 0, 1.41, 3.0)
	# premier escalier
	for i in 12:
		var top := -(i + 1) * 0.27
		box(M.pierreS, 2 * HX, 3.8 + top, 0.5, 0, (top - 3.8) / 2, Z0 + i * 0.5 + 0.25, 2, 1)
	# murs carrelés de la trémie et du couloir
	plane(M.carrelage, 17, 3.6, -HX, -1.8, 5.5, PI / 2, 22, 5)
	plane(M.carrelage, 17, 3.6, HX, -1.8, 5.5, PI / 2, 22, 5)
	plane(M.carrelage, 2 * HX, 0.95, 0, -0.47, Z1, 0, 3, 1.2)
	plane(M.globes, 2.1, 0.5, 0, -0.62, Z1 - 0.02, 0)
	rect(M.carrelage, -HX, Z1, HX, 14, -0.92, 0.8, PI / 2)
	rect(M.pierreS, -HX, Z1, HX, 14, -3.24, 1.2)
	# second escalier, vers le quai
	for i in 12:
		var top := -3.24 - (i + 1) * 0.27
		box(M.pierreS, 2 * HX, top + 6.7, 0.5, 0, (top - 6.7) / 2, 14 + i * 0.5 + 0.25, 2, 1)
	plane(M.carrelage, 6.3, 5.9, -HX, -3.85, 17.15, PI / 2, 8, 7)
	plane(M.carrelage, 6.3, 5.9, HX, -3.85, 17.15, PI / 2, 8, 7)
	plane(M.carrelage, 2 * HX, Vector2(6, 3.06).length(), 0, (-0.92 - 3.98) / 2, 17, 0, 3, 8, -PI / 2 + atan2(3.06, 6))
	plane(M.sortieQ, 1.1, 0.28, 0, -1.25, 14.05, 0)
	plane(M.plaque, 1.4, 0.36, -HX + 0.02, -1.6, 8, PI / 2)


# --- Quai, voûte, voies et tunnels --------------------------------------------

func _build_station() -> void:
	# sols des quais, percés par les escaliers du passage
	rect(M.sol, X0, ZA, PX0, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, PX1, ZA, X1, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, PX0, ZA + PW, PX1, ZT0 - 0.55, PY, 2.4)
	rect(M.bande, X0, ZT0 - 0.55, X1, ZT0, PY + 0.006, 0.55)
	rect(M.sol, X0, ZT1 + 0.55, PX0, ZB, PY, 2.4)
	rect(M.sol, PX1, ZT1 + 0.55, X1, ZB, PY, 2.4)
	rect(M.sol, PX0, ZT1 + 0.55, PX1, ZB - PW, PY, 2.4)
	rect(M.bande, X0, ZT1, X1, ZT1 + 0.55, PY + 0.006, 0.55)
	rect(M.voie, X0, ZT0, X1, ZT1, RY, 1.2)
	plane(M.quaiFace, L, PY - RY, 0, (PY + RY) / 2, ZT0, 0, 20, 1)
	plane(M.quaiFace, L, PY - RY, 0, (PY + RY) / 2, ZT1, 0, 20, 1)
	for c in [25.5, 28.5]:
		for o in [-0.72, 0.72]:
			box(M.rail, L + 220, 0.14, 0.08, 0, RY + 0.07, c + o)

	# piédroits (avec l'ouverture de l'escalier) et plinthe brune
	var wl := 30 - HX
	var wc := (30 + HX) / 2
	for sx in [-1, 1]:
		plane(M.carreau, wl, WT - PY, sx * wc, (PY + WT) / 2, ZA, 0, wl / TW, (WT - PY) / TH)
	plane(M.carreau, L, WT - PY, 0, (PY + WT) / 2, ZB, 0, L / TW, (WT - PY) / TH)
	# plinthes, interrompues au-dessus des escaliers du passage
	for run in [[X0, -HX, ZA + 0.01], [HX, PX0, ZA + 0.01], [PX1, X1, ZA + 0.01], [X0, PX0, ZB - 0.01], [PX1, X1, ZB - 0.01]]:
		var length: float = run[1] - run[0]
		plane(M.plinthe, length, 0.2, (run[0] + run[1]) / 2, PY + 0.1, run[2], 0, length / 0.6, 1)

	_build_vault()
	for sx in [-1.0, 1.0]:
		_build_tympan_and_tunnel(sx)

	# rampes de néons
	for z in [23.2, 30.8]:
		box(M.neon, L - 2, 0.1, 0.26, 0, -1.6, z)
		box(M.inox, L - 2, 0.06, 0.36, 0, -1.52, z)

	# plaques, panneaux, mobilier
	for x in [-21, -7, 9, 23]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZB - 0.03, PI)
	for x in [-15, 15]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZA + 0.03, 0)
	for x in [-26, -12, 4, 18]:
		plane(M.nepas, 1.1, 0.21, x, -5.5, ZB - 0.03, PI)
	plane(M.direction, 0.9, 1.2, -3.2, -5.05, ZA + 0.03, 0)
	for x in [-24, 8]:
		box(M.inox, 1.5, 1.5, 0.05, x, -5.05, ZA + 0.03)
		plane(M.plan, 1.38, 1.38, x, -5.05, ZA + 0.06, 0)
	for r in [PI / 2, -PI / 2]:
		var o := 0.02 if r > 0 else -0.02
		plane(M.sortieQ, 1.2, 0.3, o, -3.3, 22.2, r)
		plane(M.alarme, 1.0, 0.25, -9 + o, -3.85, 20.6, r)
		plane(M.alarme, 1.0, 0.25, 12 + o, -3.85, 20.6, r)
	box(M.inox, 0.03, 0.9, 0.03, 0, -2.8, 22.2)
	box(M.inox, 0.05, 0.05, 0.75, -9, -3.7, 20.35)
	box(M.inox, 0.05, 0.05, 0.75, 12, -3.7, 20.35)
	plane(M.repere, 0.45, 0.45, -28.6, -3.4, 25.5, PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, -28.6, -2.6, 25.5)
	plane(M.repere, 0.45, 0.45, 28.6, -3.4, 28.5, -PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, 28.6, -2.6, 28.5)

	# écrans des prochains passages, un par quai
	for screen in [[22.4, 0], [31.6, 1]]:
		var z: float = screen[0]
		var m: Material = trafic.siel_materials[screen[1]]
		for x in [5, -17]:
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

	# sièges « Motte » orange
	var bowl := PsxGeo.sphere(0.24, 8, 3, 0, TAU, PI / 2, PI / 2)
	for s in [[-18, 20.45, 1], [-3, 20.45, 1], [18, 20.45, 1], [-12, 33.55, -1], [6, 33.55, -1], [21, 33.55, -1]]:
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
	var n_len := 30
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
	add(PsxGeo.polygon(outline, 1 / TW, 1 / TH), M.carreau, Vector3(sx * 30, 0, 0), Vector3(0, -PI / 2, 0))

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
			var x := sx * (30 + TUNNEL_LEN * j / nx)
			g.p.append(Vector3(x, pr[i][1], pr[i][0]))
			g.n.append(Vector3(0, pr[i][2], pr[i][3]))
			g.uv.append(Vector2(x / 2.4, acc / 1.2))
	for i in pr.size() - 1:
		for j in nx:
			var a := i * (nx + 1) + j
			var b := a + nx + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, M.tunnel, Vector3.ZERO)

	rect(M.voie, 30.0 if sx > 0 else -30 - TUNNEL_LEN, ZT0, 30 + TUNNEL_LEN if sx > 0 else -30.0, ZT1, RY, 1.2)
	var x := 38.0
	while x < 30 + TUNNEL_LEN:
		box(M.neon, 0.12, 0.12, 0.06, sx * x, -4.5, ZT0 + 0.04)
		box(M.neon, 0.12, 0.12, 0.06, sx * (x + 7), -4.5, ZT1 - 0.04)
		x += 14
	plane(M.noir, 6.2, 6, sx * (30 + TUNNEL_LEN - 0.5), -4.6, CZ, PI / 2)
	# panneaux « Descente interdite » en bout de quai
	plane(M.descente, 0.55, 1.65, sx * 29.5, PY + 0.83, ZT0 - 0.35, -sx * PI / 2)
	plane(M.descente, 0.55, 1.65, sx * 29.5, PY + 0.83, ZT1 + 0.35, -sx * PI / 2)


# --- Bouche Guimard : arcs, lanternes, enseigne -------------------------------

func _build_guimard() -> void:
	for s in [-1.0, 1.0]:
		add(PsxGeo.tube([Vector3(1.45 * s, 0, Z0), Vector3(1.5 * s, 1.4, Z0), Vector3(1.38 * s, 2.6, Z0),
			Vector3(1.1 * s, 3.25, Z0), Vector3(0.9 * s, 3.32, Z0)], 10, 0.055, 5), M.fonte, Vector3.ZERO)
		add(PsxGeo.tube([Vector3(1.5 * s, 0, Z0), Vector3(1.62 * s, 1.8, Z0), Vector3(1.68 * s, 3.3, Z0),
			Vector3(1.5 * s, 4.0, Z0), Vector3(1.22 * s, 4.02, Z0)], 10, 0.045, 5), M.fonte, Vector3.ZERO)
		box(M.fonteDark, 0.22, 0.32, 0.22, 1.47 * s, 0.16, Z0)
		add(PsxGeo.sphere(0.17, 6, 4), M.lanterne, Vector3(1.2 * s, 3.84, Z0), Vector3.ZERO, Vector3(1, 1.25, 1))
		add(PsxGeo.cone(0.2, 0.16, 5), M.fonteDark, Vector3(1.2 * s, 4.04, Z0))
		_lanterns.append(Vector3(1.2 * s, 3.84, Z0))
	box(M.fonte, 1.96, 0.56, 0.06, 0, 3.28, Z0)
	plane(M.enseigne, 1.84, 0.46, 0, 3.28, Z0 - 0.035, PI)
	plane(M.enseigne, 1.84, 0.46, 0, 3.28, Z0 + 0.035, 0)


## Totem « M » avec le plan du quartier.
func _build_totem() -> void:
	var g := PsxGeo.xf(Vector3(-2.55, 0, -2.2), Vector3(0, 0.25, 0))
	add_xf(PsxGeo.cylinder(0.035, 0.05, 2.3, 5), M.fonte, g * PsxGeo.xf(Vector3(-0.5, 1.15, 0)))
	add_xf(PsxGeo.cylinder(0.035, 0.05, 2.3, 5), M.fonte, g * PsxGeo.xf(Vector3(0.5, 1.15, 0)))
	add_xf(PsxGeo.box(1.08, 1.26, 0.07), M.fonte, g * PsxGeo.xf(Vector3(0, 1.62, 0)))
	add_xf(PsxGeo.plane(0.94, 1.1), M.plan, g * PsxGeo.xf(Vector3(0, 1.62, -0.04), Vector3(0, PI, 0)))
	add_xf(PsxGeo.plane(0.94, 1.1), M.plan, g * PsxGeo.xf(Vector3(0, 1.62, 0.04)))
	add_xf(PsxGeo.plane(1.12, 0.3), M.plaque, g * PsxGeo.xf(Vector3(0, 2.42, -0.03), Vector3(0, PI, 0)))
	add_xf(PsxGeo.plane(1.12, 0.3), M.plaque, g * PsxGeo.xf(Vector3(0, 2.42, 0.03)))
	add_xf(PsxGeo.octahedron(0.16), M.fonte, g * PsxGeo.xf(Vector3(0, 2.7, 0), Vector3.ZERO, Vector3(1.6, 1, 0.6)))


## Candélabre avec les plaques du musée Nissim de Camondo.
func _build_candelabra() -> void:
	var x := 4.6
	var z := -5.2
	add(PsxGeo.cylinder(0.07, 0.13, 4.2, 6), M.candPost, Vector3(x, 2.1, z))
	add(PsxGeo.cylinder(0.2, 0.24, 0.6, 6), M.candPost, Vector3(x, 0.3, z))
	for a in [0.0, PI / 2]:
		plane(M.cand, 0.75, 1.5, x, 4.85, z, a)
	plane(M.musee, 0.75, 0.75, x, 2.85, z - 0.09, PI)
	plane(M.musee, 0.75, 0.75, x, 2.85, z + 0.09, 0)
	plane(M.fleche, 1.25, 0.3, x - 0.35, 2.25, z - 0.08, PI)
	_lanterns.append(Vector3(x, 4.6, z))


# --- Rotonde de Monceau et grilles du parc ------------------------------------

func _cyl(m: Material, r: float, h: float, y: float, tu: float, tv: float, open := true) -> void:
	add(PsxGeo.uv_scale(PsxGeo.cylinder(r, r, h, 16, 1, open), tu, tv), m, Vector3(ROT.x, y, ROT.z))


func _build_rotonde() -> void:
	_cyl(M.pierre, 6.3, 0.5, 0.25, 12, 0.5, false)
	_cyl(M.pierreT, 4.9, 5.2, 3.1, 16, 9)          # mur du pavillon derrière les colonnes
	for i in 12:                                    # colonnes cannelées
		var a := i / 12.0 * TAU + 0.13
		var cx := ROT.x + 5.85 * cos(a)
		var cz := ROT.z + 5.85 * sin(a)
		add(PsxGeo.cylinder(0.3, 0.34, 4.7, 6, 2, true), M.colonne, Vector3(cx, 3.05, cz))
		add(PsxGeo.cylinder(0.44, 0.44, 0.22, 6), M.pierreS, Vector3(cx, 5.52, cz))
		add(PsxGeo.cylinder(0.42, 0.46, 0.25, 6), M.pierreS, Vector3(cx, 0.62, cz))
	_cyl(M.gardecorps, 5.6, 2.0, 1.5, 22, 1)       # grilles entre les colonnes
	_cyl(M.corn, 6.4, 1.5, 6.45, 4, 1, false)
	_cyl(M.tamb, 4.8, 2.2, 8.3, 4, 1)
	add(PsxGeo.uv_scale(PsxGeo.sphere(5.0, 16, 6, 0, TAU, 0, PI / 2), 8, 3), M.dome,
		Vector3(ROT.x, 9.35, ROT.z), Vector3.ZERO, Vector3(1, 0.82, 1))
	add(PsxGeo.cylinder(0.35, 0.5, 0.6, 8), M.fonteDark, Vector3(ROT.x, 13.6, ROT.z))
	add(PsxGeo.cylinder(0.03, 0.03, 3, 4), M.fonteDark, Vector3(ROT.x, 15.3, ROT.z))
	# grilles dorées de part et d'autre
	for gate in [[-1.0, -5.4], [11.4, 15.8]]:
		var za: float = gate[0]
		var zb: float = gate[1]
		plane(M.portail, zb - za, 4.2, ROT.x, 2.1, (za + zb) / 2, PI / 2, (zb - za) / 2.2, 1)
		for pz in [za, zb]:
			box(M.grille, 0.75, 5.0, 0.75, ROT.x, 2.5, pz, 0.6, 1)
			add(PsxGeo.sphere(0.32, 6, 4), M.lanterne, Vector3(ROT.x, 5.4, pz))


# --- Immeubles haussmanniens --------------------------------------------------

func _wall(m: Material, x1: float, z1: float, x2: float, z2: float, y0: float, y1: float, tw: float, th: float) -> void:
	var length := Vector2(x2 - x1, z2 - z1).length()
	plane(m, length, y1 - y0, (x1 + x2) / 2, (y0 + y1) / 2, (z1 + z2) / 2, atan2(-(z2 - z1), x2 - x1), length / tw, (y1 - y0) / th)


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


func _build_buildings() -> void:
	_block(-34, 25, -8, 36, 18, "a")
	_block(-6, 25, 12, 36, 19, "a")
	_block(14, 25, 38, 36, 17, "b")
	_block(23, -21, 34, 21, 17, "b")
	_block(-30, -36, -4, -25, 18, "b")
	_block(-2, -36, 20, -25, 19, "a")
	_block(22, -36, 38, -25, 18, "a")
	plane(M.sortie, 0.62, 0.62, 3.0, 1.7, 24.97, PI)
	plane(M.sortie, 0.62, 0.62, 22.97, 1.7, -8, -PI / 2)


# --- Platanes et colonne Morris -----------------------------------------------

const TREES := [[-7, -7], [7, -7.5], [-7.5, 10], [7.5, 10.5], [-20, -12], [-22, 0], [-24, 14],
	[-19, 20], [13, 15.5], [-4, 17], [16, -14], [-12, -17], [3, -17]]
const MORRIS := Vector3(11, 0, 16)


func _build_trees() -> void:
	for i in TREES.size():
		var x: float = TREES[i][0]
		var z: float = TREES[i][1]
		var s := 0.9 + ((i * 37) % 5) / 12.0
		add(PsxGeo.cylinder(0.22 * s, 0.32 * s, 5 * s, 5), M.tronc, Vector3(x, 2.5 * s, z))
		add(PsxGeo.uv_scale(PsxGeo.icosahedron(2.6 * s), 2, 2), M.feuil, Vector3(x, 6 * s, z), Vector3(0, x * 1.7, 0))
		add(PsxGeo.uv_scale(PsxGeo.icosahedron(2.0 * s), 2, 2), M.feuil, Vector3(x + 1.2 * s, 7.2 * s, z - 0.6 * s), Vector3(0, 0, z * 0.9))
	add(PsxGeo.cylinder(0.62, 0.62, 3.2, 8), M.morris, MORRIS + Vector3(0, 1.6, 0))
	add(PsxGeo.sphere(0.75, 8, 4, 0, TAU, 0, PI / 2), M.morris, MORRIS + Vector3(0, 3.2, 0), Vector3.ZERO, Vector3(1, 1.3, 1))


# --- Passage sous les voies, vers le quai direction Nation --------------------
# Chaque quai a un escalier le long de son mur ; il descend vers +x jusqu'à un passage
# qui file sous les voies d'un quai à l'autre. Habillage d'après des photos de couloirs et
# d'escaliers du métro prises comme modèles : carreaux blancs biseautés, frise brune, voûte
# peinte en blanc, sol gris foncé, marches à nez en inox, main courante brune.

const STEP := (PY - PFLOOR) / 15.0
const PSPRING := PCEIL - 0.45    # naissance de la voûte du passage


func _build_passage() -> void:
	var to_nation := _sign([["ligne", "Nation"]])
	var to_exit := _sign([["ligne", "Pte Dauphine"], ["sortie", "Sortie"]])
	for well in [[ZA, 1.0, to_nation], [ZB, -1.0, to_exit]]:
		var zw: float = well[0]          # mur du quai
		var inward: float = well[1]      # sens du mur vers les voies
		var zc := zw + inward * PW / 2   # axe de l'escalier
		var zi := zw + inward * PW       # bord de la trémie côté voies
		# marches grises à nez en inox, bande d'éveil en haut
		for i in 15:
			var top := PY - (i + 1) * STEP
			var x := PX0 + i * 0.5 + 0.25
			box(M.marche, 0.5, top - PFLOOR + 0.3, PW, x, (top + PFLOOR - 0.3) / 2, zc, 1, 2)
			box(M.inox, 0.05, 0.02, PW, x - 0.225, top + 0.01, zc)
		rect(M.bande, PX0 - 0.6, minf(zw, zi), PX0, maxf(zw, zi), PY + 0.006, 0.55)
		# murs de la trémie : carreaux, plinthe brune
		var depth := PY - PFLOOR
		for z in [zw, zi]:
			plane(M.carreau, PX1 - PX0, depth, (PX0 + PX1) / 2, (PY + PFLOOR) / 2, z - inward * 0.01 * signf(z - zc), 0, (PX1 - PX0) / TW, depth / TH)
		plane(M.carreau, PW, PY - PSPRING, PX1, (PY + PSPRING) / 2, zc, PI / 2, PW / TW, (PY - PSPRING) / TH)   # bout de la dalle
		# main courante le long du mur
		var rail_len := Vector2(PX1 - PX0, depth).length()
		add(PsxGeo.box(rail_len, 0.04, 0.04), M.candPost, Vector3((PX0 + PX1) / 2, (PY + PFLOOR) / 2 + 0.9, zw + inward * 0.06),
			Vector3(0, 0, -atan2(depth, PX1 - PX0)))
		# garde-corps autour de la trémie
		plane(M.gardecorps, PX1 - PX0, 1.0, (PX0 + PX1) / 2, PY + 0.5, zi, 0, PX1 - PX0, 1)
		plane(M.gardecorps, PW, 1.0, PX1, PY + 0.5, zc, PI / 2, PW, 1)
		box(M.fonte, PX1 - PX0, 0.05, 0.05, (PX0 + PX1) / 2, PY + 1.0, zi)
		box(M.fonte, 0.05, 0.05, PW, PX1, PY + 1.0, zc)
		# panneau suspendu au-dessus du haut de l'escalier, lisible des deux côtés
		var sign_m: Material = well[2]
		var sign_h := 0.25 * (2 if sign_m == to_exit else 1)
		for r in [PI / 2, -PI / 2]:
			plane(sign_m, 1.5, sign_h * 2, PX0 - 0.4 + (0.03 if r > 0 else -0.03), -4.3, zc, r)
		box(M.fonteDark, 0.04, sign_h * 2 + 0.02, 1.52, PX0 - 0.4, -4.3, zc)
		box(M.inox, 0.03, 1.4 - sign_h + 0.25, 0.03, PX0 - 0.4, -3.35 - (sign_h - 0.25) / 2, zc)

	# le passage : murs carrelés, frise brune, plinthe, voûte blanche, sol gris foncé
	var mid := (ZA + ZB) / 2
	var wall_h := PSPRING - PFLOOR
	rect(M.sol, PX1, ZA, PX2, ZB, PFLOOR, 2.4)
	for wall in [[PX2, ZB - ZA, mid], [PX1, ZB - ZA - 2 * PW, mid]]:
		var x: float = wall[0]
		var length: float = wall[1]
		plane(M.carreau, length, wall_h, x, (PFLOOR + PSPRING) / 2, wall[2], PI / 2, length / TW, wall_h / TH)
		plane(M.frise, length, 0.14, x + (0.01 if x < PX2 else -0.01), PSPRING - 0.07, wall[2], PI / 2, length / 0.6, 1)
		plane(M.plinthe, length, 0.2, x + (0.01 if x < PX2 else -0.01), PFLOOR + 0.1, wall[2], PI / 2, length / 0.6, 1)
	for z in [ZA, ZB]:
		plane(M.carreau, PX2 - PX1, PCEIL - PFLOOR, (PX1 + PX2) / 2, (PCEIL + PFLOOR) / 2, z, 0, (PX2 - PX1) / TW, (PCEIL - PFLOOR) / TH)
	_build_passage_vault()
	box(M.neon, 0.15, 0.05, ZB - ZA - 2, (PX1 + PX2) / 2, PCEIL - 0.03, mid)
	# au pied de chaque escalier, un panneau sur le mur d'en face
	plane(to_nation, 1.5, 0.5, PX2 - 0.02, -9.1, ZA + PW / 2 + 1.0, -PI / 2)
	plane(to_exit, 1.5, 1.0, PX2 - 0.02, -9.35, ZB - PW / 2 - 1.2, -PI / 2)

	# plans de ligne sur les quais, examinables
	for p in [["Porte Dauphine", Vector3(-21.7, -4.98, ZA + 0.03), 0.0], ["Nation", Vector3(-2.0, -4.98, ZB - 0.03), PI]]:
		var terminus: String = p[0]
		var pos: Vector3 = p[1]
		var m := _sign_from_texture(Panneaux.line_plan(self, "Monceau", terminus))
		plane(m, 0.9, 1.6, pos.x, pos.y, pos.z, p[2])
		var item := Examinable.new()
		item.title = "Plan de la ligne 2"
		item.description = Panneaux.line_plan_text("Monceau", terminus)
		item.position = pos
		_examinable_shape(item, Vector3(0.9, 1.6, 0.15))
		add_child(item)


## Voûte surbaissée du passage, d'un mur à l'autre, sur toute sa longueur.
func _build_passage_vault() -> void:
	var g := PsxGeo.empty()
	var n_arc := 8
	var n_len := 14
	var cx := (PX1 + PX2) / 2
	var half := (PX2 - PX1) / 2
	for i in n_arc + 1:
		var t := PI * i / n_arc
		var x := cx + half * cos(t)
		var y := PSPRING + (PCEIL - PSPRING) * sin(t)
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


func _sign(rows: Array) -> ShaderMaterial:
	return _sign_from_texture(Panneaux.direction(self, rows))


## Matériau d'un panneau dessiné : légèrement lumineux, comme un panneau émaillé sous les néons.
func _sign_from_texture(tex: Texture2D) -> ShaderMaterial:
	var m: ShaderMaterial = M.inox.duplicate()
	m.set_shader_parameter("albedo_texture", tex)
	m.set_shader_parameter("albedo_color", Vector3.ONE)
	m.set_shader_parameter("emission", Vector3(0.2, 0.2, 0.2))
	return m


# --- Indices du chapitre 1 (provisoires) --------------------------------------

func _build_clues() -> void:
	# Porte de service dans le mur de tête, au bout du quai.
	var door := Examinable.new()
	door.title = "Porte de service"
	door.description = "Porte métallique verrouillée. Autour de la serrure, des rayures fraîches dans la peinture."
	door.evidence_id = "serrure"
	door.position = Vector3(-29.97, PY + 1.05, 21.4)
	_examinable_shape(door, Vector3(0.1, 2.1, 0.9))
	add_child(door)
	box(M.service, 0.06, 2.1, 0.9, -29.97, PY + 1.05, 21.4)

	# Badge glissé sous le dernier siège du quai.
	var badge := Examinable.new()
	badge.title = "Badge RATP"
	badge.description = "Une carte d'agent glissée sous le siège. Photo d'identité : Karim Benali."
	badge.evidence_id = "badge"
	badge.position = Vector3(18.95, PY + 0.01, 20.75)
	_examinable_shape(badge, Vector3(0.45, 0.16, 0.45))
	add_child(badge)
	box(M.neon, 0.09, 0.008, 0.055, 18.95, PY + 0.005, 20.75)


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
	shape.position = pos
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


## Construit toutes les collisions ; renvoie les garde-fous des deux quais (voie 1, voie 2).
func _build_colliders() -> Array[CollisionShape3D]:
	_collisions = StaticBody3D.new()
	_collisions.name = "Collisions"
	add_child(_collisions)

	# Sol de la rue, percé par la trémie.
	_solid(Vector3(2 * W, 0.9, W + Z0), Vector3(0, -0.45, (-W + Z0) / 2))
	_solid(Vector3(2 * W, 0.9, W - Z1), Vector3(0, -0.45, (W + Z1) / 2))
	for sx in [-1, 1]:
		_solid(Vector3(W - HX, 0.9, Z1 - Z0), Vector3(sx * (W + HX) / 2, -0.45, 0))
		# balustrade et parapet de la trémie
		_solid(Vector3(0.36, 1.5, 6.36), Vector3(sx * 1.3, 0.75, 0))
	_solid(Vector3(2.96, 1.5, 0.36), Vector3(0, 0.75, 3.0))

	# Escaliers d'accès et couloir.
	_ramp(Vector3(0, 0, Z0), Vector3(0, -3.24, Z1), 2 * HX)
	_ramp(Vector3(0, -3.24, 14), Vector3(0, PY, ZA), 2 * HX)
	_solid(Vector3(2 * HX, 0.2, 14 - Z1), Vector3(0, -3.34, (Z1 + 14) / 2))
	for sx in [-1, 1]:
		_solid(Vector3(0.2, 3.6, 17), Vector3(sx * (HX + 0.1), -1.8, 5.5))
		_solid(Vector3(0.2, 5.9, 6.3), Vector3(sx * (HX + 0.1), -3.85, 17.15))

	# Les deux quais, percés par les escaliers du passage.
	var barriers: Array[CollisionShape3D] = []
	for quai in [[ZA, ZT0, 1.0], [ZB, ZT1, -1.0]]:
		var zw: float = quai[0]       # mur du quai
		var ze: float = quai[1]       # bord du quai
		var inward: float = quai[2]   # sens du mur vers les voies
		var zi := zw + inward * PW
		var depth := absf(ze - zw)
		_solid(Vector3(PX0 - X0, 0.2, depth), Vector3((X0 + PX0) / 2, PY - 0.1, (zw + ze) / 2))
		_solid(Vector3(X1 - PX1, 0.2, depth), Vector3((PX1 + X1) / 2, PY - 0.1, (zw + ze) / 2))
		_solid(Vector3(PX1 - PX0, 0.2, absf(ze - zi)), Vector3((PX0 + PX1) / 2, PY - 0.1, (zi + ze) / 2))
		if zw == ZA:
			# le mur du quai A est percé par l'escalier qui descend du couloir
			for sx in [-1, 1]:
				_solid(Vector3(30 - HX, WT - PFLOOR, 0.2), Vector3(sx * (30 + HX) / 2, (PFLOOR + WT) / 2, zw - 0.1))
		else:
			_solid(Vector3(L, WT - PFLOOR, 0.2), Vector3(0, (PFLOOR + WT) / 2, zw + 0.1))
		for sx in [-1, 1]:
			_solid(Vector3(0.2, 4, depth), Vector3(sx * 30.1, PY + 2, (zw + ze) / 2))
			# bouts de quai au-delà des rames : garde-fou permanent
			_solid(Vector3(2.4, 2.0, 0.1), Vector3(sx * 28.9, PY + 1.0, ze - inward * 0.3))
		# garde-fou le long des voies, ôté quand la rame est à quai
		barriers.append(_solid(Vector3(56.0, 2.0, 0.1), Vector3(0, PY + 1.0, ze - inward * 0.3)))
		# trémie de l'escalier : garde-corps, mur côté voies, rampe
		_solid(Vector3(PX1 - PX0, 1.1, 0.06), Vector3((PX0 + PX1) / 2, PY + 0.55, zi))
		_solid(Vector3(0.06, 1.1, PW), Vector3(PX1, PY + 0.55, zw + inward * PW / 2))
		_solid(Vector3(PX1 - PX0, PY - PFLOOR, 0.2), Vector3((PX0 + PX1) / 2, (PY + PFLOOR) / 2, zi + inward * 0.1))
		_ramp(Vector3(PX0, PY, zw + inward * PW / 2), Vector3(PX1, PFLOOR, zw + inward * PW / 2), PW)

	# Passage sous les voies.
	_solid(Vector3(PX2 - PX1, 0.2, ZB - ZA), Vector3((PX1 + PX2) / 2, PFLOOR - 0.1, (ZA + ZB) / 2))
	_solid(Vector3(0.2, PCEIL - PFLOOR, ZB - ZA), Vector3(PX2 + 0.1, (PFLOOR + PCEIL) / 2, (ZA + ZB) / 2))
	_solid(Vector3(0.2, PCEIL - PFLOOR, ZB - ZA - 2 * PW), Vector3(PX1 - 0.1, (PFLOOR + PCEIL) / 2, (ZA + ZB) / 2))

	# Rue : façades, Rotonde, grilles du parc, mobilier.
	_solid(Vector3(0.4, 6, 2 * W), Vector3(-26.2, 3, 0))
	_solid(Vector3(0.4, 6, 2 * W), Vector3(22.4, 3, 0))
	_solid(Vector3(2 * W, 6, 0.4), Vector3(0, 3, -24.4))
	_solid(Vector3(2 * W, 6, 0.4), Vector3(0, 3, 24.4))
	_post(6.6, 10.0, ROT)
	_solid(Vector3(1.2, 5, 5.2), Vector3(ROT.x, 2.5, -3.2))
	_solid(Vector3(1.2, 5, 5.2), Vector3(ROT.x, 2.5, 13.6))
	for t in TREES:
		_post(0.35, 3.0, Vector3(t[0], 0, t[1]))
	_post(0.65, 3.0, MORRIS)
	_post(0.25, 3.0, Vector3(4.6, 0, -5.2))
	return barriers
