extends Station
## Station Villiers, quais de la ligne 2, d'après des photos prises comme modèles (voir
## CREDITS.md) : voûte blanche, bande de carreaux bleu clair au pied des murs, bandeaux
## lumineux le long de la voûte, et, au milieu de chaque quai, l'escalier qui descend vers la
## correspondance, entouré d'une rambarde grise à ampoules posée sur une bordure gris foncé,
## ses contremarches peintes d'une fresque bleue et blanche. On arrive sur le quai direction
## Porte Dauphine par un couloir en tube, carrelé jusqu'en haut de la voûte.
## Au fond du passage sous les voies, un couloir descend vers la ligne 3, qui croise la ligne 2
## à angle droit, plus bas. Son quai est construit avec les mêmes fonctions, dans un repère
## tourné (LINE3) ; sur le quai direction Gallieni, un petit local carrelé à porte grise.
## Même repère que Monceau (voir Station) ; la salle des billets et la surface viendront ensuite.

# Couloir en tube vers la sortie, perpendiculaire au quai A
const TUBE_X := -19.0          # axe du couloir
const TUBE_HW := 1.2           # demi-largeur
const TUBE_Z0 := 12.0          # fond du couloir (accès à la salle des billets, à venir)
const TUBE_SPRING := PY + 1.4  # naissance de la voûte du couloir
const TUBE_TOP := PY + 2.6     # clé de la voûte

# Ligne 3 : repère de son quai. Les voies (axe X local) suivent l'axe Z du monde ; le quai A
# local (mur en z = 20) est en x = 18 dans le monde, 7,5 m plus bas que la ligne 2 :
# monde = (z_local - 2, y_local - 7,5, 27 - x_local).
const LINE3 := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(-2.0, -7.5, 27.0))
const L3_PY := PY - 7.5           # quai de la ligne 3, dans le monde
const LINE3_COLOR := Color("#9f9825")
const L3_DOOR := 1.0              # demi-largeur de l'arrivée du couloir dans le mur du quai A (x local)
const L3_KIOSK := Vector3(27.0, 0, 33.2)   # local technique sur le quai B (repère local)

# Couloir de correspondance : du fond du passage (x = 7,9) au quai A de la ligne 3 (x = 18)
const CORR_Z0 := 26.0
const CORR_Z1 := 28.0
const CORR_STAIRS := Vector2(9.5, 15.0)   # haut et bas de l'escalier (x)
const CORR_X1 := 18.0
const CORR_STEPS := 11

## Passage sous les voies (vers la correspondance avec la ligne 3).
var UNDERPASS := {}
var trafic3: Trafic


func _underpass() -> Dictionary:
	if UNDERPASS.is_empty():
		UNDERPASS = {"x0": -2.0, "x1": 5.5, "x2": 7.9, "w": 1.6, "floor": -10.9, "ceil": -8.2, "door": [CORR_Z0, CORR_Z1],
			"rail": M.rambarde, "rail_h": 1.25, "rail_tile": 0.8, "top_rail": null, "curb": M.carreau_gris,
			"risers": M.fresque, "frieze": M.carreau_bleu, "plinth": M.carreau_gris}
	return UNDERPASS


