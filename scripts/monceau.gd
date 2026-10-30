extends Station
## Station Monceau et ses abords, reconstruits d'après le prototype navigateur « Monceau PS1 » :
## boulevard de Courcelles, bouche Guimard, Rotonde et grilles du parc, deux escaliers,
## couloir, quai, deux voies et tunnels.
## Mêmes coordonnées que le prototype (repère commun des stations, voir Station).

# Bouche de métro et rue
const HX := 1.12          # demi-largeur de l'escalier
const Z0 := -3.0          # haut du premier escalier
const Z1 := 3.0           # bas du premier escalier
const ISLAND := [-9.0, -9.0, 9.0, 12.0]   # îlot central (x0, z0, x1, z1)
const W := 46.0           # demi-taille du quartier
const ROT := Vector3(-14, 0, 5)           # centre de la Rotonde

# Passage sous les voies, entre les deux quais
const PX0 := 9.0          # haut des escaliers, sur chaque quai
const PX1 := 16.5         # bas des escaliers
const PX2 := 18.9         # mur du fond du passage
const PW := 1.6           # largeur des escaliers
const PFLOOR := -10.5     # sol du passage
const PCEIL := -8.2       # plafond du passage

var loge_door: Node3D
var kiosk_shutter: Node3D


func _ready() -> void:
	# (la salle des billets est éclairée par sa zone de néons, pas par ces lampes)
	_under_lamps = [Vector3(0, -1.2, -0.5), Vector3(-1.5, 3.2, 21.4), Vector3(0, -1.1, 13.2), Vector3(0, -3.0, 17.2),
		Vector3(0, -1.6, 2.0)]   # bas du premier escalier
	_begin()
	_setup_trafic([[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], _build_colliders())
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
	_build_ticket_hall()
	_build_kiosk()
	_build_clues()
	_place_people()
	var chapter := preload("res://scripts/chapitre_1_jeu.gd").new()
	chapter.name = "Chapitre1"
	add_child(chapter)
	_builder.build(self)
	_set_platform_zone()
	RenderingServer.global_shader_parameter_set("zone2_color", Vector3(0.98, 0.98, 0.96))
	var hall_x := [-HALL_W * GUICHET_SIDE, LOGE_X * GUICHET_SIDE]
	RenderingServer.global_shader_parameter_set("zone2_min", Vector3(minf(hall_x[0], hall_x[1]) - 0.1, CY - 0.1, HALL_Z0 - 0.05))
	RenderingServer.global_shader_parameter_set("zone2_max", Vector3(maxf(hall_x[0], hall_x[1]) + 0.1, HALL_TOP + 0.1, HALL_Z1 + 0.05))
	set_night(night)



## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame MF01 · prochaine station : %s" % next_station("Monceau", train.destination)
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



## La salle des billets est décrite côté guichet en +x, puis retournée en miroir (comme à
## Monceau : en allant vers les quais, le guichet et les portillons sont à droite).
func _set_hall_mirror(on: bool) -> void:
	_mirror = Transform3D(Basis.from_scale(Vector3(GUICHET_SIDE, 1, 1)), Vector3.ZERO) if on else Transform3D.IDENTITY
	_solid_side = GUICHET_SIDE if on else 1.0


## Panneau à texte dans la salle : placé au bon endroit sans être retourné.
func _hall_sign(m: Material, w: float, h: float, x: float, y: float, z: float, ry: float) -> void:
	var saved := _mirror
	_mirror = Transform3D.IDENTITY
	plane(m, w, h, x * GUICHET_SIDE, y, z, ry * GUICHET_SIDE)
	_mirror = saved




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
	# contremarches en haut des volées (le sol au-dessus n'a pas d'épaisseur)
	plane(M.pierreS, 2 * HX, 0.3, 0, -0.15, Z0, 0, 2, 0.3)
	plane(M.pierreS, 2 * HX, 0.3, 0, -3.39, 14.0, 0, 2, 0.3)
	# premier escalier
	for i in 12:
		var top := -(i + 1) * 0.27
		box(M.pierreS, 2 * HX, 3.8 + top, 0.5, 0, (top - 3.8) / 2, Z0 + i * 0.5 + 0.25, 2, 1)
	# murs carrelés de la trémie et du couloir
	# murs de l'escalier, puis du couloir après la salle des billets (z 3 à 11,2)
	for sx in [-1, 1]:
		plane(M.carrelage, Z1 - Z0, 3.6, sx * HX, -1.8, (Z0 + Z1) / 2, PI / 2, (Z1 - Z0) * 1.3, 5)
		plane(M.carrelage, 14 - HALL_Z1, 3.6, sx * HX, -1.8, (HALL_Z1 + 14) / 2, PI / 2, (14 - HALL_Z1) * 1.3, 5)
	plane(M.carrelage, 2 * HX, 0.95, 0, -0.47, Z1, 0, 3, 1.2)
	plane(M.globes, 2.1, 0.5, 0, -0.62, Z1 - 0.02, 0)
	rect(M.carrelage, -HX, HALL_Z1, HX, 14, -0.92, 0.8, PI / 2)
	rect(M.sol, -HX, HALL_Z1, HX, 14, -3.24, 2.4)
	# second escalier, vers le quai
	for i in 12:
		var top := -3.24 - (i + 1) * 0.27
		box(M.pierreS, 2 * HX, top + 6.7, 0.5, 0, (top - 6.7) / 2, 14 + i * 0.5 + 0.25, 2, 1)
	plane(M.carrelage, ZA - 14, 5.9, -HX, -3.85, (14 + ZA) / 2, PI / 2, 8, 7)
	plane(M.carrelage, ZA - 14, 5.9, HX, -3.85, (14 + ZA) / 2, PI / 2, 8, 7)
	plane(M.carrelage, 2 * HX, Vector2(6, 3.06).length(), 0, (-0.92 - 3.98) / 2, 17, 0, 3, 8, -PI / 2 + atan2(3.06, 6))
	plane(M.sortieQ, 1.1, 0.28, 0, -1.25, 14.05, 0)
	box(M.fonteDark, 1.12, 0.3, 0.01, 0, -1.25, 14.035)   # dos du panneau, vu du couloir
	plane(M.plaque, 1.4, 0.35, 1.96, -1.5, Z1 + 0.02, 0)   # au mur de la salle, à l'arrivée de l'escalier


# --- Quai, voûte, voies et tunnels --------------------------------------------

func _build_station() -> void:
	# sols des quais, percés par les escaliers du passage
	_build_platform_floors(_underpass())
	_build_tracks()

	# piédroits (avec l'ouverture de l'escalier) et plinthe brune
	var wl := HALF - HX
	var wc := (HALF + HX) / 2
	for sx in [-1, 1]:
		plane(M.carreau, wl, WT - PY, sx * wc, (PY + WT) / 2, ZA, 0, wl / TW, (WT - PY) / TH)
	plane(M.carreau, L, WT - PY, 0, (PY + WT) / 2, ZB, 0, L / TW, (WT - PY) / TH)
	# plinthes, interrompues au-dessus des escaliers du passage
	for run in [[X0, -HX, ZA + 0.01], [HX, PX0, ZA + 0.01], [PX1, X1, ZA + 0.01], [X0, PX0, ZB - 0.01], [PX1, X1, ZB - 0.01]]:
		var length: float = run[1] - run[0]
		plane(M.plinthe, length, 0.2, (run[0] + run[1]) / 2, PY + 0.1, run[2], 0, length / 0.6, 1)

	_build_shell()

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
		plane(M.plan_reseau, 1.38, 1.38, x, -5.05, ZA + 0.06, 0)
	for r in [PI / 2, -PI / 2]:
		var o := 0.02 if r > 0 else -0.02
		plane(M.sortieQ, 1.2, 0.3, o, -3.3, 22.2, r)
		plane(M.alarme, 1.0, 0.25, -9 + o, -3.85, 20.6, r)
		plane(M.alarme, 1.0, 0.25, 12 + o, -3.85, 20.6, r)
	box(M.inox, 0.03, 0.9, 0.03, 0, -2.8, 22.2)
	box(M.inox, 0.05, 0.05, 0.75, -9, -3.7, 20.35)
	box(M.inox, 0.05, 0.05, 0.75, 12, -3.7, 20.35)
	plane(M.repere, 0.45, 0.45, -HALF + 1.4, -3.4, 25.5, PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, -HALF + 1.4, -2.6, 25.5)
	plane(M.repere, 0.45, 0.45, HALF - 1.4, -3.4, 28.5, -PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, HALF - 1.4, -2.6, 28.5)

	_build_screens([5, -17])
	_build_seats([[-18, 20.45, 1], [-3, 20.45, 1], [18, 20.45, 1], [-12, 33.55, -1], [6, 33.55, -1], [21, 33.55, -1]])




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
		_tree(TREES[i][0], TREES[i][1], i)
	add(PsxGeo.cylinder(0.62, 0.62, 3.2, 8), M.morris, MORRIS + Vector3(0, 1.6, 0))
	add(PsxGeo.sphere(0.75, 8, 4, 0, TAU, 0, PI / 2), M.morris, MORRIS + Vector3(0, 3.2, 0), Vector3.ZERO, Vector3(1, 1.3, 1))


# --- Passage sous les voies, vers le quai direction Nation --------------------

## Le passage de Monceau : habillage d'après des photos de couloirs et d'escaliers du métro
## prises comme modèles (frise brune, plinthe verte, garde-corps noir, voûte blanche).
var UNDERPASS := {}


func _underpass() -> Dictionary:
	if UNDERPASS.is_empty():
		UNDERPASS = {"x0": PX0, "x1": PX1, "x2": PX2, "w": PW, "floor": PFLOOR, "ceil": PCEIL,
			"rail": M.gardecorps, "rail_h": 1.0, "rail_tile": 1.0, "top_rail": M.fonte, "curb": null, "risers": null,
			"frieze": M.frise, "plinth": M.plinthe_verte}
	return UNDERPASS


func _build_passage() -> void:
	_build_underpass(_underpass())
	var to_nation := _sign([["ligne", "Nation"]])
	var to_exit := _sign([["ligne", "Pte Dauphine"], ["sortie", "Sortie"]])
	for well in [[ZA, 1.0, to_nation], [ZB, -1.0, to_exit]]:
		var zc: float = well[0] + well[1] * PW / 2   # axe de l'escalier
		# panneau suspendu au-dessus du haut de l'escalier, lisible des deux côtés
		var sign_m: Material = well[2]
		var sign_h := 0.25 * (2 if sign_m == to_exit else 1)
		for r in [PI / 2, -PI / 2]:
			plane(sign_m, 1.5, sign_h * 2, PX0 - 0.4 + (0.03 if r > 0 else -0.03), -4.3, zc, r)
		box(M.fonteDark, 0.04, sign_h * 2 + 0.02, 1.52, PX0 - 0.4, -4.3, zc)
		box(M.inox, 0.03, 1.4 - sign_h + 0.25, 0.03, PX0 - 0.4, -3.35 - (sign_h - 0.25) / 2, zc)
	# au pied de chaque escalier, un panneau sur le mur d'en face
	plane(to_nation, 1.5, 0.5, PX2 - 0.02, -9.1, ZA + PW / 2 + 1.0, -PI / 2)
	plane(to_exit, 1.5, 1.0, PX2 - 0.02, -9.35, ZB - PW / 2 - 1.2, -PI / 2)

	# plans de ligne à l'accès de chaque quai, examinables : direction Porte Dauphine dans le
	# couloir avant l'escalier du quai, direction Nation dans le passage, au pied de son escalier
	for p in [["Porte Dauphine", Vector3(-HX + 0.02, -1.78, 12.6), PI / 2], ["Nation", Vector3(PX1 + 0.02, -9.4, 30.4), PI / 2]]:
		_line_plan("Monceau", p[0], p[1], p[2])


# --- Salle des billets ---------------------------------------------------------
# D'après la photo de la salle des billets de Monceau (Chabe01, Wikimedia Commons,
# CC BY-SA 4.0, voir CREDITS.md) : un élargissement du couloir au bas de l'escalier de la rue,
# voûtains blancs entre des poutres rivetées, carrelage blanc à frise et plinthe vertes.
# À gauche, une porte de service inox sous un bandeau ⓘ, le plan du quartier, un défibrillateur ;
# à droite, le guichet « Services », la porte de la loge, l'automate « Tickets » ; au fond, les
# portes de sortie et les portillons. La loge de l'agent est derrière le guichet.

const CY := -3.24              # sol du couloir
const CC := -0.92              # plafond du couloir
const HALL_W := 2.8            # demi-largeur de la salle
const GUICHET_SIDE := -1.0     # le guichet est en -x : à droite en allant vers les quais
const LOGE_DOOR_OPEN := -100.0 * GUICHET_SIDE   # angle de la porte entrouverte, en degrés
const HALL_Z0 := Z1            # bas de l'escalier de la rue
const HALL_Z1 := 11.2          # la salle se resserre en couloir
const HALL_TOP := -0.55        # clé des voûtains
const VAULT_SPRING := -1.05
const GATES_Z := 9.9           # ligne des portillons
const LOGE_X := 5.4            # fond de la loge
const LOGE_Z0 := 3.6
const LOGE_Z1 := 7.9
const WINDOW := Vector4(4.0, 6.3, -2.19, -1.55)   # vitre du guichet : z0, z1, y0, y1
const BAND_Y := -1.4           # bandeaux « Services » et « Tickets » : sous les poutres, sur la vitre
const DOOR := Vector2(6.9, 7.7)                    # porte de la loge : z0, z1
const SYLVAIN_GUICHET := Vector3(3.55 * GUICHET_SIDE, CY, 5.15)
const SYLVAIN_GUICHET_YAW := PI / 2 * GUICHET_SIDE
const SYLVAIN_QUAI := Vector3(-6.0, PY, 21.2)


func _build_ticket_hall() -> void:
	_set_hall_mirror(true)
	var white := _mat("blanc", 0xe6e5e0)
	var dark := _mat("blanc", 0x2e2f31)
	var steel := _mat("blanc", 0x8a8d90)
	var vault := _mat("blanc", 0xb4b2ab)
	var beam := _mat("poutre")
	var services := _sign_from_texture(Panneaux.band(self, "i", "Services"))
	var tickets := _sign_from_texture(Panneaux.band(self, "T", "Tickets"))
	var info := _sign_from_texture(Panneaux.band(self, "i", ""))
	for m in [services, tickets, info]:
		m.set_shader_parameter("emission", Vector3(0.8, 0.8, 0.8))
	var mid := (HALL_Z0 + HALL_Z1) / 2

	# sol, murs carrelés, voûtains entre poutres rivetées
	rect(_mat("sol_goudron", 0xc8c8c8), -HALL_W, HALL_Z0, HALL_W, HALL_Z1, CY, 2.4)
	_tiled_wall(-HALL_W, HALL_Z0, HALL_Z1, 1.0)
	_tiled_wall(HALL_W, HALL_Z0, LOGE_Z0, -1.0)
	_tiled_wall(HALL_W, LOGE_Z1, HALL_Z1, -1.0)
	for z_wall in [[HALL_Z0, 0.0], [HALL_Z1, PI]]:
		for sx in [-1, 1]:
			var w := HALL_W - HX
			plane(M.carreau_salle, w, HALL_TOP - CY, sx * (HX + w / 2), (CY + HALL_TOP) / 2, z_wall[0], z_wall[1], w / TW, (HALL_TOP - CY) / TH)
		if z_wall[0] == HALL_Z1:   # au-dessus de l'entrée du couloir
			plane(M.carreau, 2 * HX, HALL_TOP - CC, 0, (CC + HALL_TOP) / 2, z_wall[0], z_wall[1], 2 * HX / TW, 1)
	var beams := [HALL_Z0 + 0.1, HALL_Z0 + 2.75, HALL_Z0 + 5.4, HALL_Z1 - 0.1]
	for z in beams:
		box(beam, 2 * HALL_W, 0.24, 0.22, 0, VAULT_SPRING - 0.08, z, 2 * HALL_W / 1.2, 1)
	box(beam, 0.22, 0.2, HALL_Z1 - HALL_Z0, 0, VAULT_SPRING - 0.06, mid, 1, (HALL_Z1 - HALL_Z0) / 1.2)
	for i in beams.size() - 1:
		_vaulted_bay(vault, beams[i], beams[i + 1])
		box(M.neon, 0.25, 0.06, 0.25, -1.4, VAULT_SPRING - 0.22, (beams[i] + beams[i + 1]) / 2)
		box(M.neon, 0.25, 0.06, 0.25, 1.4, VAULT_SPRING - 0.22, (beams[i] + beams[i + 1]) / 2)

	# mur de gauche : porte de service inox, plan du quartier, défibrillateur
	var x := -HALL_W
	box(steel, 0.05, 2.1, 0.9, x + 0.03, CY + 1.05, 4.2)
	_hall_sign(info, 1.0, 0.24, x + 0.07, CY + 2.3, 4.2, PI / 2)
	box(M.inox, 0.08, 1.45, 1.05, x + 0.05, CY + 1.3, 6.1)
	_hall_sign(M.plan, 0.9, 1.3, x + 0.1, CY + 1.3, 6.1, PI / 2)
	box(white, 0.14, 0.4, 0.32, x + 0.08, CY + 1.25, 3.35)
	box(_mat("blanc", 0x2fa05a), 0.02, 0.18, 0.32, x + 0.03, CY + 1.62, 3.35)

	# mur de droite : guichet « Services », porte de la loge, automate « Tickets »
	x = HALL_W + 0.06
	_wall_box(white, x, LOGE_Z0, WINDOW.x, CY, HALL_TOP)
	_wall_box(white, x, WINDOW.x, WINDOW.y, WINDOW.w, HALL_TOP)
	_wall_box(dark, x, WINDOW.x, WINDOW.y, CY, WINDOW.z)
	_wall_box(white, x, WINDOW.y, DOOR.x, CY, HALL_TOP)
	_wall_box(white, x, DOOR.x, DOOR.y, -1.2, HALL_TOP)
	_wall_box(white, x, DOOR.y, LOGE_Z1, CY, HALL_TOP)
	box(dark, 0.04, 1.0, WINDOW.x - LOGE_Z0, HALL_W - 0.01, CY + 0.5, (LOGE_Z0 + WINDOW.x) / 2)
	box(dark, 0.04, 1.0, DOOR.x - WINDOW.y, HALL_W - 0.01, CY + 0.5, (WINDOW.y + DOOR.x) / 2)
	box(white, 0.3, 0.05, WINDOW.y - WINDOW.x, HALL_W - 0.12, WINDOW.z, (WINDOW.x + WINDOW.y) / 2)   # tablette
	box(M.inox, 0.03, 0.03, WINDOW.y - WINDOW.x, HALL_W, WINDOW.w - 0.02, (WINDOW.x + WINDOW.y) / 2)
	_hall_sign(services, DOOR.x - LOGE_Z0 - 0.2, 0.24, HALL_W - 0.04, BAND_Y, (LOGE_Z0 + DOOR.x) / 2, -PI / 2)
	box(_mat("blanc", 0xd8d8d4), 0.45, 1.7, 0.7, HALL_W - 0.24, CY + 0.85, 8.6)   # automate « Tickets »
	box(M.noir, 0.02, 0.3, 0.4, HALL_W - 0.47, CY + 1.25, 8.6)
	box(_mat("blanc", 0x7a3aa8), 0.02, 0.35, 0.3, HALL_W - 0.47, CY + 0.6, 8.6)
	_hall_sign(tickets, 1.1, 0.24, HALL_W - 0.04, BAND_Y, 8.6, -PI / 2)

	# la loge : sol, plafond, murs, comptoir, bureau, cahier, casier
	var h := CC - CY
	rect(M.sol, HALL_W, LOGE_Z0, LOGE_X, LOGE_Z1, CY, 2.4)
	rect(white, HALL_W, LOGE_Z0, LOGE_X, LOGE_Z1, CC, 2.0, PI / 2)
	plane(white, LOGE_Z1 - LOGE_Z0, h, LOGE_X, (CY + CC) / 2, (LOGE_Z0 + LOGE_Z1) / 2, -PI / 2)
	plane(white, LOGE_X - HALL_W, h, (HALL_W + LOGE_X) / 2, (CY + CC) / 2, LOGE_Z1, PI)
	plane(white, LOGE_X - HALL_W, h, (HALL_W + LOGE_X) / 2, (CY + CC) / 2, LOGE_Z0, 0)
	box(M.neon, 1.0, 0.05, 0.15, (HALL_W + LOGE_X) / 2, CC - 0.03, 5.6)
	box(dark, 0.55, 0.05, 2.0, HALL_W + 0.4, CY + 0.75, 5.15)            # comptoir derrière la vitre
	box(dark, 0.5, 0.05, 1.4, LOGE_X - 0.3, CY + 0.85, 4.5)             # bureau du fond
	box(dark, 0.05, 0.85, 1.4, LOGE_X - 0.3, CY + 0.42, 4.5)
	box(M.noir, 0.3, 0.25, 0.04, LOGE_X - 0.25, CY + 1.05, 4.1)         # écran de surveillance
	box(_mat("blanc", 0x5a6a7a), 0.45, 1.8, 0.5, LOGE_X - 0.25, CY + 0.9, 7.35)   # casier
	box(M.inox, 0.02, 0.04, 0.1, LOGE_X - 0.48, CY + 1.0, 7.2)
	var cahier := Examinable.new()
	cahier.title = "Cahier de service"
	cahier.description = "Ouvert à la page de mardi. « 23 h 08 : intervention maintenance, voie 1, porte de service. » Rien de tel dans le planning affiché au mur."
	cahier.evidence_id = "cahier"
	cahier.photo_range = 1.8
	cahier.position = Vector3((LOGE_X - 0.3) * GUICHET_SIDE, CY + 0.88, 4.7)
	_examinable_shape(cahier, Vector3(0.35, 0.1, 0.4))
	add_child(cahier)
	box(white, 0.22, 0.015, 0.3, LOGE_X - 0.3, CY + 0.88, 4.7)
	box(_mat("blanc", 0x2a3a6a), 0.23, 0.01, 0.31, LOGE_X - 0.3, CY + 0.87, 4.7)
	var casier := Examinable.new()
	casier.title = "Casier de Sylvain"
	casier.locked_description = "Un casier métallique fermé par un cadenas à code. Sans raison sérieuse, pas question de le forcer."
	casier.description = "Vous forcez le cadenas. Derrière une veste pliée, une enveloppe blanche : six billets de 50 € neufs."
	casier.examine_condition = "solved:faux_agent"
	casier.examine_evidence = "billet"
	casier.position = Vector3((LOGE_X - 0.25) * GUICHET_SIDE, CY + 0.9, 7.35)
	_examinable_shape(casier, Vector3(0.5, 1.8, 0.55))
	add_child(casier)

	# porte de la loge, sur charnière (ouverte pendant les rondes de Sylvain)
	loge_door = Node3D.new()
	loge_door.position = Vector3((HALL_W + 0.06) * GUICHET_SIDE, CY, DOOR.y)
	add_child(loge_door)
	var leaf := PsxBuilder.new()
	leaf.add(PsxGeo.box(0.05, 2.02, DOOR.y - DOOR.x), dark, PsxGeo.xf(Vector3(0, 1.01, -(DOOR.y - DOOR.x) / 2)))
	leaf.add(PsxGeo.box(0.07, 0.04, 0.12), M.inox, PsxGeo.xf(Vector3(0, 1.0, -(DOOR.y - DOOR.x) + 0.1)))
	leaf.build(loge_door)
	var leaf_body := StaticBody3D.new()
	var leaf_shape := CollisionShape3D.new()
	leaf_shape.shape = BoxShape3D.new()
	leaf_shape.shape.size = Vector3(0.05, 2.02, DOOR.y - DOOR.x)
	leaf_shape.position = Vector3(0, 1.01, -(DOOR.y - DOOR.x) / 2)
	leaf_body.add_child(leaf_shape)
	loge_door.add_child(leaf_body)

	_build_gate_row(-HALL_W, HALL_W, GATES_Z, CY)
	_set_hall_mirror(false)


## Mur carrelé de la salle, dans le plan x, avec frise et plinthe vertes.
func _tiled_wall(x: float, z0: float, z1: float, facing: float) -> void:
	var length := z1 - z0
	var ry := PI / 2 if facing > 0 else -PI / 2
	var mid := (z0 + z1) / 2
	plane(M.carreau_salle, length, HALL_TOP - CY, x, (CY + HALL_TOP) / 2, mid, ry, length / TW, (HALL_TOP - CY) / TH)
	plane(M.frise_verte, length, 0.14, x + facing * 0.01, VAULT_SPRING - 0.2, mid, ry, length / 0.6, 1)
	plane(M.plinthe_verte, length, 0.22, x + facing * 0.01, CY + 0.11, mid, ry, length / 0.6, 1)


## Voûtain entre deux poutres : berceau surbaissé tendu d'un mur à l'autre.
func _vaulted_bay(m: Material, z0: float, z1: float) -> void:
	var g := PsxGeo.empty()
	var n_arc := 6
	var n_len := 4
	var cz := (z0 + z1) / 2
	var half := (z1 - z0) / 2
	for i in n_arc + 1:
		var t := PI * i / n_arc
		var z := cz + half * cos(t)
		var y := VAULT_SPRING + (HALL_TOP - VAULT_SPRING) * sin(t)
		for j in n_len + 1:
			var xx := -HALL_W + 2 * HALL_W * j / n_len
			g.p.append(Vector3(xx, y, z))
			g.n.append(Vector3(0, -sin(t), -cos(t)))
			g.uv.append(Vector2(xx / 2.0, float(i) / n_arc))
	for i in n_arc:
		for j in n_len:
			var a := i * (n_len + 1) + j
			var b := a + n_len + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, m, Vector3.ZERO)


