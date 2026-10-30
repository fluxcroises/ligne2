extends Station
## Station Pigalle et ses abords, d'après des photos prises comme modèles (voir CREDITS.md) :
## quais de la ligne 2 sous une voûte striée de néons bleus, grande rampe d'éclairage
## suspendue, affiches et sièges orange ; un long couloir carrelé à liseré vert ; une salle
## des billets rénovée ; une bouche Guimard sur le terre-plein du boulevard de Clichy. En
## surface : le boulevard, la fontaine de la place Pigalle, les néons, et la rue Frochot où
## l'antiquaire Marchetti a sa boutique (inventée).
## Même repère que Monceau et Villiers (voir Station).

# Couloir de sortie, perpendiculaire au quai A, puis escalier vers la salle des billets
const DOOR_X := 10.0          # axe du couloir et des escaliers
const CW := 1.2               # demi-largeur du couloir
const COR_Z0 := 6.0           # bout du couloir, pied de l'escalier
const COR_TOP := WT           # plafond du couloir (au niveau de la naissance de la voûte)
const CY := -3.24             # sol de la salle des billets
const HALL_C := -0.7
const HALL_X0 := 4.0
const HALL_X1 := 16.0
const HALL_Z0 := -8.0         # côté rue
const HALL_Z1 := 0.0          # côté quais
const GATE_Z := -3.0
const HX := 1.12              # demi-largeur de l'escalier de la rue
const EXIT_Z := -14.0         # haut de l'escalier, sur le terre-plein (bouche Guimard)

# Surface
const W0 := Vector2(-60.0, -48.0)
const W1 := Vector2(70.0, 44.0)
const MEDIAN := Vector2(-20.0, -2.0)       # terre-plein central du boulevard (z)
const FROCHOT := Vector2(28.0, 34.0)       # rue Frochot (x), vers le sud
const SHOP := Vector3(28.0, 0, 30.0)       # façade d'Antiquités Marchetti (x de la façade, z du milieu)
const BAR := Vector3(15.0, 0, 10.0)        # le Chat Rouge, sur le boulevard
const FOUNTAIN := Vector3(40.0, 0, -11.0)  # fontaine de la place Pigalle
const CANDELABRAS := [-10.0, 24.0, 54.0]   # x des grands candélabres du terre-plein
const LAMPS := [Vector2(-40.0, 7.2), Vector2(0.0, 7.2), Vector2(22.0, 7.2), Vector2(33.4, 24.0), Vector2(-30.0, -31.0), Vector2(40.0, -31.0)]

var UNDERPASS := {}


func _underpass() -> Dictionary:
	if UNDERPASS.is_empty():
		UNDERPASS = {"x0": -12.0, "x1": -4.5, "x2": -2.1, "w": 1.6, "floor": -10.5, "ceil": -8.2,
			"rail": M.gardecorps, "rail_h": 1.0, "rail_tile": 1.0, "top_rail": M.fonte, "curb": null, "risers": null,
			"frieze": M.frise_verte, "plinth": M.plinthe_verte}
	return UNDERPASS