func _ready() -> void:
	_under_lamps = [Vector3(TUBE_X, PY + 2.0, 18.0), Vector3(TUBE_X, PY + 2.0, 13.5)]
	_begin()
	M.nom = _mat("nom_villiers")
	M.rambarde = _mat("rambarde_villiers", 0xffffff, true)
	M.carreau_bleu = _mat("carreau_bleu")
	M.carreau_gris = _mat("carreau_gris")
	M.fresque = _mat("fresque_villiers")
	var barriers := _platform_colliders(_underpass(), [[[TUBE_X - TUBE_HW, TUBE_X + TUBE_HW]], []])
	_build_tube_colliders()
	_setup_trafic([[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], barriers)
	_build_platforms()
	_build_underpass(_underpass())
	_build_signs()
	_build_tube()
	_build_correspondence()
	_frame = LINE3
	trafic3 = _add_trafic("Trafic3", [[25.5, -1, 1, 20.0, "Pont de Levallois"], [28.5, 1, -1, 66.0, "Gallieni"]],
		_line3_colliders(), "3", LINE3_COLOR)
	_build_line3()
	_frame = Transform3D.IDENTITY
	_builder.build(self)
	_set_platform_zone()
	# seconde zone éclairée : le quai de la ligne 3
	var a := LINE3 * Vector3(-HALF - 1.0, -1000.0, ZA - 0.4)
	var b := LINE3 * Vector3(HALF + 1.0, -0.3, ZB + 0.6)
	_global("zone2_color", Vector3(0.98, 0.97, 0.92))
	_global("zone2_min", a.min(b))
	_global("zone2_max", a.max(b))
	set_night(night)


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	for t: Trafic in [trafic, trafic3]:
		var train: MF01 = t.train_at(pos) if t else null
		if train:
			if t.is_moving(train):
				return "Rame · prochaine station : Villiers"
			return "Rame ligne %s · direction %s" % [t.line, train.destination]
	var local3 := LINE3.affine_inverse() * pos
	if pos.x > CORR_X1 - 0.05 and pos.y < L3_PY + 1.0:
		return "Quai ligne 3 · direction %s" % ("Gallieni" if local3.z > CZ else "Pont de Levallois")
	if pos.x > 7.85 and pos.y < -8.0:
		return "Couloir de correspondance · Villiers"
	var u := _underpass()
	if pos.y < u.floor + 0.3:
		return "Passage sous les voies · Villiers"
	if pos.y < PY - 0.2:
		return "Escalier · Villiers"
	if pos.z < ZA:
		return "Couloir · Villiers"
	return "Quai · direction Nation" if pos.z > CZ else "Quai · direction Porte Dauphine"


# --- Quais ---------------------------------------------------------------------

func _build_platforms() -> void:
	var u := _underpass()
	_build_platform_floors(u)
	_build_tracks()
	# piédroits : le mur du quai A est percé par le couloir en tube
	var tx0 := TUBE_X - TUBE_HW
	var tx1 := TUBE_X + TUBE_HW
	for run in [[X0, tx0], [tx1, X1]]:
		var length: float = run[1] - run[0]
		plane(M.carreau, length, WT - PY, (run[0] + run[1]) / 2, (PY + WT) / 2, ZA, 0, length / TW, (WT - PY) / TH)
	var over := PackedVector2Array([Vector2(tx0, TUBE_SPRING)])
	for i in range(1, 12):
		var a := PI - PI * i / 12
		over.append(Vector2(TUBE_X + TUBE_HW * cos(a), TUBE_SPRING + (TUBE_TOP - TUBE_SPRING) * sin(a)))
	over.append_array([Vector2(tx1, TUBE_SPRING), Vector2(tx1, WT), Vector2(tx0, WT)])
	add(PsxGeo.polygon(over, 1 / TW, 1 / TH), M.carreau, Vector3(0, 0, ZA))
	plane(M.carreau, L, WT - PY, 0, (PY + WT) / 2, ZB, 0, L / TW, (WT - PY) / TH)
	# bande de carreaux bleu clair au pied des murs, interrompue au-dessus des escaliers
	for run in [[X0, tx0, ZA + 0.01], [tx1, u.x0, ZA + 0.01], [u.x1, X1, ZA + 0.01], [X0, u.x0, ZB - 0.01], [u.x1, X1, ZB - 0.01]]:
		var length: float = run[1] - run[0]
		plane(M.carreau_bleu, length, 0.25, (run[0] + run[1]) / 2, PY + 0.125, run[2], 0, length / 0.6, 1)
	_build_shell(false)

	# bandeaux lumineux le long de la voûte, au-dessus de chaque quai
	for side in [[21.2, 1.0], [32.8, -1.0]]:
		var z: float = side[0]
		var tilt: float = side[1] * 0.45
		add(PsxGeo.box(L - 2, 0.05, 0.8), M.inox, Vector3(0, -3.55, z), Vector3(tilt, 0, 0))
		add(PsxGeo.box(L - 2, 0.04, 0.6), M.neon, Vector3(0, -3.6, z + side[1] * 0.02), Vector3(tilt, 0, 0))

	# plaques, consignes, repères de tête de train
	for x in [-26, -6, 12, 26]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZA + 0.03, 0)
	for x in [-24, -10, 1.75, 16, 28]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZB - 0.03, PI)
	for x in [-30, -14, 12, 22]:
		plane(M.nepas, 1.1, 0.21, x, -5.5, ZB - 0.03, PI)
	plane(M.repere, 0.45, 0.45, -HALF + 1.4, -3.4, 25.5, PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, -HALF + 1.4, -2.6, 25.5)
	plane(M.repere, 0.45, 0.45, HALF - 1.4, -3.4, 28.5, -PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, HALF - 1.4, -2.6, 28.5)
	for x in [-30, 18]:
		box(M.inox, 1.5, 1.5, 0.05, x, -5.05, ZA + 0.03)
		plane(M.plan_reseau, 1.38, 1.38, x, -5.05, ZA + 0.06, 0)

	_build_screens([-12, 14])
	_build_seats([[-28, 20.45, 1], [-11, 20.45, 1], [24, 20.45, 1], [-24, 33.55, -1], [-9, 33.55, -1], [20, 33.55, -1]])

	# distributeurs verts contre le mur du quai A
	var green := _mat("blanc", 0x2fa05a)
	for x in [9.0, 10.1]:
		box(green, 0.9, 1.85, 0.75, x, PY + 0.93, ZA + 0.4)
		box(M.noir, 0.6, 0.9, 0.02, x, PY + 1.2, ZA + 0.78)
		_solid(Vector3(0.9, 1.85, 0.75), Vector3(x, PY + 0.93, ZA + 0.4))