## Mur vertical (boîte) dans le plan x, de z0 à z1 et de y0 à y1.
func _wall_box(m: Material, x: float, z0: float, z1: float, y0: float, y1: float) -> void:
	box(m, 0.12, y1 - y0, z1 - z0, x, (y0 + y1) / 2, (z0 + z1) / 2, (z1 - z0) / 2, (y1 - y0) / 2)


# --- Kiosque à journaux et personnages du chapitre 1 ---------------------------

const KIOSK := Vector3(-1.5, 0, 22.6)


func _build_kiosk() -> void:
	box(M.morris, 2.0, 2.2, 1.4, KIOSK.x, 1.1, KIOSK.z)
	box(M.zinc, 2.4, 0.15, 1.8, KIOSK.x, 2.28, KIOSK.z)
	box(M.fonte, 2.5, 0.25, 1.9, KIOSK.x, 2.47, KIOSK.z)
	box(M.lanterne, 1.6, 0.18, 0.02, KIOSK.x, 1.95, KIOSK.z - 0.71)      # bandeau éclairé
	# présentoir de magazines sur la façade côté boulevard
	var colors := [0xd8452f, 0xe8c53a, 0x3a6fd8, 0xf2f2f2, 0x2fa05a, 0xd06aa8]
	for row in 3:
		for col in 6:
			var m := _mat("blanc", colors[(row * 2 + col) % colors.size()])
			box(m, 0.22, 0.3, 0.02, KIOSK.x - 0.65 + col * 0.26, 0.75 + row * 0.36, KIOSK.z - 0.71)
	_solid(Vector3(2.0, 2.2, 1.4), KIOSK + Vector3(0, 1.1, 0))
	# rideau de fer, baissé à la fermeture (23 h 20)
	kiosk_shutter = Node3D.new()
	add_child(kiosk_shutter)
	var shutter := PsxBuilder.new()
	shutter.add(PsxGeo.box(1.7, 1.5, 0.03), _mat("blanc", 0x5a5e58), PsxGeo.xf(Vector3(KIOSK.x, 1.15, KIOSK.z - 0.73)))
	shutter.build(kiosk_shutter)
	kiosk_shutter.hide()