func _ready() -> void:
	_under_lamps = [Vector3(DOOR_X, PY + 2.0, 15.0), Vector3(DOOR_X, PY + 2.0, 9.0)]
	for l in LAMPS:
		_lanterns.append(Vector3(l.x, 4.4, l.y))
	for x in CANDELABRAS:
		for dx in [-0.7, 0.7]:
			_lanterns.append(Vector3(x + dx, 6.2, (MEDIAN.x + MEDIAN.y) / 2))
	_begin(3)
	M.nom = _mat("nom_pigalle")
	var barriers := _platform_colliders(_underpass(), [[[DOOR_X - CW, DOOR_X + CW]], []])
	_setup_trafic([[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], barriers)
	_build_platforms()
	_build_underpass(_underpass())
	_build_corridor()
	_build_hall()
	_build_street()
	_place_people()
	var chapter := preload("res://scripts/chapitre_3_jeu.gd").new()
	chapter.name = "Chapitre3"
	add_child(chapter)
	_builder.build(self)
	_set_platform_zone()
	_global("zone2_color", Vector3(0.9, 0.9, 0.88))
	_global("zone2_min", Vector3(DOOR_X - CW - 0.1, PY - 0.5, HALL_Z1 - 0.05))
	_global("zone2_max", Vector3(DOOR_X + CW + 0.1, HALL_C + 0.1, ZA + 0.05))
	_global("zone3_color", Vector3(0.78, 0.78, 0.76))
	_global("zone3_min", Vector3(HALL_X0 - 0.1, CY - 0.1, HALL_Z0 - 0.1))
	_global("zone3_max", Vector3(HALL_X1 + 0.1, HALL_C + 0.1, HALL_Z1 + 0.1))
	set_night(night)


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame · prochaine station : %s" % next_station("Pigalle", train.destination)
		return "Rame ligne 2 · direction %s" % train.destination
	if pos.y > -0.6:
		if pos.x > FROCHOT.x and pos.x < FROCHOT.y and pos.z > MEDIAN.y + 8.0:
			return "Rue Frochot"
		if pos.x > 30.0 and pos.z < MEDIAN.y + 2.0:
			return "Place Pigalle"
		return "Boulevard de Clichy"
	if pos.z < HALL_Z1 and pos.y < HALL_C:
		return "Salle des billets · Pigalle" if pos.z > HALL_Z0 and absf(pos.y - CY) < 0.3 else "Escalier · Pigalle"
	if pos.z < ZA and pos.z > HALL_Z1:
		return "Couloir · Pigalle" if pos.z > COR_Z0 else "Escalier · Pigalle"
	var u := _underpass()
	if pos.y < u.floor + 0.3:
		return "Passage sous les voies · Pigalle"
	if pos.y < PY - 0.2:
		return "Escalier · Pigalle"
	return "Quai · direction Nation" if pos.z > CZ else "Quai · direction Porte Dauphine"


# --- Quais ---------------------------------------------------------------------

func _build_platforms() -> void:
	var u := _underpass()
	_build_platform_floors(u)
	_build_tracks()
	for run in [[X0, DOOR_X - CW], [DOOR_X + CW, X1]]:
		var length: float = run[1] - run[0]
		plane(M.carreau, length, WT - PY, (run[0] + run[1]) / 2, (PY + WT) / 2, ZA, 0, length / TW, (WT - PY) / TH)
	plane(M.carreau, L, WT - PY, 0, (PY + WT) / 2, ZB, 0, L / TW, (WT - PY) / TH)
	for run in [[X0, u.x0, ZA + 0.01], [u.x1, DOOR_X - CW, ZA + 0.01], [DOOR_X + CW, X1, ZA + 0.01], [X0, u.x0, ZB - 0.01], [u.x1, X1, ZB - 0.01]]:
		var length: float = run[1] - run[0]
		plane(M.plinthe, length, 0.2, (run[0] + run[1]) / 2, PY + 0.1, run[2], 0, length / 0.6, 1)
	_build_shell(false)
	# la grande rampe d'éclairage suspendue au-dessus de chaque quai, et les néons bleus de la voûte
	var dark := _mat("blanc", 0x2a2c30)
	var blue := _mat("blanc", 0x3a58ff, false, true)
	for z in [22.4, 31.6]:
		box(dark, L - 2, 0.06, 0.7, 0, -2.0, z)
		box(M.neon, L - 2, 0.04, 0.22, 0, -2.05, z)
		for x in range(-34, 36, 8):
			box(M.inox, 0.03, 1.4, 0.03, x, -1.3, z)
	for z in [24.0, 30.0]:
		box(blue, L - 4, 0.08, 0.5, 0, -0.95, z)

	# plaques, affiches, consignes
	for x in [-26, 2, 18, 30]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZA + 0.03, 0)
	for x in [-28, -16, 4, 20]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZB - 0.03, PI)
	var k := 0
	for p in [[-20.0, ZA, 0.0], [1.0 + 9.0, ZB, PI], [24.0, ZA, 0.0], [-22.0, ZB, PI], [13.0 + 13.0, ZB, PI], [-31.0, ZA, 0.0]]:
		var poster := _mat("affiche_%d" % (k % 3))
		poster.set_shader_parameter("emission", Vector3(0.35, 0.35, 0.35))
		# l'affiche bien en avant de son cadre : les sommets tremblent, il ne doit pas la traverser
		var face: float = 1.0 if p[1] == ZA else -1.0
		box(M.inox, 3.1, 1.6, 0.02, p[0], -5.0, p[1] + face * 0.012)
		plane(poster, 3.0, 1.5, p[0], -5.0, p[1] + face * 0.08, p[2])
		k += 1
	for x in [-30, -2, 22]:
		plane(M.nepas, 1.1, 0.21, x, -5.5, ZB - 0.03, PI)
	plane(M.repere, 0.45, 0.45, -HALF + 1.4, -3.4, 25.5, PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, -HALF + 1.4, -2.6, 25.5)
	plane(M.repere, 0.45, 0.45, HALF - 1.4, -3.4, 28.5, -PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, HALF - 1.4, -2.6, 28.5)
	_build_screens([-18, 16])
	var green: Material = M.seat
	M.seat = _mat("blanc", 0xe0782a)   # sièges orange, comme sur la photo
	_build_seats([[-30, 20.45, 1], [-1, 20.45, 1], [28, 20.45, 1], [-24, 33.55, -1], [8, 33.55, -1], [30, 33.55, -1]])
	M.seat = green

	# panneaux au-dessus des escaliers du passage et devant le couloir de sortie, plans de ligne
	var a_sign := _sign([["ligne", "Nation"]])
	var b_sign := _sign([["ligne", "Pte Dauphine"], ["sortie", "Sortie"]])
	for well in [[ZA + u.w / 2, a_sign, 1], [ZB - u.w / 2, b_sign, 2]]:
		var zc: float = well[0]
		var h: float = 0.25 * well[2]
		for r in [PI / 2, -PI / 2]:
			plane(well[1], 1.5, h * 2, u.x0 - 0.4 + (0.03 if r > 0 else -0.03), -4.1 - h, zc, r)
		box(M.fonteDark, 0.04, h * 2 + 0.02, 1.52, u.x0 - 0.4, -4.1 - h, zc)
		box(M.inox, 0.03, 0.6, 0.03, u.x0 - 0.4, -3.8, zc)
	var out := _sign([["sortie", "Bd de Clichy"]])
	for r in [0.0, PI]:
		plane(out, 1.5, 0.25, DOOR_X, -3.6, ZA + 1.2 + (0.03 if r == 0.0 else -0.03), r)
	box(M.fonteDark, 1.52, 0.27, 0.03, DOOR_X, -3.6, ZA + 1.2)
	_line_plan("Pigalle", "Porte Dauphine", Vector3(5.0, -5.0, ZA + 0.03), 0)
	_line_plan("Pigalle", "Nation", Vector3(-1.0, -5.0, ZB - 0.03), PI)