## Panneaux de direction au-dessus des escaliers, plans de ligne.
func _build_signs() -> void:
	var u := _underpass()
	var a_sign := _sign([["ligne", "Nation"], ["ligne3", "Correspondance"]])
	var b_sign := _sign([["ligne", "Pte Dauphine"], ["ligne3", "Correspondance"], ["sortie", "Sortie"]])
	for well in [[ZA + u.w / 2, a_sign, 2], [ZB - u.w / 2, b_sign, 3]]:
		var zc: float = well[0]
		var rows: int = well[2]
		var h := 0.25 * rows
		for r in [PI / 2, -PI / 2]:
			plane(well[1], 1.5, h, u.x0 - 0.4 + (0.03 if r > 0 else -0.03), -4.1 - h / 2, zc, r)
		box(M.fonteDark, 0.04, h + 0.02, 1.52, u.x0 - 0.4, -4.1 - h / 2, zc)
		box(M.inox, 0.03, 0.6, 0.03, u.x0 - 0.4, -3.8, zc)
	# en bas, de part et d'autre de l'entrée du couloir : vers la ligne 3
	var to_line3 := _sign([["ligne3", "Correspondance"]])
	plane(to_line3, 1.5, 0.5, u.x2 - 0.02, -9.4, CORR_Z0 - 1.2, -PI / 2)
	plane(to_line3, 1.5, 0.5, u.x2 - 0.02, -9.4, CORR_Z1 + 1.2, -PI / 2)
	# plans de ligne : sur les quais, et au pied des escaliers comme sur la photo
	_line_plan("Villiers", "Porte Dauphine", Vector3(-15.5, -5.0, ZA + 0.03), 0)
	_line_plan("Villiers", "Nation", Vector3(-3.6, -5.0, ZB - 0.03), PI)
	_line_plan("Villiers", "Porte Dauphine", Vector3(u.x1 + 0.02, -9.4, ZA + u.w + 1.1), PI / 2)
	_line_plan("Villiers", "Nation", Vector3(u.x1 + 0.02, -9.4, ZB - u.w - 1.1), PI / 2)