## Les personnages du chapitre 1, à leur poste (le chapitre 6 réglera leurs horaires).
func _place_people() -> void:
	var cast := [
		["sylvain", "Sylvain, agent de station", {"coat": Color("#1f2a4a"), "pants": Color("#1b1f2b"), "skin": Color("#9c6f52"), "hair": Color("#1e1a18")},
			false, SYLVAIN_GUICHET, SYLVAIN_GUICHET_YAW],
		["jo", "Un homme endormi", {"coat": Color("#4d463c"), "pants": Color("#3a3836"), "skin": Color("#b58a6c"), "hair": Color("#2a2420"), "hat": Color("#6a2a2a")},
			true, Vector3(0.85, -3.24, 13.3), PI / 2],
		["roche", "Mme Roche, kiosquière", {"coat": Color("#6b4a36"), "pants": Color("#3a3230"), "skin": Color("#d8b49a"), "hair": Color("#b5b0aa")},
			false, KIOSK + Vector3(1.4, 0, -0.6), 0.0],
		["gardien", "Le gardien du parc", {"coat": Color("#2f4a36"), "pants": Color("#24262a"), "skin": Color("#c49678"), "hair": Color("#3a3028"), "hat": Color("#24362a")},
			false, Vector3(ROT.x + 1.3, 0, 13.6), -PI / 2],   # devant la grille du parc
	]
	for p in cast:
		var person := Personnage.new(p[0], p[1], p[2], p[3])
		person.name = p[0].capitalize()
		person.position = p[4]
		person.rotation.y = p[5]
		add_child(person)
		people[p[0]] = person