# --- Couloir, escalier et salle des billets ----------------------------------------
# Le couloir d'après la photo de Métroën (Wikimedia Commons, CC0) : carreaux blancs, liserés
# verts en haut et en bas, néons au plafond, grands cadres d'affiches.

func _build_corridor() -> void:
	var x0 := DOOR_X - CW
	var x1 := DOOR_X + CW
	var h := COR_TOP - PY
	var length := ZA - COR_Z0
	var zm := (COR_Z0 + ZA) / 2
	rect(M.sol, x0, COR_Z0, x1, ZA, PY, 2.4)
	rect(M.platre, x0, COR_Z0, x1, ZA, COR_TOP, 2.0, PI / 2)
	for x in [x0, x1]:
		var ry := PI / 2 if x == x0 else -PI / 2
		var o := 0.01 if x == x0 else -0.01
		plane(M.carreau, length, h, x, (PY + COR_TOP) / 2, zm, ry, length / TW, h / TH)
		plane(M.frise_verte, length, 0.12, x + o, COR_TOP - 0.15, zm, ry, length / 0.6, 1)
		plane(M.plinthe_verte, length, 0.2, x + o, PY + 0.1, zm, ry, length / 0.6, 1)
		_solid(Vector3(0.2, h, length), Vector3(x + (-0.1 if x == x0 else 0.1), (PY + COR_TOP) / 2, zm))
	for z in [9.0, 13.0, 17.0]:
		box(M.neon, 0.15, 0.04, 2.0, DOOR_X, COR_TOP - 0.03, z)
	for p in [[x1 - 0.03, 15.5, -PI / 2, 1], [x0 + 0.03, 9.5, PI / 2, 2]]:
		var poster := _mat("affiche_%d" % p[3])
		poster.set_shader_parameter("emission", Vector3(0.35, 0.35, 0.35))
		plane(poster, 2.4, 1.2, p[0], PY + 1.4, p[1], p[2])
	_line_plan("Pigalle", "Nation", Vector3(x0 + 0.03, PY + 1.4, 17.5), PI / 2)
	_solid(Vector3(2 * CW, 0.2, length), Vector3(DOOR_X, PY - 0.1, zm))

	# escalier vers la salle des billets (de z = 6 au niveau du quai à z = 0 dans la salle)
	var n := 12
	var rise := (CY - PY) / n
	var run := (COR_Z0 - HALL_Z1) / n
	for i in n:
		var top := PY + (i + 1) * rise
		var z := COR_Z0 - (i + 0.5) * run
		box(M.marche, 2 * CW, top - PY + 0.3, run, DOOR_X, (top + PY - 0.3) / 2, z, 2, 1)
		box(M.inox, 2 * CW, 0.02, 0.05, DOOR_X, top + 0.01, z - run / 2 + 0.025)
	var wall := PackedVector2Array([Vector2(COR_Z0, PY), Vector2(HALL_Z1, CY), Vector2(HALL_Z1, HALL_C), Vector2(COR_Z0, COR_TOP)])
	for sx in [-1.0, 1.0]:
		add(PsxGeo.polygon(wall, 1 / TW, 1 / TH), M.carreau, Vector3(DOOR_X + sx * CW, 0, 0), Vector3(0, -PI / 2, 0))
		_solid(Vector3(0.2, 4.0, COR_Z0 - HALL_Z1), Vector3(DOOR_X + sx * (CW + 0.1), (PY + HALL_C) / 2, (COR_Z0 + HALL_Z1) / 2))
	_slope_ceiling(x0, x1, COR_Z0, COR_TOP, HALL_Z1, HALL_C)
	_ramp(Vector3(DOOR_X, PY, COR_Z0), Vector3(DOOR_X, CY, HALL_Z1), 2 * CW)


