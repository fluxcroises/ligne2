class_name PsxKit
## Outils pour fabriquer la géométrie et les matériaux PS1 depuis le code :
## matériaux PSX, textures dessinées en attendant les photos, boîtes à UV « monde ».

const PSX_SHADER := preload("res://shaders/psx.gdshader")

static var _white: ImageTexture


static func material(texture: Texture2D = null, color := Color.WHITE, emission := 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PSX_SHADER
	mat.set_shader_parameter("albedo_texture", texture if texture else white())
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("emission_strength", emission)
	return mat


static func white() -> ImageTexture:
	if not _white:
		var img := Image.create(1, 1, false, Image.FORMAT_RGB8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white


# --- Textures dessinées (64 px de large, comme sur PS1) ----------------------

## Carreaux blancs biseautés du métro : 4 colonnes × 8 rangées, joints gris.
static func tiles_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var tx := x % 16
			var ty := y % 8
			var c := Color(0.9, 0.89, 0.84)
			if tx == 0 or ty == 0:
				c = Color(0.55, 0.54, 0.5)
			elif tx == 1 or ty == 1:
				c = Color(0.98, 0.98, 0.95)
			elif tx == 15 or ty == 7:
				c = Color(0.74, 0.73, 0.68)
			img.set_pixel(x, y, c)
	return _texture(img)


## Sol du quai : bitume gris moucheté.
static func asphalt_texture() -> ImageTexture:
	return _noise_texture(Color(0.3, 0.3, 0.31), 0.07, 11)


## Ballast et traverses au fond des voies.
static func ballast_texture() -> ImageTexture:
	var img := _noise_image(Color(0.22, 0.2, 0.18), 0.12, 23)
	for y in 64:
		for x in range(0, 64):
			if y % 32 < 6:
				img.set_pixel(x, y, Color(0.18, 0.13, 0.09))
	return _texture(img)


## Bande d'éveil de vigilance au bord du quai : picots sur fond crème.
static func edge_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0.82, 0.78, 0.66))
	for y in 64:
		for x in 64:
			var dx := x % 8 - 3.5
			var dy := y % 8 - 3.5
			if dx * dx + dy * dy < 5.0:
				img.set_pixel(x, y, Color(0.66, 0.62, 0.5))
	return _texture(img)


## Béton sombre du tunnel.
static func tunnel_texture() -> ImageTexture:
	return _noise_texture(Color(0.16, 0.15, 0.14), 0.05, 37)


## Les mipmaps évitent le moiré du carrelage au loin ; le filtrage reste « au plus proche ».
static func _texture(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _noise_texture(base: Color, amount: float, seed_value: int) -> ImageTexture:
	return _texture(_noise_image(base, amount, seed_value))


static func _noise_image(base: Color, amount: float, seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var n := rng.randf_range(-amount, amount)
			img.set_pixel(x, y, Color(base.r + n, base.g + n, base.b + n))
	return img


# --- Géométrie ----------------------------------------------------------------

## Ajoute un quadrilatère (p0 → p3 dans l'ordre du contour) tourné vers `normal`.
static func add_quad(st: SurfaceTool, p: Array, uv: Array, normal: Vector3) -> void:
	# Godot affiche les faces dont les sommets tournent dans le sens horaire vu de face.
	var order := [0, 1, 2, 0, 2, 3]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i in order:
		st.set_normal(normal)
		st.set_uv(uv[i])
		st.add_vertex(p[i])


## Boîte dont les UV suivent les coordonnées du monde : la texture se répète tous les
## `tile` mètres et reste continue d'une boîte à l'autre.
static func box_mesh(size: Vector3, world_origin: Vector3, tile: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var axes := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP],
		[Vector3.LEFT, Vector3.FORWARD, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.BACK, Vector3.LEFT, Vector3.UP],
		[Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	for a in axes:
		var n: Vector3 = a[0]
		var u: Vector3 = a[1]
		var v: Vector3 = a[2]
		var center := n * h
		var hu := u * absf(u.dot(h))
		var hv := v * absf(v.dot(h))
		var p := [center - hu - hv, center + hu - hv, center + hu + hv, center - hu + hv]
		var uv := []
		for q in p:
			var w: Vector3 = q + world_origin
			uv.append(Vector2(w.dot(u), -w.dot(v)) / tile)
		add_quad(st, p, uv, n)
	return st.commit()