# --- Couloir en tube -----------------------------------------------------------

func _tube_profile() -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(-TUBE_HW, PY), Vector2(-TUBE_HW, TUBE_SPRING)])
	for i in range(1, 12):
		var a := PI - PI * i / 12
		pts.append(Vector2(TUBE_HW * cos(a), TUBE_SPRING + (TUBE_TOP - TUBE_SPRING) * sin(a)))
	pts.append_array([Vector2(TUBE_HW, TUBE_SPRING), Vector2(TUBE_HW, PY)])
	return pts


func _build_tube() -> void:
	# parois et voûte d'un seul tenant, carrelées
	var prof := _tube_profile()
	var nz := 8
	var g := PsxGeo.empty()
	var acc := 0.0
	for i in prof.size():
		if i > 0:
			acc += prof[i].distance_to(prof[i - 1])
		var n := Vector3(-prof[i].x, TUBE_SPRING - prof[i].y if prof[i].y > TUBE_SPRING else 0.0, 0).normalized()
		for j in nz + 1:
			var z := TUBE_Z0 + (ZA - TUBE_Z0) * j / nz
			g.p.append(Vector3(TUBE_X + prof[i].x, prof[i].y, z))
			g.n.append(n)
			g.uv.append(Vector2(z / TW, acc / TH))
	for i in prof.size() - 1:
		for j in nz:
			var a := i * (nz + 1) + j
			var b := a + nz + 1
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	add(g, M.carreau, Vector3.ZERO)
	rect(M.sol, TUBE_X - TUBE_HW, TUBE_Z0, TUBE_X + TUBE_HW, ZA, PY, 2.4)
	# au fond : rideau métallique baissé (la salle des billets n'est pas encore construite)
	var end := PsxGeo.polygon(_tube_profile(), 1 / TW, 1 / TH)
	add(end, M.carreau, Vector3(TUBE_X, 0, TUBE_Z0))
	box(_mat("blanc", 0x5a5e58), 2 * TUBE_HW - 0.2, 2.2, 0.06, TUBE_X, PY + 1.1, TUBE_Z0 + 0.05, 1, 6)
	var exit_sign := _sign([["sortie", "Sortie"]])
	plane(exit_sign, 1.2, 0.2, TUBE_X, TUBE_SPRING + 0.75, TUBE_Z0 + 0.04, 0)
	# deux appliques de part et d'autre, comme sur la photo
	for z in [13.6, 17.6]:
		for s in [-1.0, 1.0]:
			box(M.inox, 0.14, 0.24, 0.45, TUBE_X + s * (TUBE_HW - 0.07), TUBE_SPRING + 0.05, z)
			box(M.neon, 0.02, 0.18, 0.38, TUBE_X + s * (TUBE_HW - 0.15), TUBE_SPRING + 0.05, z)


func _build_tube_colliders() -> void:
	var mid := (TUBE_Z0 + ZA) / 2
	var length := ZA - TUBE_Z0
	_solid(Vector3(2 * TUBE_HW, 0.2, length), Vector3(TUBE_X, PY - 0.1, mid))
	for s in [-1.0, 1.0]:
		_solid(Vector3(0.2, 3.0, length), Vector3(TUBE_X + s * (TUBE_HW + 0.1), PY + 1.5, mid))
	_solid(Vector3(2 * TUBE_HW, 3.0, 0.2), Vector3(TUBE_X, PY + 1.5, TUBE_Z0 - 0.1 + 0.15))


# --- Couloir de correspondance -------------------------------------------------

