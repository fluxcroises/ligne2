extends Station
## Station Nation, terminus de la ligne 2, d'après des photos prises comme modèles (voir
## CREDITS.md) : quais sous un tablier métallique vert-de-gris à poutres apparentes, carreaux
## jaune orangé, néons. Au bout du quai d'arrivée, une porte de service et un couloir mènent à
## la boucle de retournement ; dans son mur, la niche du « local 14 », fermée par une grille.
## Les quais sont droits ici (ils sont en courbe dans la réalité). Les quais captent le réseau
## (station équipée de la 4G) ; la boucle, non.
## Même repère que les autres stations (voir Station).

const DECK_Y := PY + 4.6        # dessous du tablier métallique
const SERV := Vector2(29.4, 30.6)      # porte de service et couloir vers la boucle (x), quai B
const SERV_H := 2.3
const EXIT_X := -10.0                  # sortie, fermée à cette heure (quai A)
const NICHE_A := -1.2566               # angle du local 14 dans la boucle (-72°)
const NICHE := Vector3(2.4, 2.3, 2.4)  # largeur, hauteur, profondeur de la niche

var service_door: Node3D
var service_open := false
var niche_gate: Node3D
var niche_open := false


## La boucle de retournement (voir Station._build_loop).
func _loop() -> Dictionary:
	return {"c": Vector2(30.0, 83.0), "r": 40.0, "a": Vector2(deg_to_rad(-125.0), deg_to_rad(-55.0)), "walk": Vector2(1.5, 2.6),
		"spring": PY + SERV_H, "openings": [[-PI / 2, (SERV.y - SERV.x) / 2], [NICHE_A, NICHE.x / 2]], "gaps": [],
		"lamps": [-118.0, -108.0, -99.0, -90.0, -80.0, -66.0, -58.0]}


## z du mur extérieur de la boucle, là où débouche le couloir de service.
func _loop_wall_z() -> float:
	var b := _loop()
	return b.c.y - (b.r + b.walk.y)


func _ready() -> void:
	_under_lamps = _loop_lamps(_loop())
	_under_lamps.append(Vector3((SERV.x + SERV.y) / 2, PY + 2.0, (ZB + _loop_wall_z()) / 2))
	_under_lamps.append(_niche_xf() * Vector3(0, NICHE.y - 0.3, -1.0))   # l'ampoule nue du local 14
	_under_lamps.append(_niche_xf() * Vector3(0, 2.0, 1.2))              # devant la grille
	_begin(5)
	M.nom = _mat("nom_nation")
	M.carreau = _mat("carreau_blanc", 0xf0bc6a)   # carreaux jaune orangé, comme sur la photo
	var barriers := _nation_colliders()
	_setup_trafic([[25.5, -1, 1, 0.0, "Porte Dauphine"], [28.5, 1, -1, 47.0, "Nation"]], barriers)
	_build_platforms()
	_build_service()
	_build_loop(_loop())
	_build_niche()
	_place_people()
	var chapter := preload("res://scripts/chapitre_5_jeu.gd").new()
	chapter.name = "Chapitre5"
	add_child(chapter)
	_builder.build(self)
	_set_platform_zone()
	set_night(night)


func _has_network_at(pos: Vector3) -> bool:
	return pos.z < ZB + 0.3   # les quais captent ; le couloir et la boucle, non


## Nom du lieu affiché en bas de l'écran.
func place_name(pos: Vector3) -> String:
	var train: MF01 = trafic.train_at(pos) if trafic else null
	if train:
		if trafic.is_moving(train):
			return "Rame · prochaine station : %s" % ("Avron" if train.destination == "Porte Dauphine" else "Nation")
		return "Rame ligne 2 · direction %s" % train.destination
	var b := _loop()
	var np := _loop_point(b, NICHE_A, b.walk.y + NICHE.z / 2)
	if Vector2(pos.x, pos.z).distance_to(np) < NICHE.z / 2 + 0.2:
		return "Local 14 · boucle de Nation"
	if pos.z > _loop_wall_z() - 0.3:
		return "Boucle de retournement · Nation"
	if pos.z > ZB:
		return "Couloir de service · Nation"
	return "Quai d'arrivée · terminus" if pos.z > CZ else "Quai · direction Porte Dauphine"


# --- Quais ---------------------------------------------------------------------
# D'après les photos de Pline (Wikimedia Commons, CC BY-SA 3.0) : tablier métallique à poutres
# vert-de-gris, murs de carreaux jaune orangé, longs néons.

