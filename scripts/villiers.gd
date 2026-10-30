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

# Salle des billets, sous la place Prosper-Goubaux ; escaliers dans l'axe du couloir en tube
const CY := -3.24              # sol de la salle
const HALL_C := -0.7           # plafond
const HALL_X0 := -23.5
const HALL_X1 := -14.5
const HALL_Z0 := -4.0          # côté rue (escalier et escalator de sortie)
const HALL_Z1 := 6.0           # côté quais (escalier vers le couloir en tube)
const GATE_Z := 2.5            # ligne de contrôle
const EXIT_Z := -10.0          # haut de l'escalier, au niveau de la place
const ESC := Vector2(-21.8, -20.4)    # escalator de sortie (x)
const TREMIE := Vector2(-21.95, -17.75)   # trémie sur la place (x)

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
const KIOSK_DOOR := Vector2(26.45, 27.35)  # porte grise du local (x local)
const SERV := Vector2(26.3, 27.5)          # couloir de service, dans l'axe de la porte (x local)
const SERV_H := 2.3                        # hauteur du couloir de service

# La boucle désaffectée : ancien terminus de la ligne 3, une voie unique en courbe derrière le
# quai direction Gallieni (repère LINE3). Le couloir de service y débouche sur la banquette.
const BOUCLE_C := Vector2(27.0, 83.0)      # centre de la courbe (x, z locaux)
const BOUCLE_R := 40.0                     # rayon de l'axe de la voie
const BOUCLE_A := Vector2(deg_to_rad(-125.0), deg_to_rad(-55.0))   # étendue de la courbe
const BOUCLE_WALK := Vector2(1.5, 2.6)     # banquette : de r = 1,5 à r = 2,6 (r vers l'extérieur)
const BOUCLE_SPRING := PY + SERV_H         # naissance de la voûte
const SPRAGUE_LEN := 12.6

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
	_under_lamps = [Vector3(TUBE_X, PY + 2.0, 18.0), Vector3(TUBE_X, PY + 2.0, 13.5), Vector3(TUBE_X, -2.6, 9.0),
		Vector3(-19.0, -1.3, 4.0), Vector3(-19.0, -1.3, -1.5)]
	for p in _boucle_lamps():
		_under_lamps.append(LINE3 * p)
	for l in LAMPS:
		_lanterns.append(Vector3(l.x, 4.4, l.y))
	for dz in [-0.7, 0.7]:
		_lanterns.append(Vector3(CANDELABRA.x, 6.2, CANDELABRA.y + dz))
	_begin(2)
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
	_build_hall()
	_build_street()
	_build_correspondence()
	_frame = LINE3
	trafic3 = _add_trafic("Trafic3", [[25.5, -1, 1, 20.0, "Pont de Levallois"], [28.5, 1, -1, 66.0, "Gallieni"]],
		_line3_colliders(), "3", LINE3_COLOR)
	_build_line3()
	_build_boucle()
	_frame = Transform3D.IDENTITY
	_place_people()
	var chapter := preload("res://scripts/chapitre_2_jeu.gd").new()
	chapter.name = "Chapitre2"
	add_child(chapter)
	_builder.build(self)
	_set_platform_zone()
	# seconde zone éclairée : le quai de la ligne 3
	var a := LINE3 * Vector3(-HALF - 1.0, -1000.0, ZA - 0.4)
	var b := LINE3 * Vector3(HALF + 1.0, -0.3, ZB + 0.6)
	_global("zone2_color", Vector3(0.98, 0.97, 0.92))
	_global("zone2_min", a.min(b))
	_global("zone2_max", a.max(b))
	# troisième zone : la salle des billets
	_global("zone3_color", Vector3(0.78, 0.78, 0.76))
	_global("zone3_min", Vector3(HALL_X0 - 0.1, CY - 0.1, HALL_Z0 - 0.1))
	_global("zone3_max", Vector3(HALL_X1 + 0.1, HALL_C + 0.1, HALL_Z1 + 0.1))
	set_night(night)


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	for t: Trafic in [trafic, trafic3]:
		var train: MF01 = t.train_at(pos) if t else null
		if train:
			if t.is_moving(train):
				return "Rame · prochaine station : %s" % next_station("Villiers", train.destination)
			return "Rame ligne %s · direction %s" % [t.line, train.destination]
	if pos.y > -0.6:
		return "Rue de Lévis" if pos.z > 4.0 and pos.x > -25.0 and pos.x < -13.0 else "Place Prosper-Goubaux"
	if pos.z < HALL_Z1 and pos.y < HALL_C and pos.x < HALL_X1 + 0.5 and pos.x > HALL_X0 - 0.5:
		return "Escalier · Villiers" if pos.z < HALL_Z0 or pos.y > CY + 0.3 else "Salle des billets · Villiers"
	if pos.z < TUBE_Z0 and pos.y > PY + 0.2 and absf(pos.x - TUBE_X) < 2.0:
		return "Escalier · Villiers"
	var local3 := LINE3.affine_inverse() * pos
	if local3.z > _boucle_wall_z() - 0.3 and local3.y < PY + 3.0:
		return "Boucle désaffectée · Villiers"
	if local3.z > ZB and local3.y < PY + 3.0 and local3.x > SERV.x - 0.5 and local3.x < SERV.y + 0.5:
		return "Couloir de service · Villiers"
	if local3.z > L3_KIOSK.z - 0.8 and local3.x > L3_KIOSK.x - 1.3 and local3.x < L3_KIOSK.x + 1.3 and local3.y < PY + 3.0:
		return "Local technique · Villiers"
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
	# au-dessus de chaque escalier : l'autre quai de la ligne 2 et les deux directions de la ligne 3
	var line3 := [["ligne3", "Pont de Levallois"], ["ligne3", "Gallieni"]]
	var a_sign := _sign([["ligne", "Nation"]] + line3)
	var b_sign := _sign([["ligne", "Pte Dauphine"]] + line3 + [["sortie", "Sortie"]])
	for well in [[ZA + u.w / 2, a_sign, 3], [ZB - u.w / 2, b_sign, 4]]:
		var zc: float = well[0]
		var rows: int = well[2]
		var h := 0.2 * rows   # panneau de 1,2 m de large, 0,2 m par rangée
		for r in [PI / 2, -PI / 2]:
			plane(well[1], 1.2, h, u.x0 - 0.4 + (0.03 if r > 0 else -0.03), -4.1 - h / 2, zc, r)
		box(M.fonteDark, 0.04, h + 0.02, 1.22, u.x0 - 0.4, -4.1 - h / 2, zc)
		box(M.inox, 0.03, 0.6, 0.03, u.x0 - 0.4, -3.8, zc)
	# en bas, de part et d'autre de l'entrée du couloir : vers la ligne 3
	var to_line3 := _sign(line3)
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
	# au fond, l'escalier vers la salle des billets : on bouche le haut de l'arc au-dessus
	var over := PackedVector2Array([Vector2(-TUBE_HW, TUBE_SPRING)])
	for i in range(1, 12):
		var a := PI - PI * i / 12
		over.append(Vector2(TUBE_HW * cos(a), TUBE_SPRING + (TUBE_TOP - TUBE_SPRING) * sin(a)))
	over.append_array([Vector2(TUBE_HW, TUBE_SPRING), Vector2(TUBE_HW, TUBE_TOP), Vector2(-TUBE_HW, TUBE_TOP)])
	add(PsxGeo.polygon(over, 1 / TW, 1 / TH), M.carreau, Vector3(TUBE_X, 0, TUBE_Z0))
	var exit_sign := _sign([["sortie", "Sortie"]])
	for r in [0.0, PI]:
		plane(exit_sign, 1.2, 0.2, TUBE_X, TUBE_TOP - 0.25, TUBE_Z0 + 0.6 + (0.02 if r == 0.0 else -0.02), r)
	box(M.fonteDark, 1.22, 0.22, 0.03, TUBE_X, TUBE_TOP - 0.25, TUBE_Z0 + 0.6)
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
	# le mur du quai B est percé derrière le local technique, vers le couloir de service
	for run in [[X0, SERV.x], [SERV.y, X1]]:
		var length: float = run[1] - run[0]
		plane(M.carreau, length, WT - PY, (run[0] + run[1]) / 2, (PY + WT) / 2, ZB, 0, length / TW, (WT - PY) / TH)
	plane(M.carreau, SERV.y - SERV.x, WT - PY - SERV_H, (SERV.x + SERV.y) / 2, (PY + SERV_H + WT) / 2, ZB, 0, 1, 1)
	for run in [[X0, -L3_DOOR, ZA + 0.01], [L3_DOOR, X1, ZA + 0.01], [X0, L3_KIOSK.x - 1.3, ZB - 0.01], [L3_KIOSK.x + 1.3, X1, ZB - 0.01]]:
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
	# à côté de l'arrivée du couloir : vers la ligne 2 et la sortie
	var back := _sign([["ligne", "Pte Dauphine"], ["ligne", "Nation"], ["sortie", "Sortie"]])
	plane(back, 1.2, 0.6, -L3_DOOR - 1.0, PY + 1.9, ZA + 0.03, 0)
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

	_build_kiosk3()


