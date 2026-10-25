extends Node3D
## Maquette de la station Monceau : voûte carrelée, deux quais latéraux, deux voies,
## têtes de tunnel. Les dimensions sont celles d'une station type du métro parisien ;
## elles seront calées sur le prototype navigateur à l'étape 2.
## L'axe de la station suit X, le quai direction Nation est côté +Z.

const LENGTH := 60.0
const HALF_LEN := LENGTH * 0.5
const HALF_WIDTH := 7.05      # demi-largeur intérieure de la voûte
const PIT_HALF_WIDTH := 2.95  # demi-largeur de la fosse des voies
const PIT_DEPTH := 1.0        # hauteur du quai au-dessus du ballast
const SPRING := 2.2           # hauteur des piédroits verticaux
const RISE := 3.7             # flèche de la voûte (clé à 5,9 m)
const ARC_SEGMENTS := 12
const SLICE := 2.0            # découpe en longueur (limite les déformations PS1)
const TUNNEL_LEN := 30.0
const TUNNEL_HEIGHT := 4.0
const TILE := 0.6             # une texture de carrelage couvre 60 cm

var _mat := {}


func _ready() -> void:
	_mat = {
		"tiles": PsxKit.material(PsxKit.tiles_texture()),
		"asphalt": PsxKit.material(PsxKit.asphalt_texture()),
		"edge": PsxKit.material(PsxKit.edge_texture()),
		"ballast": PsxKit.material(PsxKit.ballast_texture()),
		"tunnel": PsxKit.material(PsxKit.tunnel_texture()),
		"rail": PsxKit.material(null, Color(0.45, 0.42, 0.4)),
		"seat": PsxKit.material(null, Color(0.85, 0.38, 0.1)),
		"plaque": PsxKit.material(null, Color(0.1, 0.24, 0.55)),
		"door": PsxKit.material(null, Color(0.32, 0.38, 0.36)),
		"sign": PsxKit.material(null, Color(0.75, 0.1, 0.08), 0.5),
		"lamp": PsxKit.material(null, Color(1.0, 0.95, 0.85), 1.0),
	}
	_build_vault()
	_build_floor()
	_build_ends()
	_build_furniture()
	_build_lights()
	_build_clues()


func _build_vault() -> void:
	# Profil vu en coupe (z, y), d'un pied de mur à l'autre.
	var profile: Array[Vector2] = [Vector2(HALF_WIDTH, 0.0)]
	for i in ARC_SEGMENTS + 1:
		var a := PI * i / ARC_SEGMENTS
		profile.append(Vector2(cos(a) * HALF_WIDTH, SPRING + sin(a) * RISE))
	profile.append(Vector2(-HALF_WIDTH, 0.0))

	var arc_len: Array[float] = [0.0]
	for i in range(1, profile.size()):
		arc_len.append(arc_len[i - 1] + profile[i].distance_to(profile[i - 1]))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var slices := int(LENGTH / SLICE)
	for s in slices:
		var x0 := -HALF_LEN + s * SLICE
		var x1 := x0 + SLICE
		for i in profile.size() - 1:
			var a := profile[i]
			var b := profile[i + 1]
			var mid := (a + b) * 0.5
			var inward := Vector3(0.0, SPRING - mid.y, -mid.x).normalized()
			if mid.y < SPRING:
				inward = Vector3(0.0, 0.0, -signf(mid.x))
			var p := [Vector3(x0, a.y, a.x), Vector3(x1, a.y, a.x), Vector3(x1, b.y, b.x), Vector3(x0, b.y, b.x)]
			var uv := [
				Vector2(x0 / TILE, arc_len[i] / TILE), Vector2(x1 / TILE, arc_len[i] / TILE),
				Vector2(x1 / TILE, arc_len[i + 1] / TILE), Vector2(x0 / TILE, arc_len[i + 1] / TILE),
			]
			PsxKit.add_quad(st, p, uv, inward)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = _mat.tiles
	add_child(mesh)

	# Murs pleins derrière les quais (collision seulement).
	for side in [-1.0, 1.0]:
		_collider(Vector3(LENGTH, 6.0, 0.4), Vector3(0, 3.0, side * (HALF_WIDTH + 0.2)))


func _build_floor() -> void:
	var quai_width := HALF_WIDTH - PIT_HALF_WIDTH
	for side in [-1.0, 1.0]:
		var zc: float = side * (PIT_HALF_WIDTH + quai_width * 0.5)
		_box(Vector3(LENGTH, PIT_DEPTH, quai_width), Vector3(0, -PIT_DEPTH * 0.5, zc), _mat.asphalt, 1.5)
		# Bande d'éveil le long du bord.
		_box(Vector3(LENGTH, 0.01, 0.5), Vector3(0, 0.005, side * (PIT_HALF_WIDTH + 0.25)), _mat.edge, 0.5, false)
		# Barrière invisible provisoire : on ne descend pas sur les voies.
		_collider(Vector3(LENGTH, 2.0, 0.1), Vector3(0, 1.0, side * (PIT_HALF_WIDTH - 0.05)))

	var total := LENGTH + TUNNEL_LEN * 2.0
	_box(Vector3(total, 0.2, PIT_HALF_WIDTH * 2.0), Vector3(0, -PIT_DEPTH - 0.1, 0), _mat.ballast, 2.0)
	# Deux voies, un rail tous les 1,435 m (écartement standard).
	for track_z in [-1.45, 1.45]:
		for rail in [-0.72, 0.72]:
			_box(Vector3(total, 0.15, 0.07), Vector3(0, -PIT_DEPTH + 0.075, track_z + rail), _mat.rail, 1.0, false)