func _build_platforms() -> void:
	rect(M.sol, X0, ZA, X1, ZT0 - 0.55, PY, 2.4)
	rect(M.sol, X0, ZT1 + 0.55, X1, ZB, PY, 2.4)
	_build_tracks()
	var h := DECK_Y - PY
	for run in [[X0, EXIT_X - 1.2, ZA], [EXIT_X + 1.2, X1, ZA], [X0, SERV.x, ZB], [SERV.y, X1, ZB]]:
		var length: float = run[1] - run[0]
		plane(M.carreau, length, h, (run[0] + run[1]) / 2, (PY + DECK_Y) / 2, run[2], 0.0 if run[2] == ZA else PI, length / TW, h / TH)
		plane(M.plinthe, length, 0.2, (run[0] + run[1]) / 2, PY + 0.1, run[2] + (0.01 if run[2] == ZA else -0.01), 0.0 if run[2] == ZA else PI, length / 0.6, 1)
	for over in [[EXIT_X - 1.2, EXIT_X + 1.2, ZA, PY + 2.4], [SERV.x, SERV.y, ZB, PY + SERV_H]]:
		var width: float = over[1] - over[0]
		plane(M.carreau, width, DECK_Y - over[3], (over[0] + over[1]) / 2, (over[3] + DECK_Y) / 2, over[2], 0.0 if over[2] == ZA else PI, width / TW, 2)
	for sx in [-1.0, 1.0]:
		_build_tympan_and_tunnel(sx)
	# le tablier métallique : tôle, poutres transversales et longitudinales, néons
	var steel := _mat("blanc", 0x4f6258)
	var steel_dark := _mat("blanc", 0x3a4a42)
	box(steel_dark, L, 0.1, ZB - ZA, 0, DECK_Y + 0.05, CZ, L / 2, 4)
	for x in range(-36, 37, 3):
		box(steel, 0.25, 0.45, ZB - ZA, x, DECK_Y - 0.2, CZ, 1, 4)
	for z in [ZA + 0.3, ZT0, ZT1, ZB - 0.3]:
		box(steel, L, 0.35, 0.2, 0, DECK_Y - 0.17, z, L / 2, 1)
	for z in [22.4, 31.6]:
		box(M.neon, L - 2, 0.06, 0.18, 0, DECK_Y - 0.45, z)
	# plaques, consignes, panneaux, écrans, sièges
	for x in [-26, -6, 14, 26]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZA + 0.03, 0)
	for x in [-24, -4, 16]:
		plane(M.nom, 2.1, 0.52, x, -4.75, ZB - 0.03, PI)
	for x in [-30, 4, 22]:
		plane(M.nepas, 1.1, 0.21, x, -5.5, ZB - 0.03, PI)
	var terminus := _sign([["sortie", "Terminus"]])
	for r in [0.0, PI]:
		plane(terminus, 1.5, 0.25, 0, DECK_Y - 0.8, ZT1 + 1.2 + (0.03 if r == 0.0 else -0.03), r)
	_build_screens([-16, 18])
	_build_seats([[-24, 20.45, 1], [6, 20.45, 1], [24, 20.45, 1], [-20, 33.55, -1], [0, 33.55, -1], [12, 33.55, -1]])
	_line_plan("Nation", "Porte Dauphine", Vector3(EXIT_X + 3.0, -5.0, ZA + 0.03), 0)
	# la sortie, fermée à cette heure : une grille, un panneau
	rect(M.marche, EXIT_X - 1.2, ZA - 2.0, EXIT_X + 1.2, ZA, PY, 1.0)
	plane(M.gardecorps, 2.4, 2.4, EXIT_X, PY + 1.2, ZA - 0.05, 0, 2.4, 2)
	plane(M.carreau, 2.4, 2.4, EXIT_X, PY + 1.2, ZA - 2.0, 0, 2, 4)
	var out := _sign([["sortie", "Sortie"]])
	plane(out, 1.2, 0.2, EXIT_X, PY + 2.6, ZA + 0.03, 0)
	var grille := Examinable.new()
	grille.title = "Grille de la sortie"
	grille.description = "Baissée. Une affichette : « Fermeture de la station à 0 h 50 ». Il faudra sortir par ailleurs, ou attendre le matin."
	grille.position = Vector3(EXIT_X, PY + 1.2, ZA - 0.1)
	_examinable_shape(grille, Vector3(2.4, 2.4, 0.2))
	add_child(grille)


## Collisions des deux quais (pas d'escalier : la sortie est fermée) ; renvoie les garde-fous.
func _nation_colliders() -> Array[CollisionShape3D]:
	var barriers: Array[CollisionShape3D] = []
	for quai in [[ZA, ZT0, 1.0], [ZB, ZT1, -1.0]]:
		var zw: float = quai[0]
		var ze: float = quai[1]
		var inward: float = quai[2]
		_solid(Vector3(L, 0.2, absf(ze - zw)), Vector3(0, PY - 0.1, (zw + ze) / 2))
		var runs := [[X0, X1]] if zw == ZA else [[X0, SERV.x], [SERV.y, X1]]
		for r in runs:
			_solid(Vector3(r[1] - r[0], DECK_Y - PY, 0.2), Vector3((r[0] + r[1]) / 2, (PY + DECK_Y) / 2, zw - inward * 0.1))
		barriers.append(_platform_end_colliders(zw, ze, inward))
	_solid(Vector3(SERV.y - SERV.x, DECK_Y - PY - SERV_H, 0.2), Vector3((SERV.x + SERV.y) / 2, (PY + SERV_H + DECK_Y) / 2, ZB + 0.1))
	return barriers


