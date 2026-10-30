extends Station
## Station Villiers, quais de la ligne 2, d'après des photos prises comme modèles (voir
## CREDITS.md) : voûte blanche, bande de carreaux bleu clair au pied des murs, bandeaux
## lumineux le long de la voûte, et, au milieu de chaque quai, l'escalier qui descend vers la
## correspondance, entouré d'une rambarde grise à ampoules posée sur une bordure gris foncé,
## ses contremarches peintes d'une fresque bleue et blanche. On arrive sur le quai direction
## Porte Dauphine par un couloir en tube, carrelé jusqu'en haut de la voûte.
## Même repère que Monceau (voir Station) ; la salle des billets et la surface viendront ensuite.

# Couloir en tube vers la sortie, perpendiculaire au quai A
const TUBE_X := -19.0          # axe du couloir
const TUBE_HW := 1.2           # demi-largeur
const TUBE_Z0 := 12.0          # fond du couloir (accès à la salle des billets, à venir)
const TUBE_SPRING := PY + 1.4  # naissance de la voûte du couloir
const TUBE_TOP := PY + 2.6     # clé de la voûte

## Passage sous les voies (vers la correspondance avec la ligne 3).
var UNDERPASS := {}


func _underpass() -> Dictionary:
	if UNDERPASS.is_empty():
		UNDERPASS = {"x0": -2.0, "x1": 5.5, "x2": 7.9, "w": 1.6, "floor": -10.5, "ceil": -8.2,
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
	_builder.build(self)
	_set_platform_zone()
	_global("zone2_min", Vector3(1e4, 1e4, 1e4))   # pas de seconde zone éclairée ici
	_global("zone2_max", Vector3(-1e4, -1e4, -1e4))
	set_night(night)


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame MF01 · prochaine station : Villiers"
		return "Rame MF01 · direction %s" % train.destination
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
	# en bas, sur le mur du fond du passage : vers la ligne 3
	var to_line3 := _sign([["ligne3", "Correspondance"]])
	plane(to_line3, 1.5, 0.5, u.x2 - 0.02, -9.1, (ZA + ZB) / 2, -PI / 2)
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