func _build_ends() -> void:
	var quai_width := HALF_WIDTH - PIT_HALF_WIDTH
	var top := SPRING + RISE
	for end in [-1.0, 1.0]:
		var x: float = end * (HALF_LEN + 0.2)
		for side in [-1.0, 1.0]:
			_box(Vector3(0.4, top + PIT_DEPTH, quai_width), Vector3(x, (top - PIT_DEPTH) * 0.5, side * (PIT_HALF_WIDTH + quai_width * 0.5)), _mat.tiles, TILE)
		var lintel_h := top - (TUNNEL_HEIGHT - PIT_DEPTH)
		_box(Vector3(0.4, lintel_h, PIT_HALF_WIDTH * 2.0), Vector3(x, top - lintel_h * 0.5, 0), _mat.tiles, TILE)

		# Tunnel : deux murs et un plafond, le brouillard fait le reste.
		var tx: float = end * (HALF_LEN + TUNNEL_LEN * 0.5)
		for side in [-1.0, 1.0]:
			_box(Vector3(TUNNEL_LEN, TUNNEL_HEIGHT, 0.4), Vector3(tx, TUNNEL_HEIGHT * 0.5 - PIT_DEPTH, side * (PIT_HALF_WIDTH + 0.2)), _mat.tunnel, 2.0)
		_box(Vector3(TUNNEL_LEN, 0.4, PIT_HALF_WIDTH * 2.0), Vector3(tx, TUNNEL_HEIGHT - PIT_DEPTH + 0.2, 0), _mat.tunnel, 2.0)


func _build_furniture() -> void:
	var back := HALF_WIDTH - 0.35
	# Sièges orange par groupes de quatre, sur les deux quais.
	for side in [-1.0, 1.0]:
		for group_x in [-22.0, -10.0, 2.0, 14.0, 26.0]:
			for i in 4:
				var x: float = group_x + (i - 1.5) * 0.5
				_box(Vector3(0.42, 0.06, 0.4), Vector3(x, 0.45, side * back), _mat.seat, 1.0)
				_box(Vector3(0.42, 0.45, 0.06), Vector3(x, 0.7, side * (back + 0.17)), _mat.seat, 1.0, false)
			_box(Vector3(2.0, 0.42, 0.2), Vector3(group_x, 0.21, side * back), _mat.door, 1.0)

	# Plaques « Monceau » sur les piédroits.
	for side in [-1.0, 1.0]:
		for x in [-18.0, 0.0, 18.0]:
			var z: float = side * (HALF_WIDTH - 0.03)
			_box(Vector3(2.4, 0.5, 0.04), Vector3(x, 1.9, z), _mat.plaque, 1.0, false)
			var label := Label3D.new()
			label.text = "Monceau"
			label.font_size = 40
			label.pixel_size = 0.006
			label.modulate = Color(0.95, 0.95, 0.9)
			label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			label.position = Vector3(x, 1.9, z - side * 0.03)
			if side > 0.0:
				label.rotation.y = PI
			add_child(label)


func _build_lights() -> void:
	for x in range(-25, 26, 10):
		_box(Vector3(3.0, 0.08, 0.25), Vector3(x, SPRING + RISE - 0.15, 0), _mat.lamp, 1.0, false)
		var light := OmniLight3D.new()
		light.position = Vector3(x, SPRING + RISE - 0.6, 0)
		light.light_color = Color(1.0, 0.92, 0.8)
		light.light_energy = 1.8
		light.omni_range = 11.0
		light.omni_attenuation = 1.2
		add_child(light)


func _build_clues() -> void:
	var quai_z := PIT_HALF_WIDTH + (HALF_WIDTH - PIT_HALF_WIDTH) * 0.5
	var end_x := HALF_LEN - 0.25

	# Porte de service en bout de quai, côté Nation.
	var door := _examinable(
		"Porte de service",
		"Porte métallique verrouillée. Autour de la serrure, des rayures fraîches dans la peinture.",
		Vector3(0.08, 2.1, 0.9), Vector3(end_x, 1.05, quai_z + 0.6), _mat.door)
	add_child(door)
	_box(Vector3(0.05, 0.25, 0.9), Vector3(end_x - 0.05, 2.35, quai_z + 0.6), _mat.sign, 1.0, false)
	var sign_label := Label3D.new()
	sign_label.text = "DESCENTE INTERDITE"
	sign_label.font_size = 24
	sign_label.pixel_size = 0.0035
	sign_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sign_label.position = Vector3(end_x - 0.08, 2.35, quai_z + 0.6)
	sign_label.rotation.y = -PI * 0.5
	add_child(sign_label)

	# Badge glissé sous le dernier siège du quai.
	var badge := _examinable(
		"Badge RATP",
		"Une carte d'agent glissée sous le siège. Photo d'identité : Karim Benali.",
		Vector3(0.09, 0.01, 0.055), Vector3(26.85, 0.006, HALF_WIDTH - 0.45), _mat.lamp)
	add_child(badge)


func _box(size: Vector3, pos: Vector3, mat: Material, tile: float, collide := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = PsxKit.box_mesh(size, pos, tile)
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	if collide:
		_collider(size, pos)
	return mesh


func _collider(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	body.position = pos
	add_child(body)


func _examinable(title: String, text: String, size: Vector3, pos: Vector3, mat: Material) -> Examinable:
	var item := Examinable.new()
	item.title = title
	item.description = text
	item.position = pos
	var mesh := MeshInstance3D.new()
	mesh.mesh = PsxKit.box_mesh(size, pos, 1.0)
	mesh.material_override = mat
	item.add_child(mesh)
	# Zone de visée un peu plus large que l'objet, pour les petits indices.
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size.max(Vector3(0.2, 0.2, 0.2))
	item.add_child(shape)
	return item