## Collisions du quai de la ligne 3 ; renvoie les garde-fous des deux voies.
func _line3_colliders() -> Array[CollisionShape3D]:
	var barriers: Array[CollisionShape3D] = []
	var door_top: float = PY + (_underpass_spring(_underpass()) - _underpass().floor)
	for quai in [[ZA, ZT0, 1.0], [ZB, ZT1, -1.0]]:
		var zw: float = quai[0]
		var ze: float = quai[1]
		var inward: float = quai[2]
		_solid(Vector3(L, 0.2, absf(ze - zw)), Vector3(0, PY - 0.1, (zw + ze) / 2))
		var runs := [[X0, -L3_DOOR], [L3_DOOR, X1]] if zw == ZA else [[X0, SERV.x], [SERV.y, X1]]
		for r in runs:
			_solid(Vector3(r[1] - r[0], WT - PY, 0.2), Vector3((r[0] + r[1]) / 2, (PY + WT) / 2, zw - inward * 0.1))
		barriers.append(_platform_end_colliders(zw, ze, inward))
	_solid(Vector3(2 * L3_DOOR, WT - door_top, 0.2), Vector3(0, (door_top + WT) / 2, ZA - 0.1))
	_solid(Vector3(SERV.y - SERV.x, WT - PY - SERV_H, 0.2), Vector3((SERV.x + SERV.y) / 2, (PY + SERV_H + WT) / 2, ZB + 0.1))
	return barriers


# --- Le local technique et le couloir de service (repère LINE3) -----------------

var local_door: Node3D
var local_door_item: Examinable
## Porte du local ouverte : l'agent de sécurité l'ouvre au chapitre 2 (voir Chapitre2Jeu).
var local_open := false


func _build_kiosk3() -> void:
	var k := L3_KIOSK
	var x0 := k.x - 1.3
	var x1 := k.x + 1.3
	var z0 := k.z - 0.8
	var h := 2.6
	var tile := _mat("carreau_blanc")
	# façade percée de la porte, côtés, toit ; le fond est le mur du quai, percé vers le couloir
	for run in [[x0, KIOSK_DOOR.x], [KIOSK_DOOR.y, x1]]:
		box(tile, run[1] - run[0], h, 0.08, (run[0] + run[1]) / 2, PY + h / 2, z0, (run[1] - run[0]) / TW, h / TH)
	box(tile, KIOSK_DOOR.y - KIOSK_DOOR.x, h - 2.05, 0.08, (KIOSK_DOOR.x + KIOSK_DOOR.y) / 2, PY + 2.05 + (h - 2.05) / 2, z0, 1, 1)
	for x in [x0, x1]:
		box(tile, 0.08, h, ZB - z0, x, PY + h / 2, (z0 + ZB) / 2, (ZB - z0) / TW, h / TH)
	box(_mat("blanc", 0xe6e5e0), x1 - x0 + 0.1, 0.08, ZB - z0 + 0.1, k.x, PY + h + 0.04, (z0 + ZB) / 2)
	rect(_mat("blanc", 0xd8d6d0), x0, z0, x1, ZB, PY + h - 0.01, 2.0, PI / 2)
	box(_mat("blanc", 0x6a6e72), 0.5, 0.25, 0.03, k.x + 0.85, PY + 1.6, z0 - 0.05)   # grille d'aération
	plane(M.alarme, 1.0, 0.25, k.x, PY + 2.9, z0, PI)
	# dedans : armoire électrique, ventilateur, néon
	box(_mat("blanc", 0x8a8f86), 0.5, 1.9, 0.9, x1 - 0.3, PY + 0.95, (z0 + ZB) / 2)
	box(M.noir, 0.02, 0.3, 0.3, x1 - 0.56, PY + 1.4, (z0 + ZB) / 2)
	box(M.neon, 0.8, 0.04, 0.1, k.x, PY + h - 0.05, (z0 + ZB) / 2)
	_solid(Vector3(0.5, 1.9, 0.9), Vector3(x1 - 0.3, PY + 0.95, (z0 + ZB) / 2))
	# le planning des trains de travaux, punaisé au mur du fond (à l'abri du battant ouvert)
	var sheet := Vector3((x0 + SERV.x) / 2, PY + 1.5, ZB - 0.03)
	box(_mat("blanc", 0xf2efe6), 0.3, 0.42, 0.01, sheet.x, sheet.y, sheet.z)
	for line in 5:
		box(M.noir, 0.22, 0.012, 0.012, sheet.x, sheet.y + 0.12 - line * 0.06, sheet.z - 0.01)
	var planning := Examinable.new()
	planning.title = "Planning affiché"
	planning.description = "Une feuille punaisée : « Trains de travaux · voie de garage de Villiers · mardi et vendredi, 1 h 30 – 4 h ». Signée « M. D. »."
	planning.evidence_id = "planning_travaux"
	planning.photo_range = 2.0
	_place(planning, sheet + Vector3(0, 0, -0.04))
	_examinable_shape(planning, Vector3(0.35, 0.45, 0.1))
	add_child(planning)
	for run in [[x0, KIOSK_DOOR.x], [KIOSK_DOOR.y, x1]]:
		_solid(Vector3(run[1] - run[0], h, 0.1), Vector3((run[0] + run[1]) / 2, PY + h / 2, z0))
	for x in [x0, x1]:
		_solid(Vector3(0.1, h, ZB - z0), Vector3(x, PY + h / 2, (z0 + ZB) / 2))

	# porte grise sur charnière
	var hinge := Vector3(KIOSK_DOOR.x, PY, z0 - 0.02)
	var w := KIOSK_DOOR.y - KIOSK_DOOR.x
	local_door = Node3D.new()
	add_child(local_door)
	var leaf := PsxBuilder.new()
	leaf.add(PsxGeo.box(w, 2.05, 0.04), _mat("blanc", 0x8e9296), PsxGeo.xf(Vector3(w / 2, 1.025, 0)))
	leaf.add(PsxGeo.box(0.1, 0.04, 0.06), M.inox, PsxGeo.xf(Vector3(w - 0.12, 1.0, -0.04)))
	leaf.build(local_door)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(w, 2.05, 0.04)
	shape.position = Vector3(w / 2, 1.025, 0)
	body.add_child(shape)
	local_door.add_child(body)
	local_door_item = Examinable.new()
	local_door_item.title = "Local technique"
	_examinable_shape(local_door_item, Vector3(0.9, 2.05, 0.1))
	add_child(local_door_item)
	_local_hinge = hinge
	set_local_open(local_open)

	# couloir de service, brut, jusqu'à la boucle
	var zf := _boucle_wall_z()
	rect(M.sol, SERV.x, ZB, SERV.y, zf, PY, 2.4)
	rect(M.platre, SERV.x, ZB, SERV.y, zf, PY + SERV_H, 2.0, PI / 2)
	for x in [SERV.x, SERV.y]:
		plane(M.tunnel, zf - ZB, SERV_H, x, PY + SERV_H / 2, (ZB + zf) / 2, PI / 2, (zf - ZB) / 2.4, 1)
		_solid(Vector3(0.2, SERV_H, zf - ZB), Vector3(x + (-0.1 if x == SERV.x else 0.1), PY + SERV_H / 2, (ZB + zf) / 2))
	box(M.neon, 0.06, 0.06, 0.3, (SERV.x + SERV.y) / 2, PY + SERV_H - 0.05, (ZB + zf) / 2)
	_solid(Vector3(SERV.y - SERV.x, 0.2, zf - ZB), Vector3((SERV.x + SERV.y) / 2, PY - 0.1, (ZB + zf) / 2))


