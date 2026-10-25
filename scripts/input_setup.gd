extends Node
## Déclare les contrôles au lancement : clavier (touches physiques, donc ZQSD
## sur AZERTY et WASD sur QWERTY), souris et manette.

const DEADZONE := 0.2

func _ready() -> void:
	_action("move_forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_back", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("look_left", [], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_action("look_right", [], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_action("look_up", [], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_action("look_down", [], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_action("run", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK], [])
	_action("interact", [KEY_E], [JOY_BUTTON_A], [], [MOUSE_BUTTON_LEFT])
	_action("phone", [KEY_TAB], [JOY_BUTTON_Y], [])
	_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START], [])


func _action(action: StringName, keys: Array, buttons: Array, axes: Array, mouse: Array = []) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		InputMap.action_add_event(action, ev)
	for axis in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis[0]
		ev.axis_value = axis[1]
		InputMap.action_add_event(action, ev)
	for button in mouse:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		InputMap.action_add_event(action, ev)
