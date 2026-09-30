extends Node2D
const PixelFont = preload("res://scripts/pixel_font.gd")
var world: Node
var message := ""
var message_time := 0.0
var clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		get_tree().paused = not get_tree().paused
		# Clear queued gameplay edges so resuming never spends an old jump or dash.
		world.player.jump_buffer = 0.0
		world.player.dash_buffer = false
		world.player.fire_buffer = false
	if event.is_action_pressed("restart") and not event.is_echo():
		world.restart()
	if event.is_action_pressed("fullscreen") and not event.is_echo():
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event.is_action_pressed("mute") and not event.is_echo():
		world.sound.muted = not world.sound.muted
		if world.sound.muted:
			for voice: AudioStreamPlayer in world.sound.voices:
				voice.stop()
		toast("SOUND OFF" if world.sound.muted else "SOUND ON")

func toast(text: String) -> void:
	message = text
	message_time = 2.7

func _process(delta: float) -> void:
	clock += delta
	if not get_tree().paused:
		message_time = maxf(0, message_time - delta)
	queue_redraw()

func _draw() -> void:
	var mint := Color("a5f4cf")
	var muted := Color("718391")
	draw_rect(Rect2(0, 0, 640, 43), Color("0c1520"))
	draw_rect(Rect2(16, 42, 608, 1), Color("233740"))
	PixelFont.write(self, "BD", Vector2(18, 13), mint, 2)
	PixelFont.write(self, "SUIT", Vector2(62, 9), muted)
	for i in range(5):
		draw_rect(Rect2(62 + i * 13, 22, 10, 7), mint if i < world.player.health else Color("233740"))
	PixelFont.write(self, "DASH", Vector2(143, 9), muted)
	draw_rect(Rect2(143, 24, 50, 3), Color("233740"))
	draw_rect(Rect2(143, 24, 50 * (1.0 - world.player.dash_cooldown / 0.48), 3), Color("51c9bd"))
	PixelFont.centered(self, "THE FOUNDRY", Vector2(320, 13), muted)
	PixelFont.write(self, "01", Vector2(419, 13), Color("efa35f"), 2)
	PixelFont.write(self, "SECTOR CLEARED" if world.won else "DISABLE REACTOR", Vector2(470, 10), muted)
	PixelFont.write(self, "EXIT OPEN" if world.exit_open else "EXIT LOCKED", Vector2(470, 24), Color("51c9bd"))
	draw_rect(Rect2(609, 13, 3, 3), mint if int(clock) % 2 == 0 else Color("277e83"))
	draw_rect(Rect2(0, 340, 640, 20), Color("0c1520"))
	PixelFont.write(self, "A D MOVE / SPACE JUMP / J FIRE / SHIFT DASH", Vector2(16, 347), muted)
	PixelFont.write(self, "ESC PAUSE / R RESET", Vector2(511 - 18, 347), muted)
	if message_time > 0:
		var width: int = message.length() * 6 + 24
		draw_rect(Rect2(320 - width / 2.0, 56, width, 23), Color("1a3037"))
		PixelFont.centered(self, message, Vector2(320, 64), mint)
	if world.player.dead:
		panel("SIGNAL LOST", "RETURNING TO CHECKPOINT" if world.checkpoint_active else "REBOOTING SUIT", Color("da6f86"))
	elif world.won:
		panel("FOUNDRY CLEARED", "THE DUST HAS SETTLED.", mint)
		PixelFont.centered(self, "%02d:%02d / %d ENEMIES / %d CRATES" % [int(world.elapsed) / 60, int(world.elapsed) % 60, world.kills, world.crates_broken], Vector2(320, 213), muted)
		PixelFont.centered(self, "R / PLAY AGAIN", Vector2(320, 239), mint)
	elif get_tree().paused:
		panel("PAUSED", "ESC / RESUME", mint)
		PixelFont.centered(self, "W S / AIM VERTICALLY   M / SOUND   F11 / FULLSCREEN", Vector2(320, 215), muted)
		PixelFont.centered(self, "GAMEPAD / LEFT STICK   A JUMP   X FIRE   B DASH", Vector2(320, 238), muted)

func panel(title: String, subtitle: String, color: Color) -> void:
	draw_rect(Rect2(0, 43, 640, 297), Color(0.025, 0.045, 0.07, 0.78))
	draw_rect(Rect2(76, 127, 488, 134), Color("111f2c"))
	draw_rect(Rect2(76, 127, 488, 2), color)
	PixelFont.centered(self, title, Vector2(320, 155), color, 3)
	PixelFont.centered(self, subtitle, Vector2(320, 190), Color("a5b7ba"))
