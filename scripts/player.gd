extends CharacterBody3D
## Le détective, en vue subjective. On ne le voit jamais.

signal focus_changed(examinable: Examinable)
signal examined(examinable: Examinable)

@export var walk_speed := 1.8
@export var run_speed := 3.6
@export var acceleration := 12.0
@export var mouse_sensitivity := 0.0025
@export var pad_look_speed := 2.4
@export var bob_amount := 0.025

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_time := 0.0
var _focused: Examinable = null
var _head_height := 0.0


func _ready() -> void:
	add_to_group("player")
	_head_height = head.position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		_look(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
	elif event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _focused:
		examined.emit(_focused)


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	head.rotation.x = clampf(head.rotation.x + pitch, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick != Vector2.ZERO:
		_look(-stick.x * pad_look_speed * delta, -stick.y * pad_look_speed * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).limit_length(1.0)
	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	move_and_slide()

	_update_bob(delta)
	_update_focus()


func _update_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		_bob_time += delta * horizontal_speed * 4.0
	else:
		_bob_time = lerpf(_bob_time, roundf(_bob_time / PI) * PI, delta * 8.0)
	head.position.y = _head_height + absf(sin(_bob_time)) * bob_amount


func _update_focus() -> void:
	var hit: Examinable = ray.get_collider() as Examinable if ray.is_colliding() else null
	if hit != _focused:
		_focused = hit
		focus_changed.emit(_focused)