## Profil du couloir dans le plan (x, y) : sol en escalier puis plafond, de la ligne 2 à la ligne 3.
func _corridor_outline() -> PackedVector2Array:
	var u := _underpass()
	var top: float = _underpass_spring(u)
	return PackedVector2Array([Vector2(u.x2, u.floor), Vector2(CORR_STAIRS.x, u.floor), Vector2(CORR_STAIRS.y, L3_PY),
		Vector2(CORR_X1, L3_PY), Vector2(CORR_X1, L3_PY + (top - u.floor)), Vector2(CORR_STAIRS.y, L3_PY + (top - u.floor)),
		Vector2(CORR_STAIRS.x, top), Vector2(u.x2, top)])


func _build_correspondence() -> void:
	var u := _underpass()
	var top: float = _underpass_spring(u)
	var h: float = top - u.floor
	var width := CORR_Z1 - CORR_Z0
	var zc := (CORR_Z0 + CORR_Z1) / 2
	var step: float = (u.floor - L3_PY) / CORR_STEPS
	var run: float = (CORR_STAIRS.y - CORR_STAIRS.x) / CORR_STEPS
	# murs carrelés des deux côtés, d'un seul tenant
	for z in [CORR_Z0, CORR_Z1]:
		add(PsxGeo.polygon(_corridor_outline(), 1 / TW, 1 / TH), M.carreau, Vector3(0, 0, z))
	# sols et marches
	rect(M.sol, u.x2, CORR_Z0, CORR_STAIRS.x, CORR_Z1, u.floor, 2.4)
	rect(M.sol, CORR_STAIRS.y, CORR_Z0, CORR_X1, CORR_Z1, L3_PY, 2.4)
	for i in CORR_STEPS:
		var t: float = u.floor - (i + 1) * step
		var x: float = CORR_STAIRS.x + (i + 0.5) * run
		box(M.marche, run, t - L3_PY + 0.3, width, x, (t + L3_PY - 0.3) / 2, zc, 1, 2)
		box(M.inox, 0.05, 0.02, width, x - run / 2 + 0.025, t + 0.01, zc)
	rect(M.bande, CORR_STAIRS.x - 0.6, CORR_Z0, CORR_STAIRS.x, CORR_Z1, u.floor + 0.006, 0.55)
	# plafond plat, en pente au-dessus de l'escalier, puis plat
	rect(M.platre, u.x2, CORR_Z0, CORR_STAIRS.x, CORR_Z1, top, 2.0, PI / 2)
	rect(M.platre, CORR_STAIRS.y, CORR_Z0, CORR_X1, CORR_Z1, L3_PY + h, 2.0, PI / 2)
	var g := PsxGeo.empty()
	for corner in [[CORR_STAIRS.x, top, CORR_Z0], [CORR_STAIRS.y, L3_PY + h, CORR_Z0], [CORR_STAIRS.x, top, CORR_Z1], [CORR_STAIRS.y, L3_PY + h, CORR_Z1]]:
		g.p.append(Vector3(corner[0], corner[1], corner[2]))
		g.n.append(Vector3.DOWN)
		g.uv.append(Vector2(corner[0] / 2.0, corner[2] / 2.0))
	g.i.append_array([0, 1, 2, 1, 3, 2])
	add(g, M.platre, Vector3.ZERO)
	# néons, main courante, panneaux
	box(M.neon, 1.4, 0.05, 0.15, (u.x2 + CORR_STAIRS.x) / 2, top - 0.03, zc)
	box(M.neon, 1.6, 0.05, 0.15, (CORR_STAIRS.y + CORR_X1) / 2, L3_PY + h - 0.03, zc)
	var rail_len := Vector2(CORR_STAIRS.y - CORR_STAIRS.x, u.floor - L3_PY).length()
	add(PsxGeo.box(rail_len, 0.04, 0.04), M.candPost, Vector3((CORR_STAIRS.x + CORR_STAIRS.y) / 2, (u.floor + L3_PY) / 2 + 0.9, CORR_Z1 - 0.06),
		Vector3(0, 0, -atan2(u.floor - L3_PY, CORR_STAIRS.y - CORR_STAIRS.x)))
	var down := _sign([["ligne3", "Pont de Levallois"], ["ligne3", "Gallieni"]])
	plane(down, 1.5, 0.5, CORR_STAIRS.x - 0.33, top - 0.3, zc, -PI / 2)   # lu en venant de la ligne 2
	box(M.fonteDark, 0.04, 0.52, 1.52, CORR_STAIRS.x - 0.3, top - 0.3, zc)
	var up := _sign([["ligne", "Pte Dauphine"], ["ligne", "Nation"], ["sortie", "Sortie"]])
	plane(up, 1.5, 0.75, CORR_STAIRS.y + 0.33, L3_PY + h - 0.42, zc, PI / 2)   # lu en venant de la ligne 3
	box(M.fonteDark, 0.04, 0.77, 1.52, CORR_STAIRS.y + 0.3, L3_PY + h - 0.42, zc)

	# collisions : sols, rampe, murs
	_solid(Vector3(CORR_STAIRS.x - u.x2, 0.2, width), Vector3((u.x2 + CORR_STAIRS.x) / 2, u.floor - 0.1, zc))
	_solid(Vector3(CORR_X1 - CORR_STAIRS.y, 0.2, width), Vector3((CORR_STAIRS.y + CORR_X1) / 2, L3_PY - 0.1, zc))
	_ramp(Vector3(CORR_STAIRS.x, u.floor, zc), Vector3(CORR_STAIRS.y, L3_PY, zc), width)
	for z in [CORR_Z0 - 0.1, CORR_Z1 + 0.1]:
		_solid(Vector3(CORR_X1 - u.x2, u.floor - L3_PY + h, 0.2), Vector3((u.x2 + CORR_X1) / 2, (L3_PY + top) / 2, z))