var _local_hinge := Vector3.ZERO


func set_local_open(on: bool) -> void:
	local_open = on
	local_door.transform = LINE3 * Transform3D(Basis(Vector3.UP, deg_to_rad(-100.0) if on else 0.0), _local_hinge)
	# l'examen suit le battant (sinon il boucherait l'entrée)
	local_door_item.transform = local_door.transform * Transform3D(Basis(), Vector3((KIOSK_DOOR.y - KIOSK_DOOR.x) / 2, 1.025, -0.06))
	local_door_item.description = ("La porte grise est entrouverte, la serrure de sécurité forcée. Au fond du local, un passage s'ouvre dans le mur." if on
		else "Porte grise à serrure de sécurité. Une étiquette : « Local technique – accès réservé au personnel RATP ». Derrière, on entend souffler une ventilation.")


# --- La boucle désaffectée (repère LINE3) ---------------------------------------
# D'après la photo de freeside510 (Wikimedia Commons, CC BY 2.0, voir CREDITS.md) : tunnel
# voûté en courbe, une voie, une banquette le long du mur extérieur éclairée par quelques
# lampes, et de vieilles voitures Sprague garées là, couvertes de tags.

## Point de la courbe à l'angle `a`, décalé de `r` vers l'extérieur (x, z locaux).
static func _boucle_point(a: float, r: float) -> Vector2:
	return BOUCLE_C + (BOUCLE_R + r) * Vector2(cos(a), sin(a))


## z local du mur extérieur de la boucle, là où débouche le couloir de service.
static func _boucle_wall_z() -> float:
	return BOUCLE_C.y - (BOUCLE_R + BOUCLE_WALK.y)


## Angles des tronçons de la courbe ; l'ouverture du couloir tombe entre deux tronçons.
static func _boucle_angles() -> Array[float]:
	var half := ((SERV.y - SERV.x) / 2) / (BOUCLE_R + BOUCLE_WALK.y)
	var mid := -PI / 2
	var out: Array[float] = []
	var n := 14
	for i in n + 1:
		out.append(lerpf(BOUCLE_A.x, mid - half, float(i) / n))
	for i in n + 1:
		out.append(lerpf(mid + half, BOUCLE_A.y, float(i) / n))
	return out


## Profil du tunnel (r vers l'extérieur, y) : mur intérieur, voûte, mur extérieur, banquette.
static func _boucle_profile() -> Array:
	var p := [Vector2(-2.0, RY), Vector2(-2.0, BOUCLE_SPRING)]
	for i in range(1, 10):
		var t := PI * i / 10
		p.append(Vector2(0.3 - 2.3 * cos(t), BOUCLE_SPRING + 1.3 * sin(t)))
	p.append_array([Vector2(BOUCLE_WALK.y, BOUCLE_SPRING), Vector2(BOUCLE_WALK.y, PY), Vector2(BOUCLE_WALK.x, PY), Vector2(BOUCLE_WALK.x, RY)])
	return p


## Lampes de la banquette, et une dans la voiture ouverte (repère local).
func _boucle_lamps() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for deg in [-112.0, -97.0, -80.0, -66.0]:
		var q := _boucle_point(deg_to_rad(deg), BOUCLE_WALK.y - 0.15)
		out.append(Vector3(q.x, PY + 2.0, q.y))
	var c := _boucle_point(-PI / 2, -0.3)
	out.append(Vector3(c.x, PY + 1.8, c.y))
	out.append(Vector3((SERV.x + SERV.y) / 2, PY + 2.0, (ZB + _boucle_wall_z()) / 2))   # couloir de service
	return out


func _build_boucle() -> void:
	var angles := _boucle_angles()
	var prof := _boucle_profile()
	var outer := prof.size() - 4   # indice du segment du mur extérieur (de la naissance à la banquette)
	var g := PsxGeo.empty()
	for k in angles.size() - 1:
		if is_equal_approx(angles[k], angles[k + 1]):
			continue
		var opening := angles[k] < -PI / 2 and angles[k + 1] > -PI / 2
		var acc := 0.0
		for i in prof.size() - 1:
			var seg_len: float = prof[i].distance_to(prof[i + 1])
			if not (opening and i == outer):
				var base: int = g.p.size()
				for corner in [[k, i], [k + 1, i], [k, i + 1], [k + 1, i + 1]]:
					var a: float = angles[corner[0]]
					var pr: Vector2 = prof[corner[1]]
					var q := _boucle_point(a, pr.x)
					var d: Vector2 = prof[i + 1] - prof[i]
					g.p.append(Vector3(q.x, pr.y, q.y))
					g.n.append((Vector3(cos(a), 0, sin(a)) * d.y - Vector3.UP * d.x).normalized())   # vers l'intérieur du tunnel
					g.uv.append(Vector2(a * BOUCLE_R / 2.4, (acc + (seg_len if corner[1] == i + 1 else 0.0)) / 1.2))
				g.i.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
			acc += seg_len
		# ballast et rails
		var a0 := angles[k]
		var a1 := angles[k + 1]
		var ballast := PsxGeo.empty()
		for corner in [[a0, -2.0], [a1, -2.0], [a0, BOUCLE_WALK.x], [a1, BOUCLE_WALK.x]]:
			var q := _boucle_point(corner[0], corner[1])
			ballast.p.append(Vector3(q.x, RY, q.y))
			ballast.n.append(Vector3.UP)
			ballast.uv.append(Vector2(corner[0] * BOUCLE_R / 1.2, corner[1] / 1.2))
		ballast.i.append_array([0, 1, 2, 1, 3, 2])
		add(ballast, M.voie, Vector3.ZERO)
		for r in [-0.72, 0.72]:
			var p0 := _boucle_point(a0, r)
			var p1 := _boucle_point(a1, r)
			var mid := (p0 + p1) / 2
			add(PsxGeo.box(p0.distance_to(p1) + 0.02, 0.14, 0.08), M.rail, Vector3(mid.x, RY + 0.07, mid.y),
				Vector3(0, atan2(-(p1.y - p0.y), p1.x - p0.x), 0))
		# collisions : banquette, mur extérieur, garde-fou invisible au bord de la banquette
		var w0 := _boucle_point(a0, (BOUCLE_WALK.x + BOUCLE_WALK.y) / 2)
		var w1 := _boucle_point(a1, (BOUCLE_WALK.x + BOUCLE_WALK.y) / 2)
		var yaw := atan2(-(w1.y - w0.y), w1.x - w0.x)
		var length := w0.distance_to(w1) + 0.05
		var wm := (w0 + w1) / 2
		_solid(Vector3(length, 0.2, BOUCLE_WALK.y - BOUCLE_WALK.x + 0.1), Vector3(wm.x, PY - 0.1, wm.y), Vector3(0, yaw, 0))
		if not opening:
			var o := (_boucle_point(a0, BOUCLE_WALK.y + 0.1) + _boucle_point(a1, BOUCLE_WALK.y + 0.1)) / 2
			_solid(Vector3(length, SERV_H, 0.2), Vector3(o.x, PY + SERV_H / 2, o.y), Vector3(0, yaw, 0))
		var e := (_boucle_point(a0, BOUCLE_WALK.x - 0.05) + _boucle_point(a1, BOUCLE_WALK.x - 0.05)) / 2
		var in_door := absf((a0 + a1) / 2 + PI / 2) * BOUCLE_R < 0.6
		if not in_door:
			_solid(Vector3(length, 2.0, 0.05), Vector3(e.x, PY + 1.0, e.y), Vector3(0, yaw, 0))
	add(g, M.tunnel, Vector3.ZERO)
	# aux deux bouts : le noir, et on ne passe pas
	for a in [BOUCLE_A.x, BOUCLE_A.y]:
		var c := _boucle_point(a, 0.3)
		var t := Vector2(-sin(a), cos(a))
		add(PsxGeo.plane(5.0, 5.0), M.noir, Vector3(c.x, (RY + BOUCLE_SPRING + 1.3) / 2, c.y), Vector3(0, atan2(-t.y, t.x) + PI / 2, 0))
		var b := _boucle_point(a, (BOUCLE_WALK.x + BOUCLE_WALK.y) / 2)
		_solid(Vector3(0.2, 2.5, 1.4), Vector3(b.x, PY + 1.25, b.y), Vector3(0, atan2(-t.y, t.x), 0))
	# lampes de la banquette
	for p in _boucle_lamps().slice(0, 4):   # (les deux dernières : la voiture et le couloir)
		box(M.neon, 0.12, 0.12, 0.12, p.x, p.y, p.z)
	_build_spragues()


