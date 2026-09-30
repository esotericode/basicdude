extends SceneTree
## Integration checks use real input events and the running Godot physics loop.
const Scene = preload("res://scenes/main.tscn")
const Pixels = preload("res://scripts/pixels.gd")
var game: Node2D
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func event(action: String, pressed: bool) -> void:
	var input := InputEventAction.new()
	input.action = action
	input.pressed = pressed
	Input.parse_input_event(input)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func reset(at: Vector2 = Vector2(94, 296)) -> void:
	for action in ["left", "right", "up", "down", "jump", "fire", "dash"]:
		event(action, false)
	game.restart()
	game.player.position = at
	await ticks(8)

func freeze_enemies() -> void:
	for target in game.targets:
		if is_instance_valid(target) and target.get_script() == preload("res://scripts/enemy.gd"):
			target.set_physics_process(false)

func run() -> void:
	game = Scene.instantiate()
	root.add_child(game)
	await ticks(12)
	check(game.player.is_on_floor(), "player settles on the floor")
	check(InputMap.action_has_event("fire", joy_button(JOY_BUTTON_X)), "gamepad fire is mapped")
	check(Pixels.segment_rect(Vector2(0, 5), Vector2(100, 5), Rect2(40, 0, 2, 10)) < 1, "swept projectile finds a two-pixel target")
	check(Pixels.segment_rect(Vector2(0, 20), Vector2(100, 20), Rect2(40, 0, 2, 10)) == INF, "projectile misses outside target")
	event("right", true)
	await ticks(10)
	check(game.player.velocity.x >= 180, "run reaches full speed within 83ms")
	event("right", false)
	await ticks(9)
	check(absf(game.player.velocity.x) < 1, "release stops movement within 75ms")
	game.player.health = 2
	game.player.hurt(1)
	game.player.hurt(1)
	check(game.player.health == 1 and not game.player.dead, "invulnerability protects the final health point")
	await reset()
	var floor_y: float = game.player.position.y
	event("jump", true)
	await ticks(2)
	check(game.player.velocity.y < -300, "jump starts on the next physics step")
	await ticks(40)
	check(floor_y - game.player.position.y > 50, "held jump reaches useful platform height")
	event("jump", false)
	await reset()
	event("jump", true)
	await ticks(3)
	event("jump", false)
	await ticks(22)
	check(300 - game.player.position.y < 30, "early release gives a short jump")
	await reset(Vector2(791, 296))
	event("right", true)
	for i in range(40):
		await ticks(1)
		if not game.player.is_on_floor():
			break
	await ticks(2)
	check(not game.player.is_on_floor() and game.player.coyote > 0, "ledge departure leaves a brief coyote window")
	event("jump", true)
	await ticks(2)
	check(game.player.velocity.y < -300, "jump works shortly after leaving a ledge")
	await reset(Vector2(200, 254))
	# Wait until just before landing, then press jump while still airborne.
	while game.player.position.y < 291:
		await ticks(1)
	event("jump", true)
	await ticks(10)
	check(game.player.velocity.y < -250, "buffered jump fires on landing")
	await reset()
	event("dash", true)
	await ticks(2)
	check(absf(game.player.velocity.x) > 350, "dash responds immediately")
	event("dash", false)
	await ticks(2)
	event("dash", true)
	var cooldown: float = game.player.dash_cooldown
	await ticks(2)
	check(game.player.dash_cooldown < cooldown, "dash cannot reset its own cooldown")
	await reset(Vector2(336, 296))
	freeze_enemies()
	var crate: Node = game.targets[0]
	var intact: int = crate.sprite.cells.size()
	event("fire", true)
	await ticks(18)
	check(is_instance_valid(crate) and crate.health < 5 and crate.sprite.cells.size() < intact, "projectile chips real pixels off a crate")
	check(game.debris.fragments.size() > 0, "removed pixels become debris")
	await ticks(130)
	event("fire", false)
	check(not is_instance_valid(crate), "repeated fire fully breaks a crate")
	await reset(Vector2(550, 296))
	freeze_enemies()
	var enemy: Node = game.targets[9]
	var before: int = enemy.sprite.cells.size()
	event("fire", true)
	await ticks(20)
	check(is_instance_valid(enemy) and enemy.health < 4 and enemy.sprite.cells.size() < before, "enemy flashes and loses model pixels on impact")
	await ticks(90)
	event("fire", false)
	check(not is_instance_valid(enemy) and game.kills == 1, "enemy shatters after enough hits")
	await reset(Vector2(2320, 296))
	freeze_enemies()
	event("fire", true)
	await ticks(240)
	event("fire", false)
	check(game.exit_open, "sustained horizontal fire destroys the reactor and unlocks the exit")
	game.player.position = Vector2(2600, 296)
	await ticks(3)
	check(game.won, "reaching the unlocked exit completes the level")
	await reset(Vector2(1370, 296))
	await ticks(4)
	check(game.checkpoint_active, "walking into checkpoint activates it")
	game.player.hurt(5)
	await ticks(160)
	check(not game.player.dead and game.player.health == 5 and game.player.position.x > 1300, "death restores the suit at the checkpoint")
	var position_before: Vector2 = game.player.position
	event("pause", true)
	await process_frame
	check(paused, "pause freezes the scene tree")
	event("pause", false)
	await process_frame
	event("pause", true)
	await process_frame
	check(not paused and game.player.position.distance_to(position_before) < 1, "resume preserves the paused position")
	event("pause", false)
	game.debris.fragments.clear()
	game.debris.spawn(Vector2(200, 280), Color.RED, Vector2.ZERO)
	await ticks(170)
	check(game.debris.fragments.size() == 1 and game.debris.fragments[0].sleep and absf(game.debris.fragments[0].p.y - 298) < 0.1, "fragment bounces and sleeps on the ground")
	for i in range(1100):
		game.debris.spawn(Vector2(200, 270), Color.RED, Vector2.ZERO)
	check(game.debris.fragments.size() == game.debris.MAX_FRAGMENTS, "debris count is bounded during sustained destruction")
	print("\n", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func joy_button(button: int) -> InputEventJoypadButton:
	var input := InputEventJoypadButton.new()
	input.button_index = button
	return input
