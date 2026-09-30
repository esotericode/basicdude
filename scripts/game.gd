extends Node2D
const Controls = preload("res://scripts/controls.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Breakable = preload("res://scripts/breakable.gd")
const Debris = preload("res://scripts/debris.gd")
const Sound = preload("res://scripts/sound.gd")
const HUD = preload("res://scripts/hud.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const Pixels = preload("res://scripts/pixels.gd")
const Art = preload("res://scripts/art.gd")
const LEVEL_WIDTH := 2688.0
const EXIT_X := 2590.0
const GATE_RECT := Rect2(2464, 206, 12, 94)
const CHECKPOINT := Vector2(1370, 300)
var player: CharacterBody2D
var debris: Node2D
var sound: Node
var camera: Camera2D
var hud: Node2D
var actors: Node2D
var gate: StaticBody2D
var targets: Array = []
var terrain: Array[Rect2] = []
var bullets: Array = []
var effects: Array = []
var kills := 0
var crates_broken := 0
var checkpoint_active := false
var exit_open := false
var won := false
var death_timer := 0.0
var elapsed := 0.0
var shake := 0.0
var camera_x := 320.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Controls.install()
	rng.seed = 42
	sound = Sound.new()
	add_child(sound)
	debris = Debris.new()
	debris.world = self
	add_child(debris)
	camera = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	hud = HUD.new()
	hud.world = self
	layer.add_child(hud)
	build_level()
	get_window().focus_exited.connect(_on_focus_exited)

func _on_focus_exited() -> void:
	if DisplayServer.get_name() != "headless":
		get_tree().paused = true

func build_level() -> void:
	if is_instance_valid(actors):
		remove_child(actors)
		actors.queue_free()
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	bullets.clear()
	effects.clear()
	targets.clear()
	debris.fragments.clear()
	kills = 0
	crates_broken = 0
	exit_open = false
	won = false
	death_timer = 0.0
	terrain = [
		Rect2(0, 300, 800, 120), Rect2(872, 300, 744, 120), Rect2(1700, 300, 988, 120),
		Rect2(556, 252, 116, 12), Rect2(744, 218, 112, 12),
		Rect2(1040, 245, 140, 12), Rect2(1250, 208, 112, 12),
		Rect2(1460, 252, 112, 12), Rect2(1610, 235, 110, 12),
		Rect2(1860, 244, 120, 12), Rect2(2100, 216, 112, 12),
	]
	for rect in terrain:
		add_solid(rect)
	add_solid(Rect2(-16, 0, 16, 420))
	add_solid(Rect2(LEVEL_WIDTH, 0, 16, 420))
	gate = add_solid(GATE_RECT)
	player = Player.new()
	player.world = self
	player.position = CHECKPOINT + Vector2(0, -4) if checkpoint_active else Vector2(94, 296)
	actors.add_child(player)
	for point in [Vector2(394, 300), Vector2(426, 300), Vector2(1010, 300), Vector2(1130, 245), Vector2(1900, 300), Vector2(1932, 300), Vector2(2160, 216), Vector2(2260, 300)]:
		add_breakable(point)
	add_breakable(Vector2(2380, 300), true)
	add_enemy(Vector2(635, 300), "walker", Vector2(560, 735))
	add_enemy(Vector2(1010, 300), "walker", Vector2(912, 1190))
	add_enemy(Vector2(1240, 206), "drone")
	add_enemy(Vector2(1530, 300), "walker", Vector2(1430, 1580))
	add_enemy(Vector2(1790, 214), "drone")
	add_enemy(Vector2(2040, 300), "walker", Vector2(1985, 2130))
	add_enemy(Vector2(2260, 192), "drone")
	camera_x = clampf(player.position.x + 64, 320, LEVEL_WIDTH - 320)
	camera.position = Vector2(camera_x, 180)
	queue_redraw()

func add_solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size / 2
	body.add_child(shape)
	actors.add_child(body)
	return body

func add_breakable(point: Vector2, is_core: bool = false) -> void:
	var object := Breakable.new()
	object.position = point
	object.world = self
	object.core = is_core
	actors.add_child(object)
	targets.append(object)

func add_enemy(point: Vector2, kind: String, patrol: Vector2 = Vector2.ZERO) -> void:
	var enemy := Enemy.new()
	enemy.position = point
	enemy.kind = kind
	enemy.world = self
	enemy.patrol = patrol
	actors.add_child(enemy)
	targets.append(enemy)

func shoot(from: Vector2, direction: Vector2) -> void:
	bullets.append({"p": from, "prev": from, "d": direction, "age": 0.0, "enemy": false})
	sound.play("shot")

func enemy_shoot(from: Vector2, direction: Vector2) -> void:
	bullets.append({"p": from, "prev": from, "d": direction, "age": 0.0, "enemy": true})
	impact(from, Color("da6f86"), 3)

func _physics_process(delta: float) -> void:
	if not won:
		elapsed += delta
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0:
			build_level()
	if not player.dead and not won:
		if not checkpoint_active and player.position.distance_to(CHECKPOINT) < 32:
			checkpoint_active = true
			player.health = 5
			sound.play("checkpoint")
			hud.toast("CHECKPOINT ONLINE / SUIT RESTORED")
		if exit_open and player.position.x > EXIT_X:
			won = true
			player.set_physics_process(false)
			player.set_process_input(false)
			player.queue_redraw()
			sound.play("checkpoint")
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.age += delta
		if bullet.age > 2.0:
			bullets.remove_at(i)
			continue
		var from: Vector2 = bullet.p
		var to: Vector2 = from + bullet.d * (175.0 if bullet.enemy else 650.0) * delta
		var best := INF
		var target: Node = null
		for rect: Rect2 in terrain:
			best = minf(best, Pixels.segment_rect(from, to, rect.grow(1)))
		if not exit_open:
			best = minf(best, Pixels.segment_rect(from, to, GATE_RECT.grow(1)))
		if bullet.enemy:
			if not player.dead:
				var hit: float = Pixels.segment_rect(from, to, Rect2(player.position + Vector2(-8, -28), Vector2(16, 28)).grow(2))
				if hit < best:
					best = hit
					target = player
		else:
			for object in targets:
				if not is_instance_valid(object) or not object.alive:
					continue
				if from.distance_squared_to(object.position) > 10000:
					continue
				var hit: float = object.sprite.ray_hit(from, to)
				if hit < best:
					best = hit
					target = object
		if best < INF:
			var point := from.lerp(to, best)
			if is_instance_valid(target):
				if target == player:
					player.hurt(1, point)
				else:
					target.hit(point, bullet.d * 150)
			else:
				impact(point, Color("718391"), 3)
			bullets.remove_at(i)
		else:
			bullet.prev = from
			bullet.p = to
	for i in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[i]
		effect.life -= delta
		if effect.life <= 0:
			effects.remove_at(i)
		else:
			effect.p += effect.v * delta
	shake = maxf(0, shake - 14 * delta)
	var lead: float = player.facing * 54.0
	var desired := clampf(player.position.x + lead, 320, LEVEL_WIDTH - 320)
	# Movement is immediate; only the view eases toward its look-ahead point.
	camera_x = lerpf(camera_x, desired, 1.0 - exp(-9.0 * delta))
	camera.position = Vector2(roundf(camera_x), 180)
	camera.offset = Vector2(roundf(rng.randf_range(-shake, shake)), roundf(rng.randf_range(-shake, shake)))
	queue_redraw()

func landing_surface(previous: Vector2, next: Vector2, size: int) -> float:
	if next.y < previous.y:
		return INF
	var best := INF
	for rect: Rect2 in terrain:
		if previous.y + size <= rect.position.y + 0.5 and next.y + size >= rect.position.y:
			var fraction := (rect.position.y - size - previous.y) / maxf(0.001, next.y - previous.y)
			var x := lerpf(previous.x, next.x, clampf(fraction, 0, 1))
			if x + size > rect.position.x and x < rect.end.x:
				best = minf(best, rect.position.y)
	return best

func has_floor(point: Vector2) -> bool:
	for rect: Rect2 in terrain:
		if rect.has_point(point):
			return true
	return false

func trail(point: Vector2, direction: int) -> void:
	if effects.size() < 100:
		effects.append({"p": point, "v": Vector2.ZERO, "life": 0.08, "max": 0.08, "c": Color("51c9bd"), "trail": direction})

func impact(point: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle := TAU * i / count
		effects.append({"p": point, "v": Vector2.from_angle(angle) * 80, "life": 0.1, "max": 0.1, "c": color, "trail": 0})

func kick(amount: float) -> void:
	shake = maxf(shake, amount)

func on_death() -> void:
	death_timer = 1.25

func open_exit() -> void:
	exit_open = true
	gate.collision_layer = 0
	gate.queue_free()
	hud.toast("REACTOR OFFLINE / EXIT UNLOCKED >")
	for i in range(35):
		debris.spawn(Vector2(2470, 208 + i * 2.5), Color("da6f86"), Vector2(rng.randf_range(-70, 70), 0))

func restart() -> void:
	get_tree().paused = false
	checkpoint_active = false
	elapsed = 0
	build_level()

func _draw() -> void:
	draw_backdrop()
	for rect: Rect2 in terrain:
		draw_terrain(rect)
	draw_signs()
	draw_checkpoint()
	draw_exit()
	for bullet: Dictionary in bullets:
		var color := Color("da6f86") if bullet.enemy else Color("a5f4cf")
		var p: Vector2 = bullet.p.round()
		for i in range(3):
			var tail: Vector2 = (p - bullet.d * i * 4).round()
			var tint := color
			tint.a = 1.0 - i * 0.25
			draw_rect(Rect2(tail - Vector2(2, 2), Vector2(4, 4)), tint)
		draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), Color("e8ffe2"))
	for effect: Dictionary in effects:
		var tint: Color = effect.c
		tint.a = effect.life / effect.max * 0.5
		if effect.trail != 0:
			draw_rect(Rect2(effect.p + Vector2(-8, -28), Vector2(16, 26)), tint)
		else:
			draw_rect(Rect2(effect.p.round(), Vector2(2, 2)), effect.c)

func draw_backdrop() -> void:
	var left := camera_x - 340
	draw_rect(Rect2(left, -20, 680, 440), Color("0c1520"))
	# Distant factory silhouettes shift slowly behind the playable layer.
	for i in range(-1, 11):
		var x := float(i * 164) + floorf(camera_x * 0.72)
		draw_rect(Rect2(x, 82, 106, 210), Color("111f2c"))
		draw_rect(Rect2(x + 14, 68, 76, 14), Color("111f2c"))
		for y in [106, 132, 158, 184]:
			for w in [18, 44, 70]:
				draw_rect(Rect2(x + w, y, 12, 8), Color("172c38"))
	for i in range(14):
		var x := float(i * 208)
		draw_rect(Rect2(x, 0, 5, 300), Color("1a2b36"))
		draw_rect(Rect2(x + 5, 0, 2, 300), Color("233943"))
		for y in range(40, 300, 56):
			draw_rect(Rect2(x - 3, y, 11, 3), Color("2b414c"))
		draw_rect(Rect2(x + 25, 58, 115, 2), Color("20343e"))
		draw_rect(Rect2(x + 50, 56, 32, 5), Color("2a4950"))
		draw_rect(Rect2(x + 54, 61, 24, 2), Color("466d68"))
	draw_rect(Rect2(left, 289, 680, 8), Color("152b33"))
	for i in range(0, int(LEVEL_WIDTH), 32):
		draw_rect(Rect2(i, 290, 10, 2), Color("223c43"))
	# Recessed background machinery, kept low contrast for clear silhouettes.
	for x in [900, 1188, 1750, 2010, 2330]:
		draw_rect(Rect2(x, 145, 76, 138), Color("172832"))
		draw_rect(Rect2(x + 4, 149, 68, 130), Color("0f1c27"))
		for y in range(160, 250, 12):
			draw_rect(Rect2(x + 10, y, 56, 2), Color("20343e"))
		draw_rect(Rect2(x + 10, 260, 4, 4), Color("55877a"))

func draw_terrain(rect: Rect2) -> void:
	draw_rect(rect, Color("233740"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("73918f"))
	draw_rect(Rect2(rect.position + Vector2(0, 3), Vector2(rect.size.x, 3)), Color("394f55"))
	if rect.size.y < 20:
		draw_rect(Rect2(rect.position + Vector2(0, 9), Vector2(rect.size.x, 3)), Color("101e29"))
		for x in range(int(rect.position.x) + 8, int(rect.end.x) - 3, 16):
			draw_rect(Rect2(x, rect.position.y + 6, 2, 2), Color("718391"))
	else:
		for x in range(int(rect.position.x), int(rect.end.x), 32):
			draw_rect(Rect2(x, rect.position.y + 8, 1, rect.size.y - 8), Color("1b2e38"))
			draw_rect(Rect2(x + 4, rect.position.y + 12, 2, 2), Color("394f55"))
			draw_rect(Rect2(x + 28, rect.position.y + 12, 2, 2), Color("394f55"))
			draw_rect(Rect2(x + 8, rect.position.y + 30, 16, 2), Color("1b2e38"))
		for y in range(int(rect.position.y) + 42, 420, 32):
			draw_rect(Rect2(rect.position.x, y, rect.size.x, 1), Color("1b2e38"))
		# Hazard stripes mark the edges of real gaps.
		if rect.position.x > 0:
			for i in range(3):
				draw_rect(Rect2(rect.position.x + 2 + i * 7, rect.position.y + 3, 4, 4), Color("b48b55"))
		if rect.end.x < LEVEL_WIDTH:
			for i in range(3):
				draw_rect(Rect2(rect.end.x - 23 + i * 7, rect.position.y + 3, 4, 4), Color("b48b55"))

func draw_signs() -> void:
	PixelFont.write(self, "BASICDUDE", Vector2(58, 107), Color("a5f4cf"), 5)
	PixelFont.write(self, "THE FOUNDRY", Vector2(60, 155), Color("718391"), 2)
	draw_rect(Rect2(60, 187, 29, 2), Color("efa35f"))
	PixelFont.write(self, "01 / WAKE THE DUST", Vector2(100, 184), Color("718391"))
	PixelFont.write(self, "A D  MOVE    SPACE  JUMP", Vector2(60, 229), Color("a5b7ba"))
	PixelFont.write(self, "J  FIRE      SHIFT  DASH", Vector2(60, 243), Color("a5b7ba"))
	PixelFont.write(self, "HOLD W TO AIM UP", Vector2(570, 185), Color("718391"))
	PixelFont.write(self, "MIND THE GAP >", Vector2(735, 262), Color("b48b55"))
	PixelFont.write(self, "02 / ASSEMBLY", Vector2(964, 94), Color("547579"), 2)
	PixelFont.write(self, "03 / REACTOR", Vector2(2180, 94), Color("547579"), 2)
	PixelFont.write(self, "SHOOT THE CORE", Vector2(2320, 239), Color("efa35f"))
	PixelFont.write(self, "EXIT >", Vector2(2530, 213), Color("a5f4cf"))

func draw_checkpoint() -> void:
	var color := Color("a5f4cf") if checkpoint_active else Color("718391")
	draw_rect(Rect2(CHECKPOINT + Vector2(-12, -3), Vector2(24, 3)), color)
	draw_rect(Rect2(CHECKPOINT + Vector2(-3, -50), Vector2(6, 48)), Color("394f55"))
	draw_rect(Rect2(CHECKPOINT + Vector2(-9, -54), Vector2(18, 12)), Color("233740"))
	draw_rect(Rect2(CHECKPOINT + Vector2(-6, -51), Vector2(12, 6)), color)
	PixelFont.centered(self, "CHECKPOINT", CHECKPOINT + Vector2(0, -72), color)

func draw_exit() -> void:
	draw_rect(Rect2(2580, 202, 52, 98), Color("1a3037"))
	draw_rect(Rect2(2586, 208, 40, 92), Color("0c1520"))
	draw_rect(Rect2(2586, 208, 40, 3), Color("a5f4cf") if exit_open else Color("394f55"))
	if exit_open:
		for i in range(5):
			draw_rect(Rect2(2593 + i * 6, 280 - i * 3, 3, 3), Color("51c9bd"))
	else:
		draw_rect(GATE_RECT, Color("3d2e43"))
		for y in range(210, 300, 8):
			draw_rect(Rect2(2467, y, 6, 4), Color("da6f86"))
		PixelFont.centered(self, "LOCKED", Vector2(2470, 193), Color("da6f86"))