## Trois voitures Sprague garées sur la courbe ; celle du milieu, face au couloir, est ouverte.
func _build_spragues() -> void:
	var side := _mat("sprague_cote")
	var body := _mat("blanc", 0x24302a)
	var under := _mat("blanc", 0x16181a)
	var roof := _mat("blanc", 0x3a3e3c)
	var inside := _mat("blanc", 0x3a2e24)
	var step := SPRAGUE_LEN / BOUCLE_R + 0.02
	for c in [-1, 0, 1]:
		var a: float = -PI / 2 + c * step
		# l'axe de la voiture est la corde : son milieu est un peu à l'intérieur de la courbe
		var sag := SPRAGUE_LEN * SPRAGUE_LEN / (8.0 * BOUCLE_R)
		var q := _boucle_point(a, -sag / 2)
		var t := Vector3(-sin(a), 0, cos(a))
		var xf := Transform3D(Basis(t, Vector3.UP, t.cross(Vector3.UP)), Vector3(q.x, RY, q.y))
		# repère de la voiture : x le long de la voie, z vers l'intérieur de la courbe (banquette en -z)
		var floor_y := PY - RY   # plancher au niveau de la banquette
		add_xf(PsxGeo.box(SPRAGUE_LEN - 0.6, 0.7, 2.0), under, xf * PsxGeo.xf(Vector3(0, 0.45, 0)))
		add_xf(PsxGeo.box(SPRAGUE_LEN, 0.25, 2.2), roof, xf * PsxGeo.xf(Vector3(0, floor_y + 2.42, 0)))
		for e in [-1.0, 1.0]:
			add_xf(PsxGeo.box(0.06, 2.3, 2.4), body, xf * PsxGeo.xf(Vector3(e * SPRAGUE_LEN / 2, floor_y + 1.15, 0)))
		var h := 2.3
		if c != 0:
			add_xf(PsxGeo.box(SPRAGUE_LEN - 0.1, h - 0.02, 2.36), body, xf * PsxGeo.xf(Vector3(0, floor_y + h / 2, 0)))
			for zs in [-1.0, 1.0]:
				add_xf(PsxGeo.plane(SPRAGUE_LEN, h), side, xf * PsxGeo.xf(Vector3(0, floor_y + h / 2, zs * 1.2), Vector3(0, 0 if zs > 0 else PI, 0)))
			_solid_xf(Vector3(SPRAGUE_LEN, h, 2.4), xf * PsxGeo.xf(Vector3(0, floor_y + h / 2, 0)))
			continue
		# la voiture ouverte : porte du milieu ouverte côté banquette, caisses à l'intérieur
		var door := 0.65
		var u_door := Vector2(0.5 - door / SPRAGUE_LEN, 0.5 + door / SPRAGUE_LEN)
		_quad_xf(side, xf, -SPRAGUE_LEN / 2, -door, floor_y, floor_y + h, -1.2, Vector2(0.0, u_door.x), Vector2(0, 1))
		_quad_xf(side, xf, door, SPRAGUE_LEN / 2, floor_y, floor_y + h, -1.2, Vector2(u_door.y, 1.0), Vector2(0, 1))
		_quad_xf(side, xf, -door, door, floor_y + 2.0, floor_y + h, -1.2, u_door, Vector2(0.87, 1))
		_quad_xf(side, xf, -SPRAGUE_LEN / 2, SPRAGUE_LEN / 2, floor_y, floor_y + h, 1.2, Vector2(0, 1), Vector2(0, 1))
		add_xf(PsxGeo.uv_scale(PsxGeo.plane(SPRAGUE_LEN, 2.36, 6, 1), 6, 1), inside, xf * PsxGeo.xf(Vector3(0, floor_y + 0.005, 0), Vector3(-PI / 2, 0, 0)))
		add_xf(PsxGeo.plane(SPRAGUE_LEN, 2.36), inside, xf * PsxGeo.xf(Vector3(0, floor_y + h - 0.01, 0), Vector3(PI / 2, 0, 0)))
		# caisses en bois
		var wood := _mat("blanc", 0x8a6a3a)
		var wood_dark := _mat("blanc", 0x6a5030)
		for crate in [[1.6, 0.0, 0.8, 0.7, 0.6, wood], [2.6, 0.3, 0.7, 0.6, 0.6, wood_dark], [2.1, 0.0, 0.6, 0.5, 0.5, wood_dark], [-2.4, 0.4, 0.9, 0.8, 0.5, wood]]:
			add_xf(PsxGeo.box(crate[2], crate[3], crate[4]), crate[5], xf * PsxGeo.xf(Vector3(crate[0], floor_y + crate[3] / 2, crate[1])))
			_solid_xf(Vector3(crate[2], crate[3], crate[4]), xf * PsxGeo.xf(Vector3(crate[0], floor_y + crate[3] / 2, crate[1])))
		var label := Examinable.new()
		label.title = "Caisse en bois"
		label.evidence_id = "caisse"
		label.description = "Une caisse neuve, couvercle cloué, au milieu de la poussière. « Fragile – Objets d'art ». Par une fente, une statuette de bronze dans du papier bulle. Étiquette d'expédition : Antiquités Marchetti, rue Frochot, Paris 9e."
		label.transform = LINE3 * xf * PsxGeo.xf(Vector3(1.6, floor_y + 0.35, 0))
		_examinable_shape(label, Vector3(0.85, 0.75, 0.65))
		add_child(label)
		# collisions de la voiture ouverte : plancher, flancs, bouts
		_solid_xf(Vector3(SPRAGUE_LEN, 0.2, 2.4), xf * PsxGeo.xf(Vector3(0, floor_y - 0.1, 0)))
		_solid_xf(Vector3(SPRAGUE_LEN, h, 0.1), xf * PsxGeo.xf(Vector3(0, floor_y + h / 2, 1.2)))
		for run in [[-SPRAGUE_LEN / 2, -door], [door, SPRAGUE_LEN / 2]]:
			_solid_xf(Vector3(run[1] - run[0], h, 0.1), xf * PsxGeo.xf(Vector3((run[0] + run[1]) / 2, floor_y + h / 2, -1.2)))
		for e in [-1.0, 1.0]:
			_solid_xf(Vector3(0.1, h, 2.4), xf * PsxGeo.xf(Vector3(e * SPRAGUE_LEN / 2, floor_y + h / 2, 0)))