# --- Porte de service et couloir vers la boucle --------------------------------------

func _build_service() -> void:
	var zf := _loop_wall_z()
	rect(M.sol, SERV.x, ZB, SERV.y, zf, PY, 2.4)
	rect(M.platre, SERV.x, ZB, SERV.y, zf, PY + SERV_H, 2.0, PI / 2)
	for x in [SERV.x, SERV.y]:
		plane(M.tunnel, zf - ZB, SERV_H, x, PY + SERV_H / 2, (ZB + zf) / 2, PI / 2, (zf - ZB) / 2.4, 1)
		_solid(Vector3(0.2, SERV_H, zf - ZB), Vector3(x + (-0.1 if x == SERV.x else 0.1), PY + SERV_H / 2, (ZB + zf) / 2))
	box(M.neon, 0.06, 0.06, 0.3, (SERV.x + SERV.y) / 2, PY + SERV_H - 0.05, (ZB + zf) / 2)
	_solid(Vector3(SERV.y - SERV.x, 0.2, zf - ZB), Vector3((SERV.x + SERV.y) / 2, PY - 0.1, (ZB + zf) / 2))
	plane(_mat("alarme"), 1.0, 0.25, (SERV.x + SERV.y) / 2, PY + SERV_H + 0.3, ZB - 0.03, PI)
	# la porte, sur charnière : Bruno l'ouvre (voir Chapitre5Jeu)
	var w := SERV.y - SERV.x
	service_door = Node3D.new()
	service_door.position = Vector3(SERV.x, PY, ZB - 0.03)
	add_child(service_door)
	var leaf := PsxBuilder.new()
	leaf.add(PsxGeo.box(w, 2.2, 0.05), _mat("porte_service"), PsxGeo.xf(Vector3(w / 2, 1.1, 0)))
	leaf.build(service_door)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(w, 2.2, 0.05)
	shape.position = Vector3(w / 2, 1.1, 0)
	body.add_child(shape)
	service_door.add_child(body)
	var item := Examinable.new()
	item.title = "Porte de service"
	item.description = "« Accès réservé – boucle de retournement ». Fermée à clé."
	item.position = Vector3((SERV.x + SERV.y) / 2, PY + 1.1, ZB - 0.15)
	_examinable_shape(item, Vector3(w, 2.2, 0.1))
	add_child(item)


func set_service_open(on: bool) -> void:
	service_open = on
	service_door.rotation.y = deg_to_rad(100.0) if on else 0.0


# --- La niche du local 14 -------------------------------------------------------------

## Repère de la niche : origine sur le mur extérieur de la boucle, x le long du tunnel,
## z vers l'intérieur du tunnel (la niche s'enfonce vers -z).
func _niche_xf() -> Transform3D:
	var b := _loop()
	var a := NICHE_A
	var q := _loop_point(b, a, b.walk.y)
	var t := Vector3(-sin(a), 0, cos(a))
	return Transform3D(Basis(t, Vector3.UP, t.cross(Vector3.UP)), Vector3(q.x, PY, q.y))