## Plafond en pente au-dessus d'une volée de marches, de (z0, y0) à (z1, y1), de x0 à x1.
func _slope_ceiling(x0: float, x1: float, z0: float, y0: float, z1: float, y1: float) -> void:
	var g := PsxGeo.empty()
	for c in [[x0, y0, z0], [x1, y0, z0], [x0, y1, z1], [x1, y1, z1]]:
		g.p.append(Vector3(c[0], c[1], c[2]))
		g.n.append(Vector3.DOWN)
		g.uv.append(Vector2(c[0] / 2.0, c[2] / 2.0))
	g.i.append_array([0, 1, 2, 1, 3, 2])
	add(g, M.platre, Vector3.ZERO)


## La salle des billets, d'après la photo de Métroën (CC0) : plafond bas, carreaux blancs à
## liserés verts, guichet « Services », ligne de contrôle.
func _build_hall() -> void:
	var w := HALL_X1 - HALL_X0
	var d := HALL_Z1 - HALL_Z0
	var h := HALL_C - CY
	var xm := (HALL_X0 + HALL_X1) / 2
	var zm := (HALL_Z0 + HALL_Z1) / 2
	rect(_mat("sol_goudron", 0xc8c8c8), HALL_X0, HALL_Z0, HALL_X1, HALL_Z1, CY, 2.4)
	rect(M.platre, HALL_X0, HALL_Z0, HALL_X1, HALL_Z1, HALL_C, 2.0, PI / 2)
	var walls := [[HALL_X0, HALL_Z0, HALL_X0, HALL_Z1], [HALL_X1, HALL_Z1, HALL_X1, HALL_Z0],
		[HALL_X0, HALL_Z1, DOOR_X - CW, HALL_Z1], [DOOR_X + CW, HALL_Z1, HALL_X1, HALL_Z1],
		[HALL_X1, HALL_Z0, DOOR_X + HX, HALL_Z0], [DOOR_X - HX, HALL_Z0, HALL_X0, HALL_Z0]]
	for wseg in walls:
		var a := Vector2(wseg[0], wseg[1])
		var b := Vector2(wseg[2], wseg[3])
		_wall(M.carreau, a.x, a.y, b.x, b.y, CY, HALL_C, TW, TH)
		_wall(M.frise_verte, a.x, a.y, b.x, b.y, HALL_C - 0.22, HALL_C - 0.1, 0.6, 0.12)
		_wall(M.plinthe_verte, a.x, a.y, b.x, b.y, CY, CY + 0.2, 0.6, 0.2)
	for x in [6.5, 13.5]:
		for z in [-6.0, -1.5]:
			box(M.neon, 1.2, 0.04, 0.3, x, HALL_C - 0.02, z)
	_build_gate_row(HALL_X0, HALL_X1, GATE_Z, CY)
	var services := _sign_from_texture(Panneaux.band(self, "i", "Services"))
	services.set_shader_parameter("emission", Vector3(0.8, 0.8, 0.8))
	box(_mat("blanc", 0x1a2228, false, true), 0.04, 1.0, 2.0, HALL_X1 - 0.02, CY + 1.6, -5.5)
	box(_mat("blanc", 0x2e2f31), 0.12, 1.05, 2.2, HALL_X1 - 0.06, CY + 0.52, -5.5)
	plane(services, 2.0, 0.24, HALL_X1 - 0.04, CY + 2.3, -5.5, -PI / 2)
	_solid(Vector3(0.4, 1.05, 2.2), Vector3(HALL_X1 - 0.2, CY + 0.52, -5.5))
	for z in [-7.0, -6.1]:
		box(_mat("blanc", 0xd8d8d4), 0.45, 1.7, 0.7, HALL_X0 + 0.24, CY + 0.85, z)
		box(M.noir, 0.02, 0.3, 0.4, HALL_X0 + 0.47, CY + 1.25, z)
		_solid(Vector3(0.45, 1.7, 0.7), Vector3(HALL_X0 + 0.24, CY + 0.85, z))
	box(M.inox, 0.05, 1.3, 1.3, HALL_X0 + 0.03, CY + 1.4, -1.5)
	plane(M.plan_reseau, 1.2, 1.2, HALL_X0 + 0.07, CY + 1.4, -1.5, PI / 2)
	var to_quais := _sign([["ligne", "Pte Dauphine"], ["ligne", "Nation"]])
	for r in [0.0, PI]:
		plane(to_quais, 1.5, 0.5, DOOR_X, HALL_C - 0.35, GATE_Z - 1.0 + (0.05 if r == 0.0 else -0.05), r)
	box(M.fonteDark, 1.52, 0.52, 0.02, DOOR_X, HALL_C - 0.35, GATE_Z - 1.0)
	_solid(Vector3(w, 0.2, d), Vector3(xm, CY - 0.1, zm))
	for wseg in walls:
		var a := Vector2(wseg[0], wseg[1])
		var b := Vector2(wseg[2], wseg[3])
		var mid := (a + b) / 2
		_solid(Vector3(maxf(absf(b.x - a.x), 0.2), h, maxf(absf(b.y - a.y), 0.2)), Vector3(mid.x, (CY + HALL_C) / 2, mid.y))

	# escalier de la rue : de la salle (z = -8) au terre-plein (z = -14), en pierre, à ciel ouvert
	var n := 12
	var run := (HALL_Z0 - EXIT_Z) / n
	for i in n:
		var top := CY + (i + 1) * (-CY / n)
		box(M.pierreS, 2 * HX, top - CY + 0.3, run, DOOR_X, (top + CY - 0.3) / 2, HALL_Z0 - (i + 0.5) * run, 2, 1)
	var side := PackedVector2Array([Vector2(EXIT_Z, 0.0), Vector2(HALL_Z0, 0.0), Vector2(HALL_Z0, CY)])
	for sx in [-1.0, 1.0]:
		add(PsxGeo.polygon(side, 1 / TW, 1 / TH), M.carrelage, Vector3(DOOR_X + sx * HX, 0, 0), Vector3(0, -PI / 2, 0))
		_solid(Vector3(0.2, 4.0, HALL_Z0 - EXIT_Z), Vector3(DOOR_X + sx * (HX + 0.1), CY / 2, (HALL_Z0 + EXIT_Z) / 2))
	plane(M.carreau, 2 * HX, -HALL_C, DOOR_X, HALL_C / 2, HALL_Z0, 0, 2, 1)   # tranche de la dalle
	_ramp(Vector3(DOOR_X, CY, HALL_Z0), Vector3(DOOR_X, 0.0, EXIT_Z), 2 * HX)


