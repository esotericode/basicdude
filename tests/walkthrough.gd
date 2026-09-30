extends SceneTree
## A complete run using only normal movement, jump and fire input.
var game: Node2D
var jump_points := [532.0, 653.0, 1018.0, 1168.0, 1348.0, 1555.0]
var next_jump := 0
var release_jump := 0

func _initialize() -> void:
	call_deferred("run")

func event(action: String, pressed: bool) -> void:
	var input := InputEventAction.new()
	input.action = action
	input.pressed = pressed
	Input.parse_input_event(input)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(15):
		await physics_frame
	event("right", true)
	event("fire", true)
	for frame in range(6000):
		await physics_frame
		if next_jump < jump_points.size() and game.player.position.x >= jump_points[next_jump] and game.player.is_on_floor():
			print("Jump ", next_jump, " at ", game.player.position)
			event("jump", true)
			release_jump = frame + 40
			next_jump += 1
		if frame == release_jump:
			event("jump", false)
		if game.player.dead:
			push_error("Walkthrough died at " + str(game.player.position))
			quit(1)
			return
		if game.won:
			print("PASS: full level cleared with normal input in %.2fs; health %d; enemies %d; crates %d" % [game.elapsed, game.player.health, game.kills, game.crates_broken])
			quit(0)
			return
		if frame % 600 == 0:
			print("Progress ", game.player.position, " / health ", game.player.health)
	push_error("Walkthrough timed out at " + str(game.player.position))
	quit(1)