# --- Quai de la ligne 3 (repère LINE3) -------------------------------------------
# D'après la photo de Chabe01 (Wikimedia Commons, CC BY-SA 4.0, voir CREDITS.md) : même voûte
# blanche, rampes lumineuses suspendues, sièges turquoise, et sur le quai direction Gallieni un
# petit local carrelé à porte grise, sous un panneau « Alarme ».

func _build_line3() -> void:
	rect(M.sol, X0, ZA, X1, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, X0, ZT1 + 0.55, X1, ZB, PY, 2.4)
	_build_tracks()
	# piédroits : le mur du quai A est percé par l'arrivée du couloir
	var door_top: float = PY + (_underpass_spring(_underpass()) - _underpass().floor)
	for run in [[X0, -L3_DOOR], [L3_DOOR, X1]]:
		var length: float = run[1] - run[0]
		plane(M.carreau, length, WT - PY, (run[0] + run[1]) / 2, (PY + WT) / 2, ZA, 0, length / TW, (WT - PY) / TH)
	plane(M.carreau, 2 * L3_DOOR, WT - door_top, 0, (door_top + WT) / 2, ZA, 0, 2 * L3_DOOR / TW, (WT - door_top) / TH)
	plane(M.carreau, L, WT - PY, 0, (PY + WT) / 2, ZB, 0, L / TW, (WT - PY) / TH)
	for run in [[X0, -L3_DOOR, ZA + 0.01], [L3_DOOR, X1, ZA + 0.01], [X0, X1, ZB - 0.01]]:
		var length: float = run[1] - run[0]
		plane(M.carreau_bleu, length, 0.25, (run[0] + run[1]) / 2, PY + 0.125, run[2], 0, length / 0.6, 1)
	_build_shell(true)

	# plaques et panneaux
	for x in [-24, -8, 10, 26]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZA + 0.03, 0)
	for x in [-26, -12, 4, 18]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZB - 0.03, PI)
	for x in [-20, 14]:
		plane(M.nepas, 1.1, 0.21, x, -5.5, ZB - 0.03, PI)
	var back := _sign([["ligne", "Correspondance"], ["sortie", "Sortie"]])
	plane(back, 1.5, 0.5, 0, door_top + 0.35, ZA + 0.03, 0)
	plane(M.repere, 0.45, 0.45, -HALF + 1.4, -3.4, 25.5, PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, -HALF + 1.4, -2.6, 25.5)
	plane(M.repere, 0.45, 0.45, HALF - 1.4, -3.4, 28.5, -PI / 2)
	box(M.inox, 0.03, 1.2, 0.03, HALF - 1.4, -2.6, 28.5)
	_build_screens([-10, 16], trafic3)
	# sièges turquoise
	var green: Material = M.seat
	M.seat = _mat("blanc", 0x3fb8b0)
	_build_seats([[-20, 20.45, 1], [8, 20.45, 1], [22, 20.45, 1], [-22, 33.55, -1], [-4, 33.55, -1], [12, 33.55, -1]])
	M.seat = green

	# le local technique, carrelé, porte grise vers les voies, panneau « Alarme » au-dessus
	var k := L3_KIOSK
	box(M.carreau, 2.6, 2.6, 1.6, k.x, PY + 1.3, k.z, 2.6 / TW, 2.6 / TH)
	box(_mat("blanc", 0xe6e5e0), 2.7, 0.08, 1.7, k.x, PY + 2.64, k.z)
	box(_mat("blanc", 0x8e9296), 0.9, 2.05, 0.04, k.x + 0.5, PY + 1.03, k.z - 0.81)
	box(M.inox, 0.1, 0.04, 0.05, k.x + 0.15, PY + 1.0, k.z - 0.84)
	box(_mat("blanc", 0x6a6e72), 0.5, 0.25, 0.03, k.x - 0.6, PY + 1.6, k.z - 0.81)   # grille d'aération
	plane(M.alarme, 1.0, 0.25, k.x, PY + 2.9, k.z - 0.8, PI)
	var door := Examinable.new()
	door.title = "Local technique"
	door.description = "Porte grise à serrure de sécurité. Une étiquette : « Local technique – accès réservé au personnel RATP ». Derrière, on entend souffler une ventilation."
	_place(door, Vector3(k.x + 0.5, PY + 1.03, k.z - 0.85))
	_examinable_shape(door, Vector3(0.9, 2.05, 0.1))
	add_child(door)