## Quadrilatère vertical texturé dans le repère `xf` : de x0 à x1, de y0 à y1, en z ; u et v
## choisissent la portion de texture (pour percer une porte dans un flanc).
func _quad_xf(m: Material, xf: Transform3D, x0: float, x1: float, y0: float, y1: float, z: float, u: Vector2, v: Vector2) -> void:
	var g := PsxGeo.empty()
	for corner in [[x0, y0, u.x, v.x], [x1, y0, u.y, v.x], [x0, y1, u.x, v.y], [x1, y1, u.y, v.y]]:
		g.p.append(Vector3(corner[0], corner[1], z))
		g.n.append(Vector3.BACK)
		g.uv.append(Vector2(corner[2], corner[3]))
	g.i.append_array([0, 1, 2, 1, 3, 2])
	add_xf(g, m, xf)


## Boîte de collision placée par une transformation du repère de construction courant.
func _solid_xf(size: Vector3, xf: Transform3D) -> void:
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.transform = _frame * xf
	_collisions.add_child(shape)


# --- Salle des billets ---------------------------------------------------------
# Sans photo de la salle de Villiers : une salle rénovée ordinaire, carreaux blancs et bande
# bleu clair comme sur les quais, plafond blanc à néons, la ligne de contrôle (comme à
# Monceau), le guichet « Services » et deux automates.