# --- Le boulevard de Clichy, la place Pigalle, la rue Frochot ------------------------
# D'après les photos de Chabe01 et de Métroën (Wikimedia Commons, voir CREDITS.md) : la bouche
# Guimard « Métropolitain » sur le terre-plein planté, un grand candélabre double, la nuit et
# ses néons. La boutique de l'antiquaire et le bar sont inventés.

func _build_street() -> void:
	var t0 := DOOR_X - HX
	var t1 := DOOR_X + HX
	var asphalt := _mat("sol_goudron", 0x6e6e72)
	# terre-plein (percé par la trémie), trottoirs, chaussées ; sous-couche percée aussi
	for r in [[W0.x, MEDIAN.x, t0, MEDIAN.y], [t1, MEDIAN.x, W1.x, MEDIAN.y], [t0, MEDIAN.x, t1, EXIT_Z], [t0, HALL_Z0, t1, MEDIAN.y],
			[W0.x, 6.0, W1.x, 10.0], [W0.x, -34.0, W1.x, -30.0], [FROCHOT.x, 10.0, FROCHOT.x + 1.0, W1.y], [FROCHOT.y - 1.0, 10.0, FROCHOT.y, W1.y]]:
		rect(M.trottoir, r[0], r[1], r[2], r[3], 0.0, 3.0)
	for r in [[W0.x, MEDIAN.y, W1.x, 6.0], [W0.x, -30.0, W1.x, MEDIAN.x], [FROCHOT.x + 1.0, 10.0, FROCHOT.y - 1.0, W1.y]]:
		rect(asphalt, r[0], r[1], r[2], r[3], 0.0, 2.4)
	for r in [[W0.x, W0.y, t0, W1.y], [t1, W0.y, W1.x, W1.y], [t0, W0.y, t1, EXIT_Z], [t0, HALL_Z0, t1, W1.y]]:
		rect(M.paves, r[0], r[1], r[2], r[3], -0.1, 2.5)
	for z in [MEDIAN.x, MEDIAN.y]:
		box(M.pierre, W1.x - W0.x, 0.12, 0.15, (W0.x + W1.x) / 2, 0.06, z, 70, 0.2)   # bordures du terre-plein

	# immeubles : de part et d'autre du boulevard, et de la rue Frochot
	_block(W0.x, 10, FROCHOT.x, 20, 18, "a")
	_block(FROCHOT.y, 10, W1.x, 20, 17, "b")
	_block(14, 20, FROCHOT.x, W1.y, 16, "b")
	_block(FROCHOT.y, 20, 48, W1.y, 17, "a")
	_block(W0.x, W0.y, -10, -34, 18, "a")
	_block(-6, W0.y, 30, -34, 17, "b")
	_block(34, W0.y, W1.x, -34, 18, "a")

	# la bouche Guimard : parapet, balustrade, arcs et enseigne
	var depth := HALL_Z0 - EXIT_Z
	for x in [t0 - 0.18, t1 + 0.18]:
		box(M.pierre, 0.36, 0.45, depth, x, 0.225, (EXIT_Z + HALL_Z0) / 2, depth, 0.5)
		plane(M.balus, depth, 0.95, x, 0.93, (EXIT_Z + HALL_Z0) / 2, PI / 2, depth * 1.4, 1)
		box(M.fonte, 0.05, 0.05, depth, x, 1.41, (EXIT_Z + HALL_Z0) / 2)
		_solid(Vector3(0.36, 1.5, depth), Vector3(x, 0.75, (EXIT_Z + HALL_Z0) / 2))
	box(M.pierre, 2 * HX + 0.72, 0.45, 0.36, DOOR_X, 0.225, HALL_Z0, 3, 0.5)
	plane(M.balus, 2 * HX + 0.72, 0.95, DOOR_X, 0.93, HALL_Z0, 0, 3.9, 1)
	_solid(Vector3(2 * HX + 0.72, 1.5, 0.36), Vector3(DOOR_X, 0.75, HALL_Z0))
	_build_guimard(Vector3(DOOR_X, 0, EXIT_Z))

	# terre-plein : platanes, bancs, grands candélabres doubles, la fontaine de la place
	var z_mid := (MEDIAN.x + MEDIAN.y) / 2
	var i := 0
	for x in range(-50, 66, 10):
		for z in [MEDIAN.x + 3.0, MEDIAN.y - 3.0]:
			if absf(x - DOOR_X) < 5.0 or absf(x - FOUNTAIN.x) < 6.0:
				continue
			_tree(x, z, i)
			_post(0.35, 3.0, Vector3(x, 0, z))
			i += 1
	for x in CANDELABRAS:
		add(PsxGeo.cylinder(0.08, 0.16, 6.0, 6), M.fonteDark, Vector3(x, 3.0, z_mid))
		add(PsxGeo.box(1.5, 0.06, 0.06), M.fonteDark, Vector3(x, 6.0, z_mid))
		for dx in [-0.7, 0.7]:
			add(PsxGeo.sphere(0.24, 6, 4), M.lanterne, Vector3(x + dx, 6.2, z_mid), Vector3.ZERO, Vector3(1, 1.25, 1))
		_post(0.18, 3.0, Vector3(x, 0, z_mid))
	for x in [-30.0, -2.0, 18.0, 50.0]:
		box(_mat("blanc", 0x2f4a3a), 1.8, 0.08, 0.5, x, 0.45, z_mid + 1.6)
		box(_mat("blanc", 0x2f4a3a), 1.8, 0.5, 0.06, x, 0.7, z_mid + 1.85)
	var f := FOUNTAIN
	add(PsxGeo.uv_scale(PsxGeo.cylinder(3.0, 3.1, 0.6, 16), 12, 1), M.pierre, f + Vector3(0, 0.3, 0))
	add(PsxGeo.cylinder(2.8, 2.8, 0.02, 16), _mat("blanc", 0x24406a), f + Vector3(0, 0.5, 0))
	add(PsxGeo.cylinder(0.3, 0.4, 1.6, 8), M.pierre, f + Vector3(0, 1.3, 0))
	add(PsxGeo.cylinder(1.1, 0.4, 0.3, 10), M.pierre, f + Vector3(0, 2.2, 0))
	add(PsxGeo.cylinder(0.12, 0.2, 0.8, 6), M.pierre, f + Vector3(0, 2.7, 0))
	_post(3.1, 1.0, f)
	var fountain := Examinable.new()
	fountain.title = "Fontaine de la place Pigalle"
	fountain.description = "La vasque est à sec pour l'hiver. Des canettes au fond, un pigeon endormi sur le rebord."
	fountain.position = f + Vector3(0, 0.6, 0)
	_examinable_shape(fountain, Vector3(6.2, 1.2, 6.2))
	add_child(fountain)

	# néons et vitrines sur le boulevard
	var neons := [["chat_rouge", Vector3(BAR.x, 3.4, 9.97), 0.0, 4.0], ["hotel", Vector3(-22.0, 5.5, 9.97), 0.0, 3.0],
		["cabaret", Vector3(52.0, 4.2, 9.97), 0.0, 4.0], ["tabac", Vector3(4.0, 3.2, -33.97), PI, 2.4]]
	for nn in neons:
		var m := _mat("neon_%s" % nn[0], 0xffffff, false, true)
		var p: Vector3 = nn[1]
		plane(m, nn[3], nn[3] / 4.0, p.x, p.y, p.z, nn[2] + PI)
	var warm := _mat("blanc", 0xd88a5a, false, true)
	for x in [-36.0, -8.0, 44.0, 60.0]:
		box(warm, 3.0, 2.2, 0.04, x, 1.3, 9.98)
	# le Chat Rouge : porte capitonnée rouge, rideau
	box(_mat("blanc", 0x7a1418), 1.4, 2.4, 0.06, BAR.x, 1.2, 9.97)
	box(_mat("blanc", 0x400a0e, false, true), 3.0, 0.3, 0.3, BAR.x, 2.6, 9.85)

	# la boutique d'Antiquités Marchetti, rue Frochot : vitrine éclairée, porte, enseigne
	var s := SHOP
	var vitrine := _mat("vitrine_marchetti", 0xffffff, false, true)
	plane(vitrine, 4.0, 2.4, s.x + 0.04, 1.5, s.z - 1.0, PI / 2)
	box(_mat("blanc", 0x183628), 0.12, 2.8, 0.12, s.x + 0.06, 1.4, s.z - 3.06)
	box(_mat("blanc", 0x183628), 0.12, 2.8, 0.12, s.x + 0.06, 1.4, s.z + 1.06)
	box(_mat("blanc", 0x183628), 0.12, 0.12, 6.2, s.x + 0.06, 2.8, s.z)
	box(_mat("blanc", 0x3a2418), 0.06, 2.3, 1.1, s.x + 0.04, 1.15, s.z + 2.0)
	box(_mat("blanc", 0xf0c070, false, true), 0.02, 0.7, 0.8, s.x + 0.08, 1.7, s.z + 2.0)   # carreau de la porte, éclairé
	plane(_mat("enseigne_marchetti"), 6.0, 0.75, s.x + 0.07, 3.3, s.z, PI / 2)
	var vitrine_item := Examinable.new()
	vitrine_item.title = "Vitrine d'Antiquités Marchetti"
	vitrine_item.description = "Fermé, mais la vitrine reste éclairée. Des vases, un cadre doré, une statuette… et une pendule en bronze doré, sans étiquette de prix."
	vitrine_item.evidence_id = "vitrine"
	vitrine_item.photo_range = 4.0
	vitrine_item.position = Vector3(s.x + 0.15, 1.5, s.z - 1.0)
	_examinable_shape(vitrine_item, Vector3(0.3, 2.4, 4.0))
	add_child(vitrine_item)

	# lampadaires
	for l in LAMPS:
		add(PsxGeo.cylinder(0.06, 0.1, 4.2, 6), M.fonteDark, Vector3(l.x, 2.1, l.y))
		add(PsxGeo.sphere(0.22, 6, 4), M.lanterne, Vector3(l.x, 4.4, l.y), Vector3.ZERO, Vector3(1, 1.25, 1))
		_post(0.12, 3.0, Vector3(l.x, 0, l.y))

	# collisions : sol percé par la trémie, immeubles, limites du quartier
	_solid(Vector3(t0 - W0.x, 0.9, W1.y - W0.y), Vector3((W0.x + t0) / 2, -0.45, (W0.y + W1.y) / 2))
	_solid(Vector3(W1.x - t1, 0.9, W1.y - W0.y), Vector3((t1 + W1.x) / 2, -0.45, (W0.y + W1.y) / 2))
	_solid(Vector3(t1 - t0, 0.9, EXIT_Z - W0.y), Vector3((t0 + t1) / 2, -0.45, (W0.y + EXIT_Z) / 2))
	_solid(Vector3(t1 - t0, 0.9, W1.y - HALL_Z0), Vector3((t0 + t1) / 2, -0.45, (HALL_Z0 + W1.y) / 2))
	for b in [[W0.x, 10, FROCHOT.x, 20], [FROCHOT.y, 10, W1.x, 20], [14, 20, FROCHOT.x, W1.y], [FROCHOT.y, 20, 48, W1.y],
			[W0.x, W0.y, -10, -34], [-6, W0.y, 30, -34], [34, W0.y, W1.x, -34], [-10, W0.y, -6, -34], [30, W0.y, 34, -34],
			[W0.x, 20, 14, W1.y], [48, 20, W1.x, W1.y]]:
		_solid(Vector3(b[2] - b[0], 20, b[3] - b[1]), Vector3((b[0] + b[2]) / 2.0, 10, (b[1] + b[3]) / 2.0))
	for edge in [[Vector3(0.4, 6, W1.y - W0.y), Vector3(W0.x, 3, (W0.y + W1.y) / 2)], [Vector3(0.4, 6, W1.y - W0.y), Vector3(W1.x, 3, (W0.y + W1.y) / 2)],
			[Vector3(W1.x - W0.x, 6, 0.4), Vector3((W0.x + W1.x) / 2, 3, W0.y)], [Vector3(W1.x - W0.x, 6, 0.4), Vector3((W0.x + W1.x) / 2, 3, W1.y)]]:
		_solid(edge[0], edge[1])


# --- Personnages du chapitre 3 ---------------------------------------------------

func _place_people() -> void:
	var cast := [
		["remi", "Un accordéoniste", {"coat": Color("#5a3a2a"), "pants": Color("#2a2a2c"), "skin": Color("#d8a888"), "hair": Color("#9a9690"), "hat": Color("#2a2a30")},
			true, Vector3(DOOR_X - CW + 0.35, PY, 12.0), -PI / 2],
		["lulu", "Le portier du Chat Rouge", {"coat": Color("#111114"), "pants": Color("#111114"), "skin": Color("#8a6048"), "hair": Color("#0e0c0a")},
			false, Vector3(BAR.x + 1.4, 0, 9.3), 0.0],
		["marchetti", "Marchetti, antiquaire", {"coat": Color("#5a5040"), "pants": Color("#2c2a28"), "skin": Color("#d8b090"), "hair": Color("#c8c4bc")},
			false, Vector3(SHOP.x + 0.6, 0, SHOP.z + 2.0), -PI / 2],
	]
	for p in cast:
		var person := Personnage.new(p[0], p[1], p[2], p[3])
		person.name = p[0].capitalize()
		person.position = p[4]
		person.rotation.y = p[5]
		add_child(person)
		people[p[0]] = person
