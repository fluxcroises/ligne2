class_name PsxGeo
## Primitives construites comme dans three.js (mêmes sommets, mêmes UV), pour reprendre
## le prototype navigateur à l'identique. Une géométrie est un dictionnaire
## { p: positions, n: normales, uv: UV au sens three.js (v vers le haut), i: indices }.


static func xf(pos: Vector3, rot := Vector3.ZERO, scale := Vector3.ONE) -> Transform3D:
	# Ordre des rotations de three.js : X puis Y puis Z.
	var b := Basis(Vector3.RIGHT, rot.x) * Basis(Vector3.UP, rot.y) * Basis(Vector3.BACK, rot.z)
	return Transform3D(b * Basis.from_scale(scale), pos)


static func empty() -> Dictionary:
	return {"p": [], "n": [], "uv": [], "i": []}


static func uv_scale(g: Dictionary, su: float, sv: float) -> Dictionary:
	var uv: Array = g.uv
	for k in uv.size():
		uv[k] = Vector2(uv[k].x * su, uv[k].y * sv)
	return g


## Indices d'une grille de (gx + 1) × (gy + 1) sommets commençant à `base`.
static func _grid(g: Dictionary, gx: int, gy: int, base: int) -> void:
	for iy in gy:
		for ix in gx:
			var a := base + ix + (gx + 1) * iy
			var b := base + ix + (gx + 1) * (iy + 1)
			var c := base + (ix + 1) + (gx + 1) * (iy + 1)
			var d := base + (ix + 1) + (gx + 1) * iy
			g.i.append_array([a, b, d, b, c, d])


## Plan vertical w × h tourné vers +Z.
static func plane(w: float, h: float, gx := 1, gy := 1) -> Dictionary:
	var g := empty()
	for iy in gy + 1:
		var y := iy * h / gy - h * 0.5
		for ix in gx + 1:
			g.p.append(Vector3(ix * w / gx - w * 0.5, -y, 0.0))
			g.n.append(Vector3.BACK)
			g.uv.append(Vector2(float(ix) / gx, 1.0 - float(iy) / gy))
	_grid(g, gx, gy, 0)
	return g


static func box(w: float, h: float, d: float, sw := 1, sh := 1, sd := 1) -> Dictionary:
	var g := empty()
	_box_face(g, 2, 1, 0, -1, -1, d, h, w, sd, sh)
	_box_face(g, 2, 1, 0, 1, -1, d, h, -w, sd, sh)
	_box_face(g, 0, 2, 1, 1, 1, w, d, h, sw, sd)
	_box_face(g, 0, 2, 1, 1, -1, w, d, -h, sw, sd)
	_box_face(g, 0, 1, 2, 1, -1, w, h, d, sw, sh)
	_box_face(g, 0, 1, 2, -1, -1, w, h, -d, sw, sh)
	return g


static func _box_face(g: Dictionary, u: int, v: int, w: int, udir: float, vdir: float,
		width: float, height: float, depth: float, gx: int, gy: int) -> void:
	var base: int = g.p.size()
	for iy in gy + 1:
		var y := iy * height / gy - height * 0.5
		for ix in gx + 1:
			var x := ix * width / gx - width * 0.5
			var p := Vector3()
			p[u] = x * udir
			p[v] = y * vdir
			p[w] = depth * 0.5
			var n := Vector3()
			n[w] = 1.0 if depth > 0.0 else -1.0
			g.p.append(p)
			g.n.append(n)
			g.uv.append(Vector2(float(ix) / gx, 1.0 - float(iy) / gy))
	_grid(g, gx, gy, base)


static func cylinder(r_top: float, r_bottom: float, h: float, radial := 8, hseg := 1, open := false) -> Dictionary:
	var g := empty()
	var slope := (r_bottom - r_top) / h
	for y in hseg + 1:
		var v := float(y) / hseg
		var r := v * (r_bottom - r_top) + r_top
		for x in radial + 1:
			var u := float(x) / radial
			var t := u * TAU
			g.p.append(Vector3(r * sin(t), -v * h + h * 0.5, r * cos(t)))
			g.n.append(Vector3(sin(t), slope, cos(t)).normalized())
			g.uv.append(Vector2(u, 1.0 - v))
	# Même ordre de grille que le plan : on parcourt les anneaux comme des rangées.
	_grid(g, radial, hseg, 0)
	if not open:
		if r_top > 0.0:
			_cap(g, r_top, h * 0.5, 1.0, radial)
		if r_bottom > 0.0:
			_cap(g, r_bottom, -h * 0.5, -1.0, radial)
	return g


static func _cap(g: Dictionary, r: float, y: float, sign_y: float, radial: int) -> void:
	var center: int = g.p.size()
	g.p.append(Vector3(0, y, 0))
	g.n.append(Vector3(0, sign_y, 0))
	g.uv.append(Vector2(0.5, 0.5))
	for x in radial + 1:
		var t := float(x) / radial * TAU
		g.p.append(Vector3(r * sin(t), y, r * cos(t)))
		g.n.append(Vector3(0, sign_y, 0))
		g.uv.append(Vector2(cos(t) * 0.5 + 0.5, sin(t) * 0.5 * sign_y + 0.5))
	for x in radial:
		g.i.append_array([center, center + 1 + x, center + 2 + x])


