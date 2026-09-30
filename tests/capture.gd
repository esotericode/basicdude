extends SceneTree
## Render QA: run with a real display (or xvfb-run), never --headless.
var game: Node2D

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await ticks(20)
	await screenshot("opening")
	game.player.position = Vector2(590, 300)
	game.camera_x = 710
	game.camera.position.x = 710
	var walker: Node = game.targets[9]
	walker.set_physics_process(false)
	walker.hit(walker.position + Vector2(-10, -16), Vector2(120, -30))
	await ticks(9)
	await screenshot("combat")
	game.player.position = Vector2(2300, 300)
	game.camera_x = 2368
	game.camera.position.x = 2368
	await ticks(10)
	await screenshot("reactor")
	game.open_exit()
	game.player.position.x = 2600
	await ticks(5)
	await screenshot("complete")
	quit()

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func screenshot(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	var result := root.get_texture().get_image().save_png("res://docs/screenshots/" + label + ".png")
	print("CAPTURE ", label, ": ", result)
