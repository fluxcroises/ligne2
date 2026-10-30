extends Station
## Station Jaurès, aérienne, d'après des photos prises comme modèles (voir CREDITS.md) : quais à
## l'air libre sur le viaduc du boulevard de la Villette, chacun sous un auvent bordé d'un
## lambrequin festonné, grandes fenêtres cintrées sur le mur du fond, sièges bleus ; dessous, un
## bâtiment de brique abrite la salle des billets, d'où deux escaliers montent aux quais ; aux
## deux bouts, des piles de pierre, puis le viaduc à poutres en treillis sur ses colonnes de fonte.
## Plus loin sous le viaduc, le dépôt des trains de travaux (inventé) : locotracteur, wagon chargé,
## bureau de chantier.
## Les quais sont construits dans le repère commun des stations, relevé de LIFT : le quai est
## 6 m au-dessus de la rue (y = 0).

const LIFT := 12.48
const UP := Transform3D(Basis(), Vector3(0, LIFT, 0))
const QY := PY + LIFT          # quai, dans le monde
const DECK := RY + LIFT        # dessus du tablier, sous les rails
const HALL_C := 4.2            # plafond de la salle des billets, sous le tablier
const HALL_X0 := -16.0
const HALL_X1 := 10.0
const ENTRY := Vector2(-14.0, -10.5)   # porte de la salle, sur la façade côté boulevard (x)
const GATE_X := -8.0                   # ligne de contrôle, en travers de la salle
const PIER := 40.5                     # bout des piles de pierre (x)
const VIADUCT := 150.0

# Surface (le boulevard de la Villette suit l'axe X, sous le viaduc)
const W0 := Vector2(-80.0, -6.0)
const W1 := Vector2(120.0, 60.0)
const DEPOT := Vector4(46.0, 21.0, 110.0, 33.0)   # x0, z0, x1, z1 : la cour du dépôt, sous le viaduc
const GATE_Z := Vector2(26.0, 28.0)               # portail du dépôt (z), en x = DEPOT.x
const OFFICE := Vector4(76.0, 29.5, 82.0, 32.5)   # bureau de chantier (Algeco)
const OFFICE_DOOR := Vector2(78.0, 78.9)          # porte du bureau (x), sur sa face z = OFFICE.y
const LAMPS := [Vector2(-50.0, 9.0), Vector2(-10.0, 9.0), Vector2(30.0, 9.0), Vector2(70.0, 9.0), Vector2(-30.0, 45.0), Vector2(20.0, 45.0)]

var UNDERPASS := {}
var depot_gate: Node3D
var depot_open := false


## Les escaliers : de chaque quai à la salle des billets, le long du mur du fond.
func _underpass() -> Dictionary:
	if UNDERPASS.is_empty():
		UNDERPASS = {"x0": -6.0, "x1": 5.0, "x2": 7.0, "w": 1.6, "floor": -LIFT, "ceil": HALL_C - LIFT, "steps": 22, "passage": false,
			"rail": M.gardecorps, "rail_h": 1.0, "rail_tile": 1.0, "top_rail": M.fonte, "curb": null, "risers": null,
			"frieze": M.frise_verte, "plinth": M.plinthe_verte}
	return UNDERPASS


