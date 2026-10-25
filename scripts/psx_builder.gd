class_name PsxBuilder
extends RefCounted
## Accumule la géométrie statique par matériau, puis la fusionne en un seul maillage
## par matériau (quelques dizaines d'appels de dessin pour toute la station).

var _surfaces := {}  # Material -> [SurfaceTool, nombre de sommets]


func add(geo: Dictionary, mat: Material, xform: Transform3D) -> void:
	if not _surfaces.has(mat):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[mat] = [tool, 0]
	var entry: Array = _surfaces[mat]
	var st: SurfaceTool = entry[0]
	var base: int = entry[1]
	var normal_basis := xform.basis.inverse().transposed()
	var p: Array = geo.p
	var n: Array = geo.n
	var uv: Array = geo.uv
	for k in p.size():
		st.set_normal((normal_basis * n[k]).normalized())
		# three.js retourne les images : son v = 0 est le bas de la texture.
		st.set_uv(Vector2(uv[k].x, 1.0 - uv[k].y))
		st.add_vertex(xform * p[k])
	for idx in geo.i:
		st.add_index(base + idx)
	entry[1] = base + p.size()


func build(parent: Node3D) -> void:
	for mat in _surfaces:
		var mesh := MeshInstance3D.new()
		mesh.mesh = _surfaces[mat][0].commit()
		mesh.material_override = mat
		parent.add_child(mesh)
	_surfaces.clear()
