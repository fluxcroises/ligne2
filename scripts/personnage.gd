class_name Personnage
extends Examinable
## Un personnage à qui parler : silhouette low-poly à la PS1, sans visage détaillé, faite de
## quelques boîtes. Viser et appuyer sur E ouvre son dialogue (Chapitre1.DIALOGUES).
## Il respire, et se tourne vers le détective pendant la conversation.

const PSX_SHADER := preload("res://shaders/psx.gdshader")
const BLANC := preload("res://textures/blanc.png")

## Clé du dialogue dans Chapitre1.DIALOGUES.
var dialogue_id := ""
## Couleurs : veste, pantalon, peau, cheveux, et en option une casquette ou un bonnet.
var look := {"coat": Color("#2a3346"), "pants": Color("#23262c"), "skin": Color("#a8785a"),
	"hair": Color("#2a2420"), "hat": Color.TRANSPARENT, "vest": Color.TRANSPARENT}
var sitting := false

var _body: Node3D
var _time := randf() * 10.0
var _face_target := NAN


func _init(id: String, title_text: String, colors: Dictionary, seated := false) -> void:
	dialogue_id = id
	title = title_text
	look.merge(colors, true)
	sitting = seated


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var b := PsxBuilder.new()
	if sitting:
		_build_sitting(b)
	else:
		_build_standing(b)
	b.build(_body)
	var shape := CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	shape.shape.radius = 0.32 if not sitting else 0.45
	shape.shape.height = 1.75 if not sitting else 0.95
	shape.position.y = shape.shape.height / 2
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	_body.position.y = sin(_time * 1.6) * 0.008      # respiration
	if not is_nan(_face_target):
		rotation.y = lerp_angle(rotation.y, _face_target, minf(1.0, delta * 6.0))


## Se tourner vers un point (pendant le dialogue) ; NAN pour garder sa pose.
func face(point: Vector3) -> void:
	if sitting:
		return
	var d := point - global_position
	_face_target = atan2(-d.x, -d.z)


func _build_standing(b: PsxBuilder) -> void:
	for side in [-1, 1]:
		_part(b, Vector3(0.15, 0.86, 0.17), Vector3(side * 0.095, 0.43, 0), look.pants)        # jambes
		_part(b, Vector3(0.16, 0.08, 0.26), Vector3(side * 0.095, 0.04, -0.04), Color("#141414"))  # chaussures
		_part(b, Vector3(0.11, 0.62, 0.13), Vector3(side * 0.27, 1.13, 0), look.coat)           # bras
		_part(b, Vector3(0.09, 0.09, 0.1), Vector3(side * 0.27, 0.78, 0), look.skin)            # mains
	_part(b, Vector3(0.44, 0.64, 0.25), Vector3(0, 1.16, 0), look.coat)                        # buste
	if look.vest.a > 0.0:
		_part(b, Vector3(0.46, 0.4, 0.27), Vector3(0, 1.22, 0), look.vest)
	_head(b, Vector3(0, 1.6, 0))


func _build_sitting(b: PsxBuilder) -> void:
	# assis contre le mur, jambes allongées devant lui (vers -z), sous une couverture
	_part(b, Vector3(0.36, 0.2, 0.9), Vector3(0, 0.1, -0.5), look.pants)
	_part(b, Vector3(0.46, 0.6, 0.3), Vector3(0, 0.45, 0.02), look.coat)
	for side in [-1, 1]:
		_part(b, Vector3(0.11, 0.42, 0.13), Vector3(side * 0.27, 0.42, -0.05), look.coat)
	_head(b, Vector3(0, 0.9, 0.0))


func _head(b: PsxBuilder, at: Vector3) -> void:
	_part(b, Vector3(0.1, 0.08, 0.1), at - Vector3(0, 0.15, 0), look.skin)                      # cou
	b.add(PsxGeo.sphere(0.12, 6, 4), _material(look.skin), PsxGeo.xf(at, Vector3.ZERO, Vector3(0.9, 1.1, 0.95)))
	b.add(PsxGeo.sphere(0.13, 6, 3, 0, TAU, 0, PI / 2), _material(look.hair), PsxGeo.xf(at + Vector3(0, 0.02, 0.01)))
	if look.hat.a > 0.0:
		b.add(PsxGeo.cylinder(0.13, 0.14, 0.08, 6), _material(look.hat), PsxGeo.xf(at + Vector3(0, 0.1, 0)))
		_part(b, Vector3(0.2, 0.02, 0.1), at + Vector3(0, 0.07, -0.15), look.hat)              # visière


func _part(b: PsxBuilder, size: Vector3, at: Vector3, color: Color) -> void:
	b.add(PsxGeo.box(size.x, size.y, size.z), _material(color), PsxGeo.xf(at))


var _materials := {}


func _material(color: Color) -> ShaderMaterial:
	if not _materials.has(color):
		var m := ShaderMaterial.new()
		m.shader = PSX_SHADER
		m.set_shader_parameter("albedo_texture", BLANC)
		m.set_shader_parameter("albedo_color", Vector3(color.r, color.g, color.b))
		_materials[color] = m
	return _materials[color]
