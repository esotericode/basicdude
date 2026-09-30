extends CharacterBody2D
const Pixels = preload("res://scripts/pixels.gd")
const Art = preload("res://scripts/art.gd")
var world: Node
var sprite: Node2D
var kind := "walker"
var health := 4
var anchor := Vector2.ZERO
var patrol := Vector2.ZERO
var direction := -1
var clock := 0.0
var stagger := 0.0
var alive := true
var shot_timer := 1.5

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 4
	anchor = position
	clock = position.x / 90
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(22, 24)
	shape.shape = rectangle
	shape.position.y = -12
	add_child(shape)
	sprite = Pixels.new()
	add_child(sprite)
	if kind == "drone":
		health = 3
		collision_mask = 0
		sprite.build(Art.DRONE, Vector2(-14, -22))
	else:
		sprite.build(Art.WALKER, Vector2(-14, -28))

func _physics_process(delta: float) -> void:
	if not alive:
		return
	clock += delta
	stagger = maxf(0, stagger - delta)
	if kind == "drone":
		position = anchor + Vector2(sin(clock * 1.2) * 36, sin(clock * 2.3) * 9)
		shot_timer -= delta
		if shot_timer <= 0 and absf(world.player.position.x - position.x) < 280 and not world.player.dead:
			shot_timer = 2.2
			var direction_to_player: Vector2 = (world.player.position + Vector2(0, -15) - (position + Vector2(0, -10))).normalized()
			world.enemy_shoot(position + Vector2(0, -10), direction_to_player)
	else:
		if position.x <= patrol.x:
			direction = 1
		elif position.x >= patrol.y:
			direction = -1
		if is_on_floor() and not world.has_floor(position + Vector2(direction * 18, 3)):
			direction *= -1
		velocity.x = move_toward(velocity.x, direction * (12.0 if stagger > 0 else 38.0), 600 * delta)
		velocity.y += 1300 * delta
		move_and_slide()
		if is_on_wall():
			direction *= -1
		sprite.facing = direction
		sprite.queue_redraw()
	if not world.player.dead and position.distance_to(world.player.position) < 22:
		world.player.hurt(1, position)
	queue_redraw()

func hit(point: Vector2, impulse: Vector2) -> void:
	if not alive:
		return
	health -= 1
	stagger = 0.13
	velocity.x += impulse.x * 0.3
	sprite.chip(world, point, impulse * 0.65, 9)
	world.impact(point, Color("ffd4b0"), 5)
	world.sound.play("hit")
	world.kick(0.7)
	if health <= 0:
		alive = false
		sprite.shatter(world, impulse * 0.4)
		world.kills += 1
		world.sound.play("break")
		world.kick(1.6)
		collision_layer = 0
		collision_mask = 0
		queue_free()

func _draw() -> void:
	if kind == "walker":
		Art.shadow(self, 28)
	elif alive:
		var glow := Color("da6f86")
		glow.a = 0.2 + 0.1 * sin(clock * 5)
		draw_rect(Rect2(-5, 0, 10, 3), glow)