static func cone(r: float, h: float, radial := 8) -> Dictionary:
	return cylinder(0.0, r, h, radial, 1, false)


static func sphere(r: float, ws: int, hs: int, phi_start := 0.0, phi_len := TAU,
		theta_start := 0.0, theta_len := PI) -> Dictionary:
	var g := empty()
	var theta_end := minf(theta_start + theta_len, PI)
	for iy in hs + 1:
		var v := float(iy) / hs
		for ix in ws + 1:
			var u := float(ix) / ws
			var phi := phi_start + u * phi_len
			var theta := theta_start + v * theta_len
			var p := Vector3(-r * cos(phi) * sin(theta), r * cos(theta), r * sin(phi) * sin(theta))
			g.p.append(p)
			g.n.append(p.normalized())
			g.uv.append(Vector2(u, 1.0 - v))
	for iy in hs:
		for ix in ws:
			var a := iy * (ws + 1) + ix + 1
			var b := iy * (ws + 1) + ix
			var c := (iy + 1) * (ws + 1) + ix
			var d := (iy + 1) * (ws + 1) + ix + 1
			if iy != 0 or theta_start > 0.0:
				g.i.append_array([a, b, d])
			if iy != hs - 1 or theta_end < PI:
				g.i.append_array([b, c, d])
	return g


static func icosahedron(r: float) -> Dictionary:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts := [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var faces := [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2,
		10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10,
		8, 6, 7, 9, 8, 1]
	return _polyhedron(verts, faces, r)


static func octahedron(r: float) -> Dictionary:
	var verts := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var faces := [0, 2, 4, 0, 4, 3, 0, 3, 5, 0, 5, 2, 1, 2, 5, 1, 5, 3, 1, 3, 4, 1, 4, 2]
	return _polyhedron(verts, faces, r)


## Polyèdre à faces plates, UV en projection sphérique comme three.js.
static func _polyhedron(verts: Array, faces: Array, r: float) -> Dictionary:
	var g := empty()
	for f in range(0, faces.size(), 3):
		var tri: Array = [verts[faces[f]].normalized() * r, verts[faces[f + 1]].normalized() * r, verts[faces[f + 2]].normalized() * r]
		var n: Vector3 = (tri[2] - tri[1]).cross(tri[0] - tri[1]).normalized()
		for p in tri:
			var u: float = atan2(p.z, -p.x) / TAU + 0.5
			var v: float = atan2(-p.y, Vector2(p.x, p.z).length()) / PI + 0.5
			g.i.append(g.p.size())
			g.p.append(p)
			g.n.append(n)
			g.uv.append(Vector2(u, 1.0 - v))
	return g


## Tube le long d'une courbe de Catmull-Rom (tiges des arcs Guimard).
## Les courbes du prototype sont toutes dans un plan vertical z = constante.
static func tube(points: Array, segments: int, radius: float, radial: int) -> Dictionary:
	var g := empty()
	var pts := [2.0 * points[0] - points[1]] + points + [2.0 * points[-1] - points[-2]]
	for i in segments + 1:
		var t := float(i) / segments * (points.size() - 1)
		var k := mini(int(t), points.size() - 2)
		var w := t - k
		var c: Vector3 = _catmull(pts[k], pts[k + 1], pts[k + 2], pts[k + 3], w)
		var tangent: Vector3 = (_catmull(pts[k], pts[k + 1], pts[k + 2], pts[k + 3], minf(w + 0.01, 1.0))
			- _catmull(pts[k], pts[k + 1], pts[k + 2], pts[k + 3], maxf(w - 0.01, 0.0))).normalized()
		var normal := Vector3.BACK.cross(tangent).normalized()
		for j in radial + 1:
			var a := float(j) / radial * TAU
			var n := -cos(a) * normal + sin(a) * Vector3.BACK
			g.p.append(c + n * radius)
			g.n.append(n)
			g.uv.append(Vector2(float(i) / segments, float(j) / radial))
	for i in segments:
		for j in radial:
			var a := (radial + 1) * i + j
			var b := (radial + 1) * (i + 1) + j
			g.i.append_array([a, b, a + 1, b, b + 1, a + 1])
	return g


static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


## Polygone plat (dans le plan XY, tourné vers +Z), UV = coordonnées × échelle.
static func polygon(outline: PackedVector2Array, su: float, sv: float) -> Dictionary:
	var g := empty()
	for q in outline:
		g.p.append(Vector3(q.x, q.y, 0.0))
		g.n.append(Vector3.BACK)
		g.uv.append(Vector2(q.x * su, q.y * sv))
	g.i.append_array(Array(Geometry2D.triangulate_polygon(outline)))
	return g