func _ready() -> void:
	_under_lamps = [Vector3(68.0, 3.6, 27.0), Vector3(79.0, 2.3, 31.0), Vector3(56.0, 3.6, 27.0)]
	for l in LAMPS:
		_lanterns.append(Vector3(l.x, 4.4, l.y))
	_begin(4)
	M.nom = _mat("nom_jaures")
	_frame = UP
	var barriers := _platform_colliders(_underpass(), [[[ENTRY.x, ENTRY.y]], []])
	_setup_trafic([[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], barriers)
	_build_platforms()
	_build_underpass(_underpass())
	_frame = Transform3D.IDENTITY
	_build_hall()
	_build_viaduct()
	_build_street()
	_build_depot()
	_place_people()
	var chapter := preload("res://scripts/chapitre_4_jeu.gd").new()
	chapter.name = "Chapitre4"
	add_child(chapter)
	_builder.build(self)
	_global("zone_color", Vector3(0.95, 0.95, 0.9))
	_global("zone_min", Vector3(-HALF - 1.0, QY - 0.5, ZA - 0.4))
	_global("zone_max", Vector3(HALF + 1.0, QY + 4.6, ZB + 0.6))
	_global("zone2_color", Vector3(0.82, 0.82, 0.78))
	_global("zone2_min", Vector3(HALL_X0 - 0.1, -0.1, ZA - 0.1))
	_global("zone2_max", Vector3(HALL_X1 + 0.1, HALL_C + 0.1, ZB + 0.1))
	_global("zone3_color", Vector3(0.7, 0.66, 0.55))
	_global("zone3_min", Vector3(OFFICE.x - 0.1, -0.1, OFFICE.y - 0.1))
	_global("zone3_max", Vector3(OFFICE.z + 0.1, 2.8, OFFICE.w + 0.1))
	set_night(night)


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame · prochaine station : %s" % next_station("Jaurès", train.destination)
		return "Rame ligne 2 · direction %s" % train.destination
	if pos.y > QY - 0.3:
		return "Quai · direction Nation" if pos.z > CZ else "Quai · direction Porte Dauphine"
	if pos.y > 0.3:
		return "Escalier · Jaurès"
	if pos.x > OFFICE.x and pos.x < OFFICE.z and pos.z > OFFICE.y and pos.z < OFFICE.w:
		return "Bureau de chantier"
	if pos.x > DEPOT.x and pos.x < DEPOT.z and pos.z > DEPOT.y and pos.z < DEPOT.w:
		return "Dépôt des trains de travaux"
	if pos.x > HALL_X0 and pos.x < HALL_X1 and pos.z > ZA and pos.z < ZB:
		return "Salle des billets · Jaurès"
	return "Boulevard de la Villette"


# --- Quais (repère UP) ------------------------------------------------------------

func _build_platforms() -> void:
	var u := _underpass()
	_build_platform_floors(u)
	_build_tracks()
	# murs du fond : soubassement carrelé, grandes fenêtres cintrées, et le haut du mur
	var window := _mat("fenetre_jaures")
	for z in [ZA, ZB]:
		var ry := 0.0 if z == ZA else PI
		plane(M.carreau, L, 1.0, 0, PY + 0.5, z, ry, L / TW, 1.0 / TH)
		plane(window, L, 2.8, 0, PY + 2.4, z, ry, L / 3.0, 1)
		plane(_mat("blanc", 0xe2e0d8), L, 0.6, 0, PY + 4.1, z, ry, 1, 1)
		plane(M.plinthe, L, 0.2, 0, PY + 0.1, z + (0.01 if z == ZA else -0.01), ry, L / 0.6, 1)
	# auvents : plafond blanc, néons, consoles, et le lambrequin festonné côté voies
	var ceiling := _mat("blanc", 0xe6e4dc)
	var valance := _mat("lambrequin", 0xffffff, true)
	var steel := _mat("blanc", 0x8a8e90)
	for side in [[ZA, ZT0 + 0.4, 1.0], [ZB, ZT1 - 0.4, -1.0]]:
		var zw: float = side[0]
		var ze: float = side[1]
		var zm := (zw + ze) / 2
		box(ceiling, L, 0.12, absf(ze - zw), 0, PY + 4.26, zm, L / 2, 1)
		box(_mat("zinc"), L, 0.08, absf(ze - zw) + 0.2, 0, PY + 4.38, zm, L / 3, 1)
		for r in [0.0, PI]:
			plane(valance, L, 0.8, 0, PY + 3.82, ze + (0.01 if r == 0.0 else -0.01), r, L / 1.6, 1)
		box(M.neon, L - 4, 0.04, 0.2, 0, PY + 4.18, zm)
		for x in range(-36, 37, 6):
			add(PsxGeo.box(0.08, 0.08, 1.8), steel, Vector3(x, PY + 3.7, zw + side[2] * 0.85), Vector3(side[2] * 0.6, 0, 0))
	# plaques, consignes, écrans, sièges bleus, panneaux et plans
	for x in [-26, -12, 14, 28]:
		plane(M.nom, 2.1, 0.52, x, PY + 1.6, ZA + 0.03, 0)
		plane(M.nom, 2.1, 0.52, x + 2, PY + 1.6, ZB - 0.03, PI)
	for x in [-30, 12]:
		plane(M.nepas, 1.1, 0.21, x, PY + 0.9, ZB - 0.03, PI)
	_build_screens([-18, 18])
	var green: Material = M.seat
	M.seat = _mat("blanc", 0x2a5ab0)
	_build_seats([[-24, 20.45, 1], [-14, 20.45, 1], [20, 20.45, 1], [-30, 33.55, -1], [-16, 33.55, -1], [16, 33.55, -1]])
	M.seat = green
	var a_sign := _sign([["sortie", "Sortie"]])
	var b_sign := _sign([["sortie", "Sortie"]])
	for well in [[ZA + u.w / 2, a_sign], [ZB - u.w / 2, b_sign]]:
		var zc: float = well[0]
		for r in [PI / 2, -PI / 2]:
			plane(well[1], 1.2, 0.2, u.x0 - 0.4 + (0.03 if r > 0 else -0.03), PY + 2.6, zc, r)
		box(M.fonteDark, 0.04, 0.22, 1.22, u.x0 - 0.4, PY + 2.6, zc)
		box(M.inox, 0.03, 1.5, 0.03, u.x0 - 0.4, PY + 3.45, zc)
	_line_plan("Jaurès", "Porte Dauphine", Vector3(8.0, PY + 1.5, ZA + 0.03), 0)
	_line_plan("Jaurès", "Nation", Vector3(-4.0, PY + 1.5, ZB - 0.03), PI)


# --- Salle des billets, sous les quais ------------------------------------------------

func _build_hall() -> void:
	var u := _underpass()
	var brick := _mat("brique")
	# le bâtiment de brique sous la station, d'une pile de pierre à l'autre
	for z in [ZA - 0.02, ZB + 0.02]:
		for run in ([[-HALF, ENTRY.x], [ENTRY.y, HALF]] if z < CZ else [[-HALF, HALF]]):
			var length: float = run[1] - run[0]
			plane(brick, length, 5.4, (run[0] + run[1]) / 2, 2.7, z, 0.0 if z < CZ else PI, length / 1.6, 5.4 / 1.6)
	plane(brick, ENTRY.y - ENTRY.x, 5.4 - 2.6, (ENTRY.x + ENTRY.y) / 2, 4.0, ZA - 0.02, 0, 2, 2)   # au-dessus de la porte
	# le bandeau Ⓜ ② ⑤ ⑦bis au-dessus de l'entrée, les portes vitrées ouvertes
	var sigle := _mat("sigle_jaures")
	sigle.set_shader_parameter("emission", Vector3(0.5, 0.5, 0.5))
	plane(sigle, 4.4, 1.1, (ENTRY.x + ENTRY.y) / 2, 3.2, ZA - 0.06, PI)
	for x in [ENTRY.x + 0.05, ENTRY.y - 0.05]:
		box(M.inox, 0.1, 2.6, 0.12, x, 1.3, ZA)
	# dedans : sol, murs carrelés, plafond percé par les escaliers, néons
	rect(_mat("sol_goudron", 0xc8c8c8), HALL_X0, ZA, HALL_X1, ZB, 0.0, 2.4)
	for wall in [[HALL_X0, ZA, HALL_X0, ZB], [HALL_X1, ZB, HALL_X1, ZA]]:
		_wall(M.carreau, wall[0], wall[1], wall[2], wall[3], 0.0, HALL_C, TW, TH)
		_wall(M.plinthe_verte, wall[0], wall[1], wall[2], wall[3], 0.0, 0.2, 0.6, 0.2)
	for wall in [[HALL_X0, ZA + 0.02, u.x0, ZA + 0.02], [u.x1, ZA + 0.02, HALL_X1, ZA + 0.02],
			[HALL_X1, ZB - 0.02, u.x1, ZB - 0.02], [u.x0, ZB - 0.02, HALL_X0, ZB - 0.02]]:
		_wall(M.carreau, wall[0], wall[1], wall[2], wall[3], 0.0, HALL_C, TW, TH)
	for r in [[HALL_X0, ZA + u.w, HALL_X1, ZB - u.w], [HALL_X0, ZA, u.x0, ZA + u.w], [u.x1, ZA, HALL_X1, ZA + u.w],
			[HALL_X0, ZB - u.w, u.x0, ZB], [u.x1, ZB - u.w, HALL_X1, ZB]]:
		rect(M.platre, r[0], r[1], r[2], r[3], HALL_C, 2.0, PI / 2)
	for x in [-12.0, -2.0, 7.0]:
		box(M.neon, 1.2, 0.04, 0.3, x, HALL_C - 0.03, CZ)
	# ligne de contrôle en travers de la salle (on entre du côté de la porte, x < GATE_X)
	_frame = Transform3D(Basis(Vector3.UP, PI / 2), Vector3(GATE_X, 0, 0))
	_build_gate_row(-ZB, -ZA, 0.0, 0.0)
	_frame = Transform3D.IDENTITY
	var services := _sign_from_texture(Panneaux.band(self, "i", "Services"))
	services.set_shader_parameter("emission", Vector3(0.8, 0.8, 0.8))
	box(_mat("blanc", 0x1a2228, false, true), 2.0, 1.0, 0.04, -13.0, 1.6, ZB - 0.04)
	box(_mat("blanc", 0x2e2f31), 2.2, 1.05, 0.12, -13.0, 0.52, ZB - 0.08)
	plane(services, 2.0, 0.24, -13.0, 2.3, ZB - 0.05, PI)
	_solid(Vector3(2.2, 1.05, 0.4), Vector3(-13.0, 0.52, ZB - 0.2))
	var to_quais := _sign([["ligne", "Pte Dauphine"], ["ligne", "Nation"]])
	for r in [PI / 2, -PI / 2]:
		plane(to_quais, 1.5, 0.5, GATE_X + 1.5 + (0.05 if r > 0 else -0.05), HALL_C - 0.4, CZ, r)
	box(M.fonteDark, 0.02, 0.52, 1.52, GATE_X + 1.5, HALL_C - 0.4, CZ)
	# collisions : murs intérieurs (le reste du bâtiment est plein)
	_solid(Vector3(0.2, 6.0, ZB - ZA), Vector3(HALL_X0 - 0.1, 3.0, CZ))
	_solid(Vector3(0.2, 6.0, ZB - ZA), Vector3(HALL_X1 + 0.1, 3.0, CZ))
	for run in [[-HALF, HALL_X0], [HALL_X1, HALF]]:
		_solid(Vector3(run[1] - run[0], 5.4, ZB - ZA), Vector3((run[0] + run[1]) / 2, 2.7, CZ))


# --- Le viaduc, les piles de pierre, les colonnes de fonte -------------------------------

func _build_viaduct() -> void:
	var stone: Material = M.pierre
	var lattice := _mat("treillis", 0xffffff, true)
	var steel := _mat("blanc", 0x6e7476)
	var iron := _mat("blanc", 0x9aa0a2)
	# piles de pierre aux deux bouts de la station, de part et d'autre des voies
	for sx in [-1.0, 1.0]:
		var xc: float = sx * (HALF + PIER) / 2
		for zr in [[ZA - 0.5, ZT0 - 0.4], [ZT1 + 0.4, ZB + 0.5]]:
			var depth: float = zr[1] - zr[0]
			box(stone, PIER - HALF, QY + 4.6, depth, xc, (QY + 4.6) / 2, (zr[0] + zr[1]) / 2, 2, 6)
			_solid(Vector3(PIER - HALF, QY + 4.6, depth), Vector3(xc, (QY + 4.6) / 2, (zr[0] + zr[1]) / 2))
		box(stone, PIER - HALF, 1.2, ZB - ZA + 1.0, xc, QY + 5.2, CZ, 2, 1)
	# le tablier et ses poutres en treillis, de la pile au bout du quartier
	for sx in [-1.0, 1.0]:
		var x0 := PIER
		var xc: float = sx * (x0 + VIADUCT) / 2
		var length := VIADUCT - x0
		box(steel, length, 0.8, ZT1 - ZT0 + 0.8, xc, DECK - 0.4, CZ, length / 4, 1)
		for z in [ZT0 - 0.4, ZT1 + 0.4]:
			for r in [0.0, PI]:
				plane(lattice, length, 2.4, xc, DECK - 0.2, z + (0.02 if r == 0.0 else -0.02), r, length / 4.8, 1)
		# rails du tablier, au-delà des quais (ceux de la station sont posés par _build_tracks)
		for c in [25.5, 28.5]:
			for o in [-0.72, 0.72]:
				box(M.rail, length, 0.14, 0.08, xc, DECK + 0.07, c + o)
		rect(M.voie, minf(sx * x0, sx * VIADUCT), ZT0, maxf(sx * x0, sx * VIADUCT), ZT1, DECK, 1.2)
		# colonnes de fonte cannelées, par paires, sous le tablier
		var x := x0 + 6.0
		while x < VIADUCT:
			for z in [ZT0 + 0.2, ZT1 - 0.2]:
				var p := Vector3(sx * x, 0, z)
				add(PsxGeo.cylinder(0.32, 0.4, DECK - 1.6, 8), iron, p + Vector3(0, (DECK - 1.6) / 2, 0))
				add(PsxGeo.cylinder(0.6, 0.4, 0.5, 8), iron, p + Vector3(0, DECK - 1.35, 0))
				add(PsxGeo.box(1.0, 0.4, 1.0), stone, p + Vector3(0, 0.2, 0))
				_post(0.45, 4.0, p)
			x += 18.0


# --- Le boulevard de la Villette -------------------------------------------------------

func _build_street() -> void:
	var asphalt := _mat("sol_goudron", 0x6e6e72)
	for r in [[W0.x, 6.0, W1.x, 10.0], [W0.x, 44.0, W1.x, 48.0], [-HALF, 18.0, HALF, ZA], [-HALF, ZB, HALF, 36.0],
			[W0.x, 18.0, -HALF, 36.0], [HALF, 18.0, DEPOT.x, 36.0], [DEPOT.x, 18.0, W1.x, DEPOT.y], [DEPOT.x, DEPOT.w, W1.x, 36.0]]:
		rect(M.trottoir, r[0], r[1], r[2], r[3], 0.0, 3.0)
	for r in [[W0.x, 10.0, W1.x, 18.0], [W0.x, 36.0, W1.x, 44.0]]:
		rect(asphalt, r[0], r[1], r[2], r[3], 0.0, 2.4)
	rect(M.paves, W0.x, W0.y, W1.x, W1.y, -0.1, 2.5)
	# immeubles de part et d'autre du boulevard
	_block(-80, -6, -40, 6, 18, "a")
	_block(-36, -6, 0, 6, 17, "b")
	_block(4, -6, 50, 6, 19, "a")
	_block(54, -6, 120, 6, 18, "b")
	_block(-80, 48, -20, 60, 18, "b")
	_block(-16, 48, 60, 60, 18, "a")
	_block(64, 48, 120, 60, 17, "b")
	# sous le viaduc, côté ouest : jardinières plantées, comme sur les photos
	for x in [-70.0, -58.0, -46.0]:
		box(_mat("blanc", 0x5a5a56), 6.0, 0.6, 2.2, x, 0.3, CZ)
		for k in 4:
			add(PsxGeo.uv_scale(PsxGeo.icosahedron(0.55), 1, 1), M.feuil, Vector3(x - 2.2 + k * 1.5, 0.9, CZ + (k % 2) * 0.4 - 0.2))
		_solid(Vector3(6.0, 0.6, 2.2), Vector3(x, 0.3, CZ))
	for l in LAMPS:
		add(PsxGeo.cylinder(0.06, 0.1, 4.2, 6), M.fonteDark, Vector3(l.x, 2.1, l.y))
		add(PsxGeo.sphere(0.22, 6, 4), M.lanterne, Vector3(l.x, 4.4, l.y), Vector3.ZERO, Vector3(1, 1.25, 1))
		_post(0.12, 3.0, Vector3(l.x, 0, l.y))
	# collisions : sol, immeubles, limites
	_solid(Vector3(W1.x - W0.x, 0.9, W1.y - W0.y), Vector3((W0.x + W1.x) / 2, -0.45, (W0.y + W1.y) / 2))
	for b in [[-80, -6, -40, 6], [-36, -6, 0, 6], [4, -6, 50, 6], [54, -6, 120, 6], [-40, -6, -36, 6], [0, -6, 4, 6], [50, -6, 54, 6],
			[-80, 48, -20, 60], [-16, 48, 60, 60], [64, 48, 120, 60], [-20, 48, -16, 60], [60, 48, 64, 60]]:
		_solid(Vector3(b[2] - b[0], 20, b[3] - b[1]), Vector3((b[0] + b[2]) / 2.0, 10, (b[1] + b[3]) / 2.0))
	for edge in [[Vector3(0.4, 6, W1.y - W0.y), Vector3(W0.x, 3, (W0.y + W1.y) / 2)], [Vector3(0.4, 6, W1.y - W0.y), Vector3(W1.x, 3, (W0.y + W1.y) / 2)]]:
		_solid(edge[0], edge[1])


# --- Le dépôt des trains de travaux, sous le viaduc ---------------------------------------

func _build_depot() -> void:
	var d := DEPOT
	var fence: Material = M.gardecorps
	# sol, grille tout autour, portail
	rect(_mat("sol_goudron", 0x5a5a5c), d.x, d.y, d.z, d.w, 0.01, 2.4)
	for z in [d.y, d.w]:
		plane(fence, d.z - d.x, 2.2, (d.x + d.z) / 2, 1.1, z, 0, (d.z - d.x) / 1.1, 2)
		_solid(Vector3(d.z - d.x, 2.4, 0.1), Vector3((d.x + d.z) / 2, 1.2, z))
	for run in [[d.y, GATE_Z.x], [GATE_Z.y, d.w]]:
		plane(fence, run[1] - run[0], 2.2, d.x, 1.1, (run[0] + run[1]) / 2, PI / 2, (run[1] - run[0]) / 1.1, 2)
		_solid(Vector3(0.1, 2.4, run[1] - run[0]), Vector3(d.x, 1.2, (run[0] + run[1]) / 2))
	_solid(Vector3(0.1, 2.4, d.w - d.y), Vector3(d.z, 1.2, (d.y + d.w) / 2))
	depot_gate = Node3D.new()
	depot_gate.position = Vector3(d.x, 0, GATE_Z.x)
	add_child(depot_gate)
	var leaf := PsxBuilder.new()
	var w := GATE_Z.y - GATE_Z.x
	leaf.add(PsxGeo.uv_scale(PsxGeo.plane(w, 2.2), w / 1.1, 2), fence, PsxGeo.xf(Vector3(0, 1.1, w / 2), Vector3(0, PI / 2, 0)))
	leaf.add(PsxGeo.box(0.06, 2.3, 0.06), M.fonteDark, PsxGeo.xf(Vector3(0, 1.15, w)))
	leaf.build(depot_gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.1, 2.4, w)
	shape.position = Vector3(0, 1.2, w / 2)
	body.add_child(shape)
	depot_gate.add_child(body)
	var plate := Examinable.new()
	plate.title = "Portail du dépôt"
	plate.description = "Une plaque : « RATP – Maintenance des voies – Accès interdit ». Cadenas neuf."
	plate.position = Vector3(d.x - 0.1, 1.2, (GATE_Z.x + GATE_Z.y) / 2)
	_examinable_shape(plate, Vector3(0.2, 2.2, w))
	add_child(plate)

	# une voie au sol, le locotracteur jaune et son wagon plat chargé de caisses sous une bâche
	var zt := (d.y + d.w) / 2
	rect(M.voie, d.x + 4.0, zt - 1.2, d.z, zt + 1.2, 0.02, 1.2)
	for o in [-0.72, 0.72]:
		box(M.rail, d.z - d.x - 4.0, 0.14, 0.08, (d.x + 4.0 + d.z) / 2, 0.09, zt + o)
	var yellow := _mat("locotracteur")
	var dark := _mat("blanc", 0x1c1e20)
	var loco := Vector3(57.0, 0, zt)
	box(dark, 6.0, 0.8, 2.2, loco.x, 0.55, loco.z)
	box(_mat("blanc", 0xe8ba1e), 6.0, 1.6, 2.3, loco.x, 1.75, loco.z)
	for r in [0.0, PI]:
		plane(yellow, 6.0, 2.4, loco.x, 1.75, loco.z + (1.16 if r == 0.0 else -1.16), r)
	box(_mat("blanc", 0xe8ba1e), 2.4, 1.0, 2.3, loco.x + 1.6, 3.05, loco.z)
	box(_mat("blanc", 0xf0a020, false, true), 0.1, 0.12, 0.12, loco.x - 3.0, 2.6, loco.z)   # gyrophare
	var wagon := Vector3(65.5, 0, zt)
	box(dark, 9.0, 0.5, 2.3, wagon.x, 0.75, wagon.z)
	var tarp := _mat("blanc", 0x4a5a48)
	var wood := _mat("blanc", 0x8a6a3a)
	for k in 5:
		box(wood, 1.4, 1.0, 1.2, wagon.x - 3.4 + k * 1.7, 1.5, wagon.z - 0.4 + (k % 2) * 0.6)
	add(PsxGeo.box(4.4, 1.3, 2.4), tarp, Vector3(wagon.x + 2.0, 1.65, wagon.z), Vector3(0, 0, 0.06))
	_solid(Vector3(6.0, 3.6, 2.4), loco + Vector3(0, 1.8, 0))
	_solid(Vector3(9.0, 2.2, 2.4), wagon + Vector3(0, 1.1, 0))
	var train := Examinable.new()
	train.title = "Locotracteur et wagon"
	train.description = "Un locotracteur jaune « TRAVAUX » et son wagon plat. Sous une bâche mal tirée, des caisses neuves : « Fragile – Objets d'art »."
	train.evidence_id = "draisine"
	train.photo_range = 7.0
	train.position = (loco + wagon) / 2 + Vector3(0, 1.5, 0)
	_examinable_shape(train, Vector3(16.0, 3.0, 2.6))
	add_child(train)
	# projecteur de chantier
	add(PsxGeo.cylinder(0.05, 0.08, 3.6, 5), M.fonteDark, Vector3(68.0, 1.8, d.y + 0.6))
	box(_mat("blanc", 0xfff2c0, false, true), 0.6, 0.4, 0.2, 68.0, 3.7, d.y + 0.7)

	# le bureau de chantier (Algeco) : porte ouverte, lumière, bureau, registre
	var o := OFFICE
	var panel := _mat("blanc", 0xd6d6cc)
	var h := 2.6
	for run in [[o.x, OFFICE_DOOR.x], [OFFICE_DOOR.y, o.z]]:
		box(panel, run[1] - run[0], h, 0.08, (run[0] + run[1]) / 2, h / 2, o.y, (run[1] - run[0]) / 1.2, 1)
		_solid(Vector3(run[1] - run[0], h, 0.1), Vector3((run[0] + run[1]) / 2, h / 2, o.y))
	box(panel, OFFICE_DOOR.y - OFFICE_DOOR.x, h - 2.05, 0.08, (OFFICE_DOOR.x + OFFICE_DOOR.y) / 2, 2.05 + (h - 2.05) / 2, o.y)
	box(panel, o.z - o.x, h, 0.08, (o.x + o.z) / 2, h / 2, o.w, 4, 1)
	_solid(Vector3(o.z - o.x, h, 0.1), Vector3((o.x + o.z) / 2, h / 2, o.w))
	for x in [o.x, o.z]:
		box(panel, 0.08, h, o.w - o.y, x, h / 2, (o.y + o.w) / 2, 2, 1)
		_solid(Vector3(0.1, h, o.w - o.y), Vector3(x, h / 2, (o.y + o.w) / 2))
	box(_mat("blanc", 0x8a8a84), o.z - o.x + 0.2, 0.12, o.w - o.y + 0.2, (o.x + o.z) / 2, h + 0.06, (o.y + o.w) / 2)
	rect(_mat("blanc", 0x9a8a72), o.x, o.y, o.z, o.w, 0.03, 1.0)
	box(_mat("blanc", 0xf2d27a, false, true), 1.2, 0.6, 0.04, 80.6, 1.6, o.y - 0.03)   # fenêtre éclairée
	box(M.neon, 1.0, 0.04, 0.15, (o.x + o.z) / 2, h - 0.05, (o.y + o.w) / 2)
	var desk := Vector3(80.4, 0, 31.7)
	box(_mat("blanc", 0x6a5a48), 2.2, 0.06, 0.9, desk.x, 0.78, desk.z)
	box(_mat("blanc", 0x4a4038), 2.2, 0.75, 0.06, desk.x, 0.38, desk.z + 0.42)
	_solid(Vector3(2.2, 0.8, 0.9), desk + Vector3(0, 0.4, 0))
	box(_mat("blanc", 0x24304a), 0.4, 0.04, 0.3, desk.x - 0.2, 0.83, desk.z - 0.1)    # le registre
	box(_mat("blanc", 0xf2efe6), 0.36, 0.01, 0.26, desk.x - 0.2, 0.86, desk.z - 0.1)
	box(_mat("blanc", 0x5a6a7a), 0.5, 1.8, 0.5, o.x + 0.35, 0.9, o.w - 0.35)          # armoire
	_solid(Vector3(0.5, 1.8, 0.5), Vector3(o.x + 0.35, 0.9, o.w - 0.35))
	var registre := Examinable.new()
	registre.title = "Registre des trains de travaux"
	registre.description = "Ouvert sur le bureau. Chaque mardi et chaque vendredi : « Intervention voie de garage de Villiers – locotracteur 4 – 1 h 30 / 4 h ». Signé M. Delorme. Aucun numéro de bon de chantier."
	registre.evidence_id = "registre_travaux"
	registre.photo_range = 2.6
	registre.position = desk + Vector3(-0.2, 0.86, -0.1)
	_examinable_shape(registre, Vector3(0.5, 0.15, 0.4))
	add_child(registre)


## Le portail du dépôt : Sami l'ouvre (voir Chapitre4Jeu).
func set_depot_open(on: bool) -> void:
	depot_open = on
	depot_gate.rotation.y = deg_to_rad(-100.0) if on else 0.0


# --- Personnages du chapitre 4 ---------------------------------------------------

func _place_people() -> void:
	var cast := [
		["josiane", "Josiane, agente de station", {"coat": Color("#1f2a4a"), "pants": Color("#1b1f2b"), "skin": Color("#b07a5a"), "hair": Color("#2a1a14")},
			false, Vector3(-20.0, QY, 21.4), PI],
		["sami", "Un agent de maintenance", {"coat": Color("#30363c"), "pants": Color("#24282c"), "skin": Color("#a87250"), "hair": Color("#1a1410"), "vest": Color("#ff7a1a")},
			false, Vector3(DEPOT.x - 1.4, 0, (GATE_Z.x + GATE_Z.y) / 2 + 1.6), PI / 2],
		["delorme", "Marc Delorme", {"coat": Color("#e8e6e0"), "pants": Color("#2a2c30"), "skin": Color("#d8b090"), "hair": Color("#6a6460"), "vest": Color("#ff7a1a")},
			false, Vector3(76.8, 0, 31.4), -PI / 4],
	]
	for p in cast:
		var person := Personnage.new(p[0], p[1], p[2], p[3])
		person.name = p[0].capitalize()
		person.position = p[4]
		person.rotation.y = p[5]
		add_child(person)
		people[p[0]] = person