func _build_hall() -> void:
	var w := HALL_X1 - HALL_X0
	var d := HALL_Z1 - HALL_Z0
	var h := HALL_C - CY
	var xm := (HALL_X0 + HALL_X1) / 2
	var zm := (HALL_Z0 + HALL_Z1) / 2
	rect(_mat("sol_goudron", 0xc8c8c8), HALL_X0, HALL_Z0, HALL_X1, HALL_Z1, CY, 2.4)
	rect(M.platre, HALL_X0, HALL_Z0, HALL_X1, HALL_Z1, HALL_C, 2.0, PI / 2)
	for x in [HALL_X0, HALL_X1]:
		var ry := PI / 2 if x == HALL_X0 else -PI / 2
		plane(M.carreau, d, h, x, (CY + HALL_C) / 2, zm, ry, d / TW, h / TH)
		plane(M.carreau_bleu, d, 0.25, x + (0.01 if x == HALL_X0 else -0.01), CY + 0.125, zm, ry, d / 0.6, 1)
	# murs du fond, percés : escalier du couloir (côté quais), escalier et escalator (côté rue)
	for wall in [[HALL_Z1, [[HALL_X0, TUBE_X - TUBE_HW], [TUBE_X + TUBE_HW, HALL_X1]], PI],
			[HALL_Z0, [[HALL_X0, TREMIE.x], [TREMIE.y, HALL_X1]], 0.0]]:
		for run in wall[1]:
			var length: float = run[1] - run[0]
			plane(M.carreau, length, h, (run[0] + run[1]) / 2, (CY + HALL_C) / 2, wall[0], wall[2], length / TW, h / TH)
			plane(M.carreau_bleu, length, 0.25, (run[0] + run[1]) / 2, CY + 0.125, wall[0] + (0.01 if wall[2] == 0.0 else -0.01), wall[2], length / 0.6, 1)
	for x in [-21.0, -17.0]:
		for z in [-2.0, 0.8, 4.4]:
			box(M.neon, 1.2, 0.04, 0.3, x, HALL_C - 0.02, z)
	_build_gate_row(HALL_X0, HALL_X1, GATE_Z, CY)

	# guichet « Services » dans le mur est : vitre, tablette, bandeau ; la loge derrière
	var white := _mat("blanc", 0xe6e5e0)
	var services := _sign_from_texture(Panneaux.band(self, "i", "Services"))
	var tickets := _sign_from_texture(Panneaux.band(self, "T", "Tickets"))
	for m in [services, tickets]:
		m.set_shader_parameter("emission", Vector3(0.8, 0.8, 0.8))
	box(_mat("blanc", 0x1a2228, false, true), 0.04, 1.0, 2.2, HALL_X1 - 0.02, CY + 1.6, -1.2)   # vitre sombre
	box(_mat("blanc", 0xd8c890, false, true), 0.02, 0.4, 0.6, HALL_X1 - 0.04, CY + 1.7, -1.6)  # lampe de la loge
	box(white, 0.3, 0.05, 2.2, HALL_X1 - 0.15, CY + 1.08, -1.2)
	box(_mat("blanc", 0x2e2f31), 0.12, 1.05, 2.4, HALL_X1 - 0.06, CY + 0.52, -1.2)
	plane(services, 2.2, 0.24, HALL_X1 - 0.04, CY + 2.3, -1.2, -PI / 2)
	_solid(Vector3(0.4, 1.05, 2.4), Vector3(HALL_X1 - 0.2, CY + 0.52, -1.2))
	# deux automates contre le mur ouest
	for z in [-2.6, -1.6]:
		box(_mat("blanc", 0xd8d8d4), 0.45, 1.7, 0.7, HALL_X0 + 0.24, CY + 0.85, z)
		box(M.noir, 0.02, 0.3, 0.4, HALL_X0 + 0.47, CY + 1.25, z)
		box(_mat("blanc", 0x7a3aa8), 0.02, 0.35, 0.3, HALL_X0 + 0.47, CY + 0.6, z)
		_solid(Vector3(0.45, 1.7, 0.7), Vector3(HALL_X0 + 0.24, CY + 0.85, z))
	plane(tickets, 1.6, 0.24, HALL_X0 + 0.04, CY + 2.3, -2.1, PI / 2)
	for m in [M.plan_reseau]:
		box(M.inox, 0.05, 1.3, 1.3, HALL_X0 + 0.03, CY + 1.4, 0.6)
		plane(m, 1.2, 1.2, HALL_X0 + 0.07, CY + 1.4, 0.6, PI / 2)
	# panneaux suspendus : vers les quais et vers la sortie
	var to_quais := _sign([["ligne", "Pte Dauphine"], ["ligne", "Nation"], ["ligne3", "Pont de Levallois"], ["ligne3", "Gallieni"]])
	var out := _sign([["sortie", "Place Prosper-Goubaux"]])
	for r in [0.0, PI]:   # lisibles des deux côtés
		var o := -0.05 if r == PI else 0.05   # assez loin du support : les sommets tremblent
		plane(to_quais, 1.2, 0.8, -18.5, HALL_C - 0.45, GATE_Z - 0.9 + o, r)
		plane(out, 1.2, 0.2, -19.8, HALL_C - 0.2, HALL_Z0 + 1.0 + o, r)
	box(M.fonteDark, 1.22, 0.82, 0.02, -18.5, HALL_C - 0.45, GATE_Z - 0.9)
	box(M.fonteDark, 1.22, 0.22, 0.02, -19.8, HALL_C - 0.2, HALL_Z0 + 1.0)
	_line_plan("Villiers", "Porte Dauphine", Vector3(HALL_X1 - 0.03, CY + 1.4, 4.4), -PI / 2)

	# escalier du couloir en tube (de z = 12 au quai, à z = 6 dans la salle)
	var n := 12
	var rise := (CY - PY) / n
	var run := (TUBE_Z0 - HALL_Z1) / n
	for i in n:
		var top := PY + (i + 1) * rise
		var z := TUBE_Z0 - (i + 0.5) * run
		box(M.marche, 2 * TUBE_HW, top - PY + 0.3, run, TUBE_X, (top + PY - 0.3) / 2, z, 2, 1)
		box(M.inox, 2 * TUBE_HW, 0.02, 0.05, TUBE_X, top + 0.01, z - run / 2 + 0.025)
	var wall := PackedVector2Array([Vector2(TUBE_Z0, PY), Vector2(HALL_Z1, CY), Vector2(HALL_Z1, HALL_C), Vector2(TUBE_Z0, TUBE_TOP)])
	for sx in [-1.0, 1.0]:
		add(PsxGeo.polygon(wall, 1 / TW, 1 / TH), M.carreau, Vector3(TUBE_X + sx * TUBE_HW, 0, 0), Vector3(0, -PI / 2, 0))
	_ceiling_quad(TUBE_X - TUBE_HW, TUBE_X + TUBE_HW, TUBE_Z0, TUBE_TOP, HALL_Z1, HALL_C)
	add(PsxGeo.box(0.04, 0.04, Vector2(TUBE_Z0 - HALL_Z1, CY - PY).length()), M.candPost,
		Vector3(TUBE_X + TUBE_HW - 0.06, (PY + CY) / 2 + 0.9, (TUBE_Z0 + HALL_Z1) / 2), Vector3(atan2(CY - PY, TUBE_Z0 - HALL_Z1), 0, 0))

	# escalier et escalator de sortie (de la salle, z = -4, à la place, z = -10)
	var sx0 := TUBE_X - TUBE_HW
	var sx1 := TUBE_X + TUBE_HW
	run = (HALL_Z0 - EXIT_Z) / n
	rise = -CY / n
	for i in n:
		var top := CY + (i + 1) * rise
		var z := HALL_Z0 - (i + 0.5) * run
		box(M.marche, sx1 - sx0, top - CY + 0.3, run, TUBE_X, (top + CY - 0.3) / 2, z, 2, 1)
		box(M.inox, sx1 - sx0, 0.02, 0.05, TUBE_X, top + 0.01, z - run / 2 + 0.025)
	# l'escalator, à l'arrêt la nuit : tablier strié, flancs inox, main courante noire
	var slope := atan2(-CY, HALL_Z0 - EXIT_Z)
	var length := Vector2(HALL_Z0 - EXIT_Z, -CY).length()
	var ex := (ESC.x + ESC.y) / 2
	var center := Vector3(ex, CY / 2, (HALL_Z0 + EXIT_Z) / 2)
	add(PsxGeo.box(ESC.y - ESC.x, 0.05, length), _mat("blanc", 0x3a3c3e), center, Vector3(slope, 0, 0))
	for i in int(length / 0.4):
		var t := (i + 0.5) / int(length / 0.4)
		add(PsxGeo.box(ESC.y - ESC.x - 0.1, 0.02, 0.03), M.inox, Vector3(ex, lerpf(CY, 0.0, t) + 0.03, lerpf(HALL_Z0, EXIT_Z, t)), Vector3(slope, 0, 0))
	for bx in [ESC.x - 0.05, ESC.y + 0.05]:
		add(PsxGeo.box(0.1, 0.9, length), M.inox, center + Vector3(bx - ex, 0.45, 0), Vector3(slope, 0, 0))
		add(PsxGeo.box(0.12, 0.08, length), M.noir, center + Vector3(bx - ex, 0.93, 0), Vector3(slope, 0, 0))
	# flancs carrelés de la trémie, du niveau de la place jusqu'à la salle
	var side := PackedVector2Array([Vector2(EXIT_Z, 0.0), Vector2(HALL_Z0, 0.0), Vector2(HALL_Z0, CY)])
	for x in [TREMIE.x, TREMIE.y]:
		add(PsxGeo.polygon(side, 1 / TW, 1 / TH), M.carreau, Vector3(x, 0, 0), Vector3(0, -PI / 2, 0))
	plane(M.carreau, TREMIE.y - TREMIE.x, -HALL_C, (TREMIE.x + TREMIE.y) / 2, HALL_C / 2, HALL_Z0, 0, 3, 1)   # tranche de la dalle

	# collisions de la salle, des escaliers et de l'escalator
	_solid(Vector3(w, 0.2, d), Vector3(xm, CY - 0.1, zm))
	for x in [HALL_X0 - 0.1, HALL_X1 + 0.1]:
		_solid(Vector3(0.2, h, d), Vector3(x, (CY + HALL_C) / 2, zm))
	for wall_z in [[HALL_Z1 + 0.1, TUBE_X - TUBE_HW, TUBE_X + TUBE_HW], [HALL_Z0 - 0.1, TREMIE.x, TREMIE.y]]:
		for run_x in [[HALL_X0, wall_z[1]], [wall_z[2], HALL_X1]]:
			_solid(Vector3(run_x[1] - run_x[0], h, 0.2), Vector3((run_x[0] + run_x[1]) / 2, (CY + HALL_C) / 2, wall_z[0]))
	_ramp(Vector3(TUBE_X, PY, TUBE_Z0), Vector3(TUBE_X, CY, HALL_Z1), 2 * TUBE_HW)
	for sx in [-1.0, 1.0]:
		_solid(Vector3(0.2, 4.0, TUBE_Z0 - HALL_Z1), Vector3(TUBE_X + sx * (TUBE_HW + 0.1), (PY + HALL_C) / 2, (TUBE_Z0 + HALL_Z1) / 2))
	_ramp(Vector3(TUBE_X, CY, HALL_Z0), Vector3(TUBE_X, 0.0, EXIT_Z), sx1 - sx0)
	_ramp(Vector3(ex, CY, HALL_Z0), Vector3(ex, 0.0, EXIT_Z), ESC.y - ESC.x)
	_solid(Vector3(sx0 - ESC.y, 1.2, length), Vector3((ESC.y + sx0) / 2, CY / 2 + 0.6, (HALL_Z0 + EXIT_Z) / 2), Vector3(slope, 0, 0))
	for x in [TREMIE.x - 0.1, TREMIE.y + 0.1]:
		_solid(Vector3(0.2, 4.0, HALL_Z0 - EXIT_Z), Vector3(x, CY / 2, (HALL_Z0 + EXIT_Z) / 2))


## Plafond en pente au-dessus d'une volée de marches, de (z0, y0) à (z1, y1), de x0 à x1.
func _ceiling_quad(x0: float, x1: float, z0: float, y0: float, z1: float, y1: float) -> void:
	var g := PsxGeo.empty()
	for c in [[x0, y0, z0], [x1, y0, z0], [x0, y1, z1], [x1, y1, z1]]:
		g.p.append(Vector3(c[0], c[1], c[2]))
		g.n.append(Vector3.DOWN)
		g.uv.append(Vector2(c[0] / 2.0, c[2] / 2.0))
	g.i.append_array([0, 1, 2, 1, 3, 2])
	add(g, M.platre, Vector3.ZERO)


# --- La place Prosper-Goubaux et la rue de Lévis --------------------------------
# D'après la photo de Chabe01 (Wikimedia Commons, CC BY-SA 4.0, voir CREDITS.md) : l'accès
# s'ouvre sur le trottoir, escalier et escalator côte à côte derrière un garde-corps vert,
# signalé par un mât au « M » jaune dans son anneau ; tout autour, des immeubles
# haussmanniens. Le café qui ferme tard est au début de la rue de Lévis (inventé).