func _build_niche() -> void:
	var xf := _niche_xf()
	var w := NICHE.x
	var h := NICHE.y
	var d := NICHE.z
	var wall: Material = M.tunnel
	add_xf(PsxGeo.uv_scale(PsxGeo.plane(w, d), 2, 2), M.sol, xf * PsxGeo.xf(Vector3(0, 0.01, -d / 2), Vector3(-PI / 2, 0, 0)))
	add_xf(PsxGeo.plane(w, d), M.platre, xf * PsxGeo.xf(Vector3(0, h, -d / 2), Vector3(PI / 2, 0, 0)))
	add_xf(PsxGeo.uv_scale(PsxGeo.plane(w, h), 1, 1), wall, xf * PsxGeo.xf(Vector3(0, h / 2, -d)))
	for sx in [-1.0, 1.0]:
		add_xf(PsxGeo.uv_scale(PsxGeo.plane(d, h), 1, 1), wall, xf * PsxGeo.xf(Vector3(sx * w / 2, h / 2, -d / 2), Vector3(0, PI / 2, 0)))
		_solid_xf(Vector3(0.2, h, d), xf * PsxGeo.xf(Vector3(sx * (w / 2 + 0.1), h / 2, -d / 2)))
	_solid_xf(Vector3(w, h, 0.2), xf * PsxGeo.xf(Vector3(0, h / 2, -d - 0.1)))
	_solid_xf(Vector3(w, 0.2, d), xf * PsxGeo.xf(Vector3(0, -0.1, -d / 2)))
	# dedans : un matelas, une bouteille, une ampoule nue ; devant : des barquettes vides
	add_xf(PsxGeo.box(0.9, 0.12, 1.9), _mat("blanc", 0x6a6a5a), xf * PsxGeo.xf(Vector3(0.6, 0.06, -1.4), Vector3(0, PI / 2, 0)))
	add_xf(PsxGeo.cylinder(0.04, 0.04, 0.3, 5), _mat("blanc", 0x4a7a6a), xf * PsxGeo.xf(Vector3(-0.9, 0.15, -2.1)))
	add_xf(PsxGeo.sphere(0.06, 4, 3), _mat("blanc", 0xfff0c0, false, true), xf * PsxGeo.xf(Vector3(0, h - 0.15, -d / 2)))
	for k in 3:
		add_xf(PsxGeo.box(0.18, 0.04, 0.12), _mat("blanc", 0xd8d4c8), xf * PsxGeo.xf(Vector3(-0.8 + k * 0.25, 0.02, 0.35)))
	add_xf(PsxGeo.plane(0.6, 0.3), _mat("local_14"), xf * PsxGeo.xf(Vector3(0, h + 0.25, 0.02)))
	# la grille, sur charnière, cadenassée
	niche_gate = Node3D.new()
	niche_gate.transform = xf * PsxGeo.xf(Vector3(-w / 2, 0, -0.05))
	add_child(niche_gate)
	var leaf := PsxBuilder.new()
	leaf.add(PsxGeo.uv_scale(PsxGeo.plane(w, h), w, 2), M.gardecorps, PsxGeo.xf(Vector3(w / 2, h / 2, 0)))
	leaf.add(PsxGeo.box(0.12, 0.16, 0.08), _mat("blanc", 0xc8b048), PsxGeo.xf(Vector3(w - 0.15, 1.05, 0.06)))   # cadenas
	leaf.build(niche_gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(w, h, 0.08)
	shape.position = Vector3(w / 2, h / 2, 0)
	body.add_child(shape)
	niche_gate.add_child(body)
	var item := Examinable.new()
	item.title = "Grille du local 14"
	item.description = "Une grille fermée par un cadenas neuf. Devant, des barquettes de repas vides. Derrière, dans le noir, quelqu'un respire."
	item.evidence_id = "cadenas"
	item.photo_range = 3.0
	item.transform = xf * PsxGeo.xf(Vector3(0, 1.1, 0.12))
	_examinable_shape(item, Vector3(w, h, 0.1))
	add_child(item)


func set_niche_open(on: bool) -> void:
	niche_open = on
	niche_gate.transform = _niche_xf() * PsxGeo.xf(Vector3(-NICHE.x / 2, 0, -0.05), Vector3(0, deg_to_rad(110.0) if on else 0.0, 0))


## Boîte de collision placée par une transformation.
func _solid_xf(size: Vector3, xf: Transform3D) -> void:
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.transform = _frame * xf
	_collisions.add_child(shape)


# --- Personnages du chapitre 5 ---------------------------------------------------

func _place_people() -> void:
	var b := _loop()
	var guard := _loop_point(b, NICHE_A - 0.05, 2.0)
	var toward := _loop_point(b, NICHE_A - 0.3, 2.0) - guard
	var inside := _niche_xf() * Vector3(0.0, 0.0, -1.6)
	var cast := [
		["bruno", "Bruno, conducteur", {"coat": Color("#2a3a5a"), "pants": Color("#20242c"), "skin": Color("#c89a7a"), "hair": Color("#5a4a3a")},
			false, Vector3(27.6, PY, 32.6), 0.0],
		["franck", "Franck Roussel", {"coat": Color("#3a3a36"), "pants": Color("#2a2c30"), "skin": Color("#c09070"), "hair": Color("#2a2420"), "vest": Color("#ff7a1a")},
			false, Vector3(guard.x, PY, guard.y), atan2(-toward.x, -toward.y)],
		["karim", "Karim Benali", {"coat": Color("#3a4a5a"), "pants": Color("#2a2c34"), "skin": Color("#b07a5a"), "hair": Color("#2a2420")},
			true, Vector3(inside.x, PY, inside.z), atan2(-_niche_xf().basis.z.x, -_niche_xf().basis.z.z)],
	]
	for p in cast:
		var person := Personnage.new(p[0], p[1], p[2], p[3])
		person.name = p[0].capitalize()
		person.position = p[4]
		person.rotation.y = p[5]
		add_child(person)
		people[p[0]] = person
