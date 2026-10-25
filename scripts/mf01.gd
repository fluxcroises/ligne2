class_name MF01
extends Node3D
## Rame MF01 de cinq voitures (75 m, comme sur la ligne 2), reprise du prototype : caisse, vitres et portes ajourées,
## intérieur complet (sièges, barres, néons, soufflets), collisions pour monter à bord.
## Origine : centre de la rame, au niveau des rails ; la rame suit l'axe X.

const CARS := 5
const CAR_PITCH := 14.0
const HALF_LENGTH := CARS * CAR_PITCH / 2
const DOOR_OFFSETS := [-4.533, 0.0, 4.533]   # portes de chaque voiture, autour de son centre
const OPEN_THRESHOLD := 0.8                  # au-delà, les portes laissent passer

var destination := ""
var door_side := 1      # côté (z local) dont les portes s'ouvrent à Monceau
var direction := 1      # 1 : arrive par les x positifs et repart vers les x négatifs
var offset := 0.0       # décalage dans le cycle des passages, en secondes
var doors_amount := 0.0
var floor_height := 0.0
var beeped := false

var _leaves := []                              # [nœud, x fermé, sens d'ouverture]
var _door_shapes: Array[CollisionShape3D] = []


func _init(M: Dictionary, floor_h: float, side: int, dir: int, off: float, dest: String) -> void:
	floor_height = floor_h
	door_side = side
	direction = dir
	offset = off
	destination = dest
	_build_body(M)
	_build_collisions()


## Le point est-il à l'intérieur de la rame, au niveau du plancher ?
func contains(p: Vector3) -> bool:
	var lp := p - position
	return absf(lp.x) < HALF_LENGTH - 0.7 and absf(lp.z) < 1.25 and absf(lp.y - floor_height) < 1.0


func set_doors(amount: float) -> void:
	doors_amount = amount
	for leaf in _leaves:
		leaf[0].position.x = leaf[1] + leaf[2] * 0.48 * amount
	var open := amount >= OPEN_THRESHOLD
	for shape in _door_shapes:
		if shape.disabled != open:
			shape.set_deferred("disabled", open)


static func car_center(c: int) -> float:
	return (c - (CARS - 1) / 2.0) * CAR_PITCH


static func door_positions() -> Array[float]:
	var xs: Array[float] = []
	for c in CARS:
		for dx in DOOR_OFFSETS:
			xs.append(car_center(c) + dx)
	return xs