# --- Indices du chapitre 1 (provisoires) --------------------------------------

func _build_clues() -> void:
	# Porte de service dans le mur de tête, au bout du quai.
	var door := Examinable.new()
	door.title = "Porte de service"
	door.description = "Porte métallique verrouillée. Autour de la serrure, des rayures fraîches dans la peinture."
	door.evidence_id = "serrure"
	door.position = Vector3(-HALF + 0.03, PY + 1.05, 21.4)
	_examinable_shape(door, Vector3(0.1, 2.1, 0.9))
	add_child(door)
	box(M.service, 0.06, 2.1, 0.9, -HALF + 0.03, PY + 1.05, 21.4)

	# Badge glissé sous le dernier siège du quai.
	var badge := Examinable.new()
	badge.title = "Badge RATP"
	badge.description = "Une carte d'agent glissée sous le siège. Photo d'identité : Karim Benali."
	badge.evidence_id = "badge"
	badge.position = Vector3(18.95, PY + 0.01, 20.75)
	_examinable_shape(badge, Vector3(0.45, 0.16, 0.45))
	add_child(badge)
	box(M.neon, 0.09, 0.008, 0.055, 18.95, PY + 0.005, 20.75)





## Construit toutes les collisions ; renvoie les garde-fous des deux quais (voie 1, voie 2).
func _build_colliders() -> Array[CollisionShape3D]:
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
	for sx in [-1, 1]:   # murs de l'escalier de la rue, puis du couloir après la salle
		_solid(Vector3(0.2, 3.6, Z1 - Z0), Vector3(sx * (HX + 0.1), -1.8, (Z0 + Z1) / 2))
		_solid(Vector3(0.2, 3.6, 14 - HALL_Z1), Vector3(sx * (HX + 0.1), -1.8, (HALL_Z1 + 14) / 2))
		_solid(Vector3(0.2, 5.9, 6.3), Vector3(sx * (HX + 0.1), -3.85, 17.15))

	# Les deux quais et le passage ; le mur du quai A est percé par l'escalier du couloir.
	var barriers := _platform_colliders(_underpass(), [[[-HX, HX]], []])

	# Salle des billets et loge (la vitre du guichet est sur la couche 2 : elle arrête le
	# détective, pas son regard ni ses photos).
	_set_hall_mirror(true)
	_solid(Vector3(LOGE_X + HALL_W, 0.2, HALL_Z1 - HALL_Z0), Vector3((LOGE_X - HALL_W) / 2, CY - 0.1, (HALL_Z0 + HALL_Z1) / 2))
	_solid(Vector3(0.2, 2.4, HALL_Z1 - HALL_Z0), Vector3(-HALL_W - 0.1, -2.1, (HALL_Z0 + HALL_Z1) / 2))
	_solid(Vector3(0.2, 2.4, LOGE_Z0 - HALL_Z0), Vector3(HALL_W + 0.1, -2.1, (HALL_Z0 + LOGE_Z0) / 2))
	_solid(Vector3(0.2, 2.4, HALL_Z1 - LOGE_Z1), Vector3(HALL_W + 0.1, -2.1, (LOGE_Z1 + HALL_Z1) / 2))
	for sx in [-1, 1]:
		_solid(Vector3(HALL_W - HX, 2.4, 0.2), Vector3(sx * (HALL_W + HX) / 2, -2.1, HALL_Z0 - 0.1))
		_solid(Vector3(HALL_W - HX, 2.4, 0.2), Vector3(sx * (HALL_W + HX) / 2, -2.1, HALL_Z1 + 0.1))
	_solid(Vector3(0.2, 2.4, LOGE_Z1 - LOGE_Z0), Vector3(LOGE_X + 0.1, -2.1, (LOGE_Z0 + LOGE_Z1) / 2))
	for z in [LOGE_Z0 - 0.1, LOGE_Z1 + 0.1]:
		_solid(Vector3(LOGE_X - HALL_W, 2.4, 0.2), Vector3((HALL_W + LOGE_X) / 2, -2.1, z))
	for seg in [[LOGE_Z0, WINDOW.x], [WINDOW.y, DOOR.x]]:
		_solid(Vector3(0.12, 2.4, seg[1] - seg[0]), Vector3(HALL_W + 0.06, -2.1, (seg[0] + seg[1]) / 2))
	_solid(Vector3(0.12, WINDOW.z - CY, WINDOW.y - WINDOW.x), Vector3(HALL_W + 0.06, (CY + WINDOW.z) / 2, (WINDOW.x + WINDOW.y) / 2))
	var glass := StaticBody3D.new()
	glass.collision_layer = 2
	var pane := CollisionShape3D.new()
	pane.shape = BoxShape3D.new()
	pane.shape.size = Vector3(0.05, WINDOW.w - WINDOW.z, WINDOW.y - WINDOW.x)
	pane.position = Vector3((HALL_W + 0.06) * GUICHET_SIDE, (WINDOW.z + WINDOW.w) / 2, (WINDOW.x + WINDOW.y) / 2)
	glass.add_child(pane)
	add_child(glass)
	_solid(Vector3(0.55, 0.8, 2.0), Vector3(HALL_W + 0.4, CY + 0.4, 5.15))
	_solid(Vector3(0.5, 0.9, 1.4), Vector3(LOGE_X - 0.3, CY + 0.45, 4.5))
	_solid(Vector3(0.45, 1.8, 0.5), Vector3(LOGE_X - 0.25, CY + 0.9, 7.35))
	_solid(Vector3(0.45, 1.7, 0.7), Vector3(HALL_W - 0.24, CY + 0.85, 8.6))
	_solid(Vector3(0.14, 0.4, 1.0), Vector3(-HALL_W + 0.07, CY + 1.3, 6.1))
	_set_hall_mirror(false)

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