const W0 := Vector2(-62.0, -50.0)   # coin nord-ouest du quartier (x, z)
const W1 := Vector2(32.0, 30.0)     # coin sud-est
const CAFE := Vector3(-25.0, 0, 10.0)   # façade du café, rue de Lévis (x de la façade, z du milieu)
const LAMPS := [Vector2(-30.0, 1.6), Vector2(-15.0, -13.5), Vector2(15.0, -10.0), Vector2(-13.4, 14.0), Vector2(-24.6, 4.6)]
# Au milieu de la place, d'après les photos de Mbzt (CC BY 3.0) et de Chabe01 (CC BY-SA 4.0) :
# un terre-plein planté de platanes, un manège (bâché la nuit) et un grand candélabre à deux
# lanternes ; tout autour, l'asphalte.
const ISLAND := Vector3(-5.0, 0, -9.0)
const ISLAND_R := 6.5
const CANDELABRA := Vector2(-10.6, -9.0)


func _build_street() -> void:
	# sol : trottoirs (devant les immeubles, autour de l'accès, rue de Lévis) et asphalte ;
	# une sous-couche, percée elle aussi par la trémie, bouche les fissures entre les dalles
	var t0 := TREMIE.x
	var t1 := TREMIE.y
	var asphalt := _mat("sol_goudron", 0x7a7a7e)
	for r in [[-25.0, -14.0, t0, 0.0], [t1, -14.0, -14.0, 0.0], [t0, -14.0, t1, EXIT_Z], [t0, HALL_Z0, t1, 0.0],
			[-45.0, 0.0, 2.0, 4.0], [-25.0, 4.0, -13.0, W1.y]]:
		rect(M.trottoir, r[0], r[1], r[2], r[3], 0.0, 3.0)
	for r in [[W0.x, -30.0, W1.x, -18.0], [-45.0, -18.0, -25.0, 0.0], [-25.0, -18.0, -14.0, -14.0], [-14.0, -18.0, 2.0, 0.0], [2.0, -18.0, 14.0, W1.y]]:
		rect(asphalt, r[0], r[1], r[2], r[3], 0.0, 2.4)
	for r in [[W0.x, W0.y, t0, W1.y], [t1, W0.y, W1.x, W1.y], [t0, W0.y, t1, EXIT_Z], [t0, HALL_Z0, t1, W1.y]]:
		rect(M.paves, r[0], r[1], r[2], r[3], -0.1, 2.5)
	rect(M.trottoir, W0.x, -18.0, -45.0, W1.y, 0.0, 3)
	rect(M.trottoir, W0.x, W0.y, W1.x, -30.0, 0.0, 3)
	rect(M.trottoir, 14.0, -18.0, W1.x, W1.y, 0.0, 3)
	_build_island()
	# immeubles
	_block(-45, 4, -25, 30, 18, "a")
	_block(-13, 4, 2, 30, 19, "b")
	_block(-60, -50, -28, -31, 18, "b")
	_block(-24, -50, 10, -31, 18, "a")
	_block(14, -16, 32, 22, 17, "a")
	_block(-62, -16, -46, 2, 17, "b")

	# la trémie : parapet de pierre, garde-corps vert, ouverte du côté de la place (z = -10)
	var green_rail: Material = _mat("balustrade", 0x9fd0a8, true)
	var depth := HALL_Z0 - EXIT_Z
	for x in [t0, t1]:
		box(M.pierre, 0.3, 0.45, depth, x, 0.225, (EXIT_Z + HALL_Z0) / 2, depth, 0.5)
		plane(green_rail, depth, 0.95, x, 0.93, (EXIT_Z + HALL_Z0) / 2, PI / 2, depth * 1.4, 1)
		box(M.fonte, 0.05, 0.05, depth, x, 1.41, (EXIT_Z + HALL_Z0) / 2)
		_solid(Vector3(0.3, 1.5, depth), Vector3(x, 0.75, (EXIT_Z + HALL_Z0) / 2))
	box(M.pierre, t1 - t0, 0.45, 0.3, (t0 + t1) / 2, 0.225, HALL_Z0, 4, 0.5)
	plane(green_rail, t1 - t0, 0.95, (t0 + t1) / 2, 0.93, HALL_Z0, 0, (t1 - t0) * 1.4, 1)
	box(M.fonte, t1 - t0, 0.05, 0.05, (t0 + t1) / 2, 1.41, HALL_Z0)
	_solid(Vector3(t1 - t0, 1.5, 0.3), Vector3((t0 + t1) / 2, 0.75, HALL_Z0))
	# le mât au « M » jaune, à l'angle de la trémie
	var mast := Vector3(t0 - 0.8, 0, EXIT_Z - 0.6)
	add(PsxGeo.cylinder(0.05, 0.07, 3.4, 6), _mat("blanc", 0x8a8e90), mast + Vector3(0, 1.7, 0))
	for r in [0.0, PI / 2]:
		plane(_mat("mat_m", 0xffffff, true), 0.9, 0.9, mast.x, 3.85, mast.z, r)
	_post(0.12, 3.0, mast)

	# le café, au début de la rue de Lévis : vitrine éclairée, store, terrasse
	var warm := _mat("blanc", 0xf2c27a, false, true)
	var c := CAFE
	box(warm, 0.04, 2.4, 6.0, c.x + 0.03, 1.5, c.z)
	var frame := _mat("blanc", 0x3a2418)
	for k in range(-2, 3):   # montants de la vitrine, comptoir et silhouettes derrière
		box(frame, 0.06, 2.4, 0.08, c.x + 0.06, 1.5, c.z + k * 1.2)
	box(_mat("blanc", 0x5a3a24), 0.05, 0.9, 5.6, c.x + 0.05, 0.75, c.z)
	for z in [c.z - 1.6, c.z + 0.9]:
		box(_mat("blanc", 0x2a2220), 0.03, 0.9, 0.45, c.x + 0.055, 1.65, z)
		box(_mat("blanc", 0x2a2220), 0.03, 0.3, 0.3, c.x + 0.055, 2.25, z)
	box(_mat("blanc", 0x3a2418), 0.06, 2.6, 0.12, c.x + 0.05, 1.5, c.z - 3.05)
	box(_mat("blanc", 0x3a2418), 0.06, 2.6, 0.12, c.x + 0.05, 1.5, c.z + 3.05)
	box(_mat("blanc", 0x3a2418), 0.06, 0.12, 6.2, c.x + 0.05, 2.75, c.z)
	add(PsxGeo.uv_scale(PsxGeo.box(1.4, 0.05, 6.4), 1, 6), _mat("toile_rayee"), Vector3(c.x + 0.7, 3.15, c.z), Vector3(0, 0, -0.35))
	plane(_mat("cafe_levis"), 6.4, 0.8, c.x + 1.37, 2.62, c.z, PI / 2, 1, 1)
	for k in 3:
		var tz: float = c.z - 2.0 + k * 2.0
		add(PsxGeo.cylinder(0.3, 0.3, 0.04, 8), _mat("blanc", 0xb8b2a6), Vector3(c.x + 1.9, 0.74, tz))
		add(PsxGeo.cylinder(0.03, 0.03, 0.72, 4), M.fonteDark, Vector3(c.x + 1.9, 0.36, tz))
		for dz in [-0.55, 0.55]:
			box(_mat("blanc", 0x6a4a2a), 0.4, 0.45, 0.4, c.x + 1.9, 0.225, tz + dz)
		_post(0.35, 0.8, Vector3(c.x + 1.9, 0, tz))
	var cafe := Examinable.new()
	cafe.title = "Café Le Lévis"
	cafe.description = "Un café-brasserie encore ouvert, vitrine embuée. Derrière le comptoir, on range les chaises de la terrasse."
	cafe.position = Vector3(c.x + 0.2, 1.5, c.z)
	_examinable_shape(cafe, Vector3(0.3, 2.4, 6.0))
	add_child(cafe)

	# kiosque à journaux fermé, lampadaires, platanes
	box(M.morris, 2.0, 2.2, 1.4, -6.0, 1.1, -14.0)
	box(M.zinc, 2.4, 0.15, 1.8, -6.0, 2.28, -14.0)
	box(_mat("blanc", 0x5a5e58), 1.7, 1.5, 0.03, -6.0, 1.15, -14.73)
	_solid(Vector3(2.0, 2.2, 1.4), Vector3(-6.0, 1.1, -14.0))
	for l in LAMPS:
		add(PsxGeo.cylinder(0.06, 0.1, 4.2, 6), M.fonteDark, Vector3(l.x, 2.1, l.y))
		add(PsxGeo.sphere(0.22, 6, 4), M.lanterne, Vector3(l.x, 4.4, l.y), Vector3.ZERO, Vector3(1, 1.25, 1))
		_post(0.12, 3.0, Vector3(l.x, 0, l.y))
	_tree(-42.0, 2.0, 0)
	_post(0.35, 3.0, Vector3(-42.0, 0, 2.0))

	# collisions : sol percé par la trémie, immeubles, limites du quartier
	_solid(Vector3(t0 - W0.x, 0.9, W1.y - W0.y), Vector3((W0.x + t0) / 2, -0.45, (W0.y + W1.y) / 2))
	_solid(Vector3(W1.x - t1, 0.9, W1.y - W0.y), Vector3((t1 + W1.x) / 2, -0.45, (W0.y + W1.y) / 2))
	_solid(Vector3(t1 - t0, 0.9, EXIT_Z - W0.y), Vector3((t0 + t1) / 2, -0.45, (W0.y + EXIT_Z) / 2))
	_solid(Vector3(t1 - t0, 0.9, W1.y - HALL_Z0), Vector3((t0 + t1) / 2, -0.45, (HALL_Z0 + W1.y) / 2))
	for b in [[-45, 4, -25, 30], [-13, 4, 2, 30], [-60, -50, -28, -31], [-24, -50, 10, -31], [14, -16, 32, 22], [-62, -16, -46, 2]]:
		_solid(Vector3(b[2] - b[0], 20, b[3] - b[1]), Vector3((b[0] + b[2]) / 2.0, 10, (b[1] + b[3]) / 2.0))
	for edge in [[Vector3(0.4, 6, W1.y - W0.y), Vector3(W0.x, 3, (W0.y + W1.y) / 2)], [Vector3(0.4, 6, W1.y - W0.y), Vector3(W1.x, 3, (W0.y + W1.y) / 2)],
			[Vector3(W1.x - W0.x, 6, 0.4), Vector3((W0.x + W1.x) / 2, 3, W0.y)], [Vector3(W1.x - W0.x, 6, 0.4), Vector3((W0.x + W1.x) / 2, 3, W1.y)]]:
		_solid(edge[0], edge[1])