func _build_body(M: Dictionary) -> void:
	var b := PsxBuilder.new()
	var fh := floor_height
	var poles := []
	for c in CARS:
		var cx := car_center(c)
		_put(b, PsxGeo.box(13.0, 0.6, 2.0, 7, 1, 1), M.rameNoir, Vector3(cx, 0.35, 0))
		_put(b, PsxGeo.uv_scale(PsxGeo.plane(13.6, 2.4, 7, 1), 3, 1), M.rameBlanc, Vector3(cx, 3.5, 0), Vector3(-PI / 2, 0, 0))
		_put(b, PsxGeo.plane(13.6, 2.3, 7, 1), M.int_sol, Vector3(cx, fh, 0), Vector3(-PI / 2, 0, 0))
		_put(b, PsxGeo.plane(13.6, 2.3, 7, 1), M.int_plafond, Vector3(cx, fh + 2.2, 0), Vector3(PI / 2, 0, 0))
		for sz in [-1, 1]:
			var out_ry := PI if sz < 0 else 0.0
			var in_ry := 0.0 if sz < 0 else PI
			_put(b, PsxGeo.uv_scale(PsxGeo.plane(13.6, 2.9, 7, 2), 3, 1), M.rameCote, Vector3(cx, 2.05, sz * 1.21), Vector3(0, out_ry, 0))
			_put(b, PsxGeo.uv_scale(PsxGeo.plane(13.6, 2.9, 7, 2), 3, 1), M.int_paroi, Vector3(cx, 2.05, sz * 1.17), Vector3(0, in_ry, 0))
			for dx in DOOR_OFFSETS:
				var x: float = cx + dx
				for lr in [-1, 1]:
					var x0: float = x + lr * 0.25
					var leaf_pos := Vector3(x0, 2.0, sz * 1.225)
					var ext := PsxGeo.xf(Vector3.ZERO, Vector3(0, out_ry, 0))
					var inn := PsxGeo.xf(Vector3(0, 0, -sz * 0.03), Vector3(0, in_ry, 0))
					if sz == door_side:
						# Vantaux mobiles : un nœud par vantail, déplacé à l'ouverture.
						var leaf := Node3D.new()
						leaf.position = leaf_pos
						add_child(leaf)
						var lb := PsxBuilder.new()
						lb.add(PsxGeo.plane(0.5, 2.36), M.porte_ext, ext)
						lb.add(PsxGeo.plane(0.5, 2.36), M.porte_int, inn)
						lb.build(leaf)
						_leaves.append([leaf, x0, lr])
					else:
						b.add(PsxGeo.plane(0.5, 2.36), M.porte_ext, Transform3D(Basis(), leaf_pos) * ext)
						b.add(PsxGeo.plane(0.5, 2.36), M.porte_int, Transform3D(Basis(), leaf_pos) * inn)
				poles.append(Vector3(x, fh + 1.05, 0))
				_put(b, PsxGeo.plane(1.5, 0.24), M.int_plan, Vector3(x, fh + 2.08, sz * 1.02), Vector3(0, in_ry, 0))
		# sièges face à face dans les deux travées centrales
		for bx in [cx - 2.266, cx + 2.266]:
			for row in [[-0.62, 1.0], [0.62, -1.0]]:
				var x: float = bx + row[0]
				var f: float = row[1]
				for sz in [-0.82, -0.38, 0.38, 0.82]:
					_put(b, PsxGeo.box(0.44, 0.08, 0.42), M.siege, Vector3(x, fh + 0.46, sz))
					_put(b, PsxGeo.box(0.06, 0.55, 0.42), M.siege, Vector3(x - f * 0.22, fh + 0.76, sz))
					_put(b, PsxGeo.box(0.3, 0.4, 0.36), M.int_pied, Vector3(x, fh + 0.2, sz))
		for z in [-0.5, 0.5]:
			_put(b, PsxGeo.cylinder(0.02, 0.02, 13.2, 4), M.inox, Vector3(cx, fh + 1.95, z), Vector3(0, 0, PI / 2))
		for z in [-0.6, 0.6]:
			_put(b, PsxGeo.box(12.6, 0.05, 0.22), M.neon, Vector3(cx, fh + 2.17, z))
		if c < CARS - 1:  # soufflet d'intercirculation
			for sz in [-1, 1]:
				_put(b, PsxGeo.plane(0.42, 2.2), M.soufflet, Vector3(cx + 7, fh + 1.1, sz * 1.0), Vector3(0, 0.0 if sz < 0 else PI, 0))
				_put(b, PsxGeo.plane(0.42, 2.9), M.rameNoir, Vector3(cx + 7, 2.05, sz * 1.2), Vector3(0, PI if sz < 0 else 0.0, 0))
			_put(b, PsxGeo.plane(0.42, 2.0), M.int_sol, Vector3(cx + 7, fh + 0.005, 0), Vector3(-PI / 2, 0, 0))
			_put(b, PsxGeo.plane(0.42, 2.0), M.soufflet, Vector3(cx + 7, fh + 2.2, 0), Vector3(PI / 2, 0, 0))
			_put(b, PsxGeo.plane(0.42, 2.4), M.rameNoir, Vector3(cx + 7, 3.45, 0), Vector3(-PI / 2, 0, 0))
	for p in poles:
		_put(b, PsxGeo.cylinder(0.025, 0.025, 2.1, 5), M.inox, p)
	_put(b, PsxGeo.plane(2.4, 3.0), M.rameFace, Vector3(-HALF_LENGTH - 0.02, 2.05, 0), Vector3(0, -PI / 2, 0))
	_put(b, PsxGeo.plane(2.4, 3.0), M.rameFace, Vector3(HALF_LENGTH + 0.02, 2.05, 0), Vector3(0, PI / 2, 0))
	_put(b, PsxGeo.plane(2.3, 2.2), M.int_cabine, Vector3(-HALF_LENGTH + 0.4, fh + 1.1, 0), Vector3(0, PI / 2, 0))
	_put(b, PsxGeo.plane(2.3, 2.2), M.int_cabine, Vector3(HALF_LENGTH - 0.4, fh + 1.1, 0), Vector3(0, -PI / 2, 0))
	b.build(self)


func _put(b: PsxBuilder, geo: Dictionary, m: Material, pos: Vector3, rot := Vector3.ZERO) -> void:
	b.add(geo, m, PsxGeo.xf(pos, rot))


func _build_collisions() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var fh := floor_height
	# Le plancher déborde jusqu'au bord du quai pour ne laisser aucun vide.
	_shape(body, Vector3(HALF_LENGTH * 2, 0.2, 3.0), Vector3(0, fh - 0.1, 0))
	_shape(body, Vector3(HALF_LENGTH * 2, 2.4, 0.1), Vector3(0, fh + 1.2, -door_side * 1.22))
	for end in [-1, 1]:
		_shape(body, Vector3(0.1, 2.4, 2.4), Vector3(end * HALF_LENGTH, fh + 1.2, 0))
	# côté quai : panneaux entre les portes, et une collision par porte, ôtée à l'ouverture
	var start := -HALF_LENGTH
	for d in door_positions():
		_shape(body, Vector3(d - 0.5 - start, 2.4, 0.1), Vector3((start + d - 0.5) / 2, fh + 1.2, door_side * 1.22))
		_door_shapes.append(_shape(body, Vector3(1.0, 2.4, 0.1), Vector3(d, fh + 1.2, door_side * 1.22)))
		start = d + 0.5
	_shape(body, Vector3(HALF_LENGTH - start, 2.4, 0.1), Vector3((start + HALF_LENGTH) / 2, fh + 1.2, door_side * 1.22))
	# carrés de sièges, en laissant l'allée centrale libre
	for c in CARS:
		for bx in [car_center(c) - 2.266, car_center(c) + 2.266]:
			for sz in [-1, 1]:
				_shape(body, Vector3(1.9, 0.9, 0.8), Vector3(bx, fh + 0.45, sz * 0.7))


func _shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.position = pos
	body.add_child(shape)
	return shape