## Collisions du quai de la ligne 3 ; renvoie les garde-fous des deux voies.
func _line3_colliders() -> Array[CollisionShape3D]:
	var barriers: Array[CollisionShape3D] = []
	var door_top: float = PY + (_underpass_spring(_underpass()) - _underpass().floor)
	for quai in [[ZA, ZT0, 1.0], [ZB, ZT1, -1.0]]:
		var zw: float = quai[0]
		var ze: float = quai[1]
		var inward: float = quai[2]
		_solid(Vector3(L, 0.2, absf(ze - zw)), Vector3(0, PY - 0.1, (zw + ze) / 2))
		var runs := [[X0, -L3_DOOR], [L3_DOOR, X1]] if zw == ZA else [[X0, X1]]
		for r in runs:
			_solid(Vector3(r[1] - r[0], WT - PY, 0.2), Vector3((r[0] + r[1]) / 2, (PY + WT) / 2, zw - inward * 0.1))
		barriers.append(_platform_end_colliders(zw, ze, inward))
	_solid(Vector3(2 * L3_DOOR, WT - door_top, 0.2), Vector3(0, (door_top + WT) / 2, ZA - 0.1))
	_solid(Vector3(2.6, 2.6, 1.6), L3_KIOSK + Vector3(0, PY + 1.3, 0))
	return barriers
