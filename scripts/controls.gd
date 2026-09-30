extends RefCounted

static func install() -> void:
	bind("left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	bind("right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	bind("up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	bind("down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	bind("jump", [KEY_SPACE, KEY_Z], [JOY_BUTTON_A])
	bind("fire", [KEY_J, KEY_X], [JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER])
	bind("dash", [KEY_SHIFT, KEY_K, KEY_C], [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER])
	bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	bind("restart", [KEY_R], [JOY_BUTTON_BACK])
	bind("fullscreen", [KEY_F11], [])
	bind("mute", [KEY_M], [])
	Input.use_accumulated_input = false
	Engine.max_fps = 240

static func bind(action: String, keys: Array, buttons: Array, axis: int = -1, value: float = 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.25)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)
	if axis >= 0:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = value
		InputMap.action_add_event(action, event)