# --- Personnages du chapitre 2 ---------------------------------------------------

func _place_people() -> void:
	var c := CAFE
	var cast := [
		["ines", "Inès, conductrice", {"coat": Color("#2a3a5a"), "pants": Color("#20242c"), "skin": Color("#c89a7a"), "hair": Color("#3a2218")},
			true, Vector3(c.x + 1.9, 0, c.z + 0.6), 0.0],
		["patron", "Le patron du café", {"coat": Color("#e8e2d4"), "pants": Color("#2a2a2c"), "skin": Color("#d0a080"), "hair": Color("#8a8682")},
			false, Vector3(c.x + 1.0, 0, c.z - 3.6), -PI / 2],
		["gpsr", "Agent de sécurité", {"coat": Color("#1c2230"), "pants": Color("#1a1d24"), "skin": Color("#7a5440"), "hair": Color("#151210"), "hat": Color("#1c2230")},
			false, Vector3(HALL_X1 - 1.6, CY, 0.2), PI / 2],
	]
	if not Enquete.check("franck_vu"):
		var q := _boucle_point(deg_to_rad(-75.0), 2.05)
		cast.append(["franck", "Un homme en gilet orange", {"coat": Color("#3a3a36"), "pants": Color("#2a2c30"), "skin": Color("#c09070"),
			"hair": Color("#2a2420"), "vest": Color("#ff7a1a")}, false, LINE3 * Vector3(q.x, PY, q.y), PI])
	for p in cast:
		var person := Personnage.new(p[0], p[1], p[2], p[3])
		person.name = p[0].capitalize()
		person.position = p[4]
		person.rotation.y = p[5]
		add_child(person)
		people[p[0]] = person


## Le chemin de Franck quand il s'enfuit : le long de la banquette, jusqu'au bout de la boucle.
func franck_escape() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for deg in [-68.0, -62.0, -56.0]:
		var q := _boucle_point(deg_to_rad(deg), 2.05)
		out.append(LINE3 * Vector3(q.x, PY, q.y))
	return out


## Le terre-plein du milieu de la place : bordure, platanes, manège bâché, candélabre.
func _build_island() -> void:
	var c := ISLAND
	var outline := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16
		outline.append(Vector2(c.x + ISLAND_R * cos(a), c.z + ISLAND_R * sin(a)))
	add(PsxGeo.polygon(outline, 1 / 3.0, 1 / 3.0), M.trottoir, Vector3(0, 0.02, 0), Vector3(PI / 2, 0, 0))
	add(PsxGeo.uv_scale(PsxGeo.cylinder(ISLAND_R, ISLAND_R, 0.12, 16, 1, true), 20, 0.2), M.pierre, c + Vector3(0, 0.04, 0))
	for i in 5:
		var a := TAU * i / 5 + 0.4
		var p := Vector2(c.x + 4.9 * cos(a), c.z + 4.9 * sin(a))
		_tree(p.x, p.y, i + 1)
		_post(0.35, 3.0, Vector3(p.x, 0, p.y))
	# le manège, bâché pour la nuit
	var wood := _mat("blanc", 0x6a4a30)
	var tarp := _mat("blanc", 0xb8ae96)
	var stripes := _mat("toile_rayee")
	add(PsxGeo.cylinder(3.2, 3.2, 0.45, 12), wood, c + Vector3(0, 0.25, 0))
	add(PsxGeo.uv_scale(PsxGeo.cylinder(3.05, 3.1, 2.5, 12, 1, true), 6, 1), tarp, c + Vector3(0, 1.7, 0))
	add(PsxGeo.uv_scale(PsxGeo.cone(3.7, 1.5, 12), 12, 1), stripes, c + Vector3(0, 3.7, 0))
	add(PsxGeo.uv_scale(PsxGeo.cylinder(3.7, 3.7, 0.35, 12, 1, true), 24, 1), stripes, c + Vector3(0, 2.95, 0))
	add(PsxGeo.sphere(0.2, 6, 4), _mat("blanc", 0xd8b040), c + Vector3(0, 4.6, 0))
	_post(3.3, 3.0, c)
	var carousel := Examinable.new()
	carousel.title = "Manège"
	carousel.description = "Un manège de chevaux de bois, bâché pour la nuit. Une pancarte : « Fermé ». Sous la bâche, on devine les chevaux immobiles."
	carousel.position = c + Vector3(0, 1.5, 0)
	_examinable_shape(carousel, Vector3(6.4, 3.0, 6.4))
	add_child(carousel)
	# le grand candélabre à deux lanternes
	var k := CANDELABRA
	add(PsxGeo.cylinder(0.08, 0.16, 6.0, 6), M.fonteDark, Vector3(k.x, 3.0, k.y))
	add(PsxGeo.box(0.06, 0.06, 1.5), M.fonteDark, Vector3(k.x, 6.0, k.y))
	for dz in [-0.7, 0.7]:
		add(PsxGeo.sphere(0.24, 6, 4), M.lanterne, Vector3(k.x, 6.2, k.y + dz), Vector3.ZERO, Vector3(1, 1.25, 1))
	_post(0.18, 3.0, Vector3(k.x, 0, k.y))
