extends CharacterBody2D
const Art = preload("res://scripts/art.gd")
const SPEED := 185.0
const JUMP_SPEED := 390.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.11
const DASH_SPEED := 380.0
var world: Node
var facing := 1
var health := 5
var coyote := 0.0
var jump_buffer := 0.0
var jump_cut := false
var fire_buffer := false
var fire_cooldown := 0.0
var invulnerable := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_buffer := false
var run_clock := 0.0
var dead := false
var aim := Vector2.RIGHT
var muzzle_flash := 0.0
var last_floor := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 5
	floor_snap_length = 4
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 28)
	shape.shape = rectangle
	shape.position.y = -14
	add_child(shape)

func _input(event: InputEvent) -> void:
	if dead:
		return
	if event.is_action_pressed("jump") and not event.is_echo():
		jump_buffer = JUMP_BUFFER
	if event.is_action_released("jump"):
		jump_cut = true
	if event.is_action_pressed("fire") and not event.is_echo():
		fire_buffer = true
	if event.is_action_pressed("dash") and not event.is_echo():
		dash_buffer = true

func _physics_process(delta: float) -> void:
	if dead:
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	muzzle_flash = maxf(0.0, muzzle_flash - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	var horizontal := Input.get_axis("left", "right")
	if absf(horizontal) > 0.1:
		facing = 1 if horizontal > 0 else -1
	var grounded := is_on_floor()
	if grounded:
		coyote = COYOTE_TIME
	else:
		coyote = maxf(0.0, coyote - delta)
	if dash_buffer and dash_cooldown <= 0:
		dash_time = 0.13
		dash_cooldown = 0.48
		world.sound.play("dash")
		world.debris.dust(position, 7)
	dash_buffer = false
	if dash_time > 0:
		dash_time = maxf(0.0, dash_time - delta)
		velocity = Vector2(facing * DASH_SPEED, 0)
		world.trail(position, facing)
	else:
		velocity.x = move_toward(velocity.x, horizontal * SPEED, (3200.0 if absf(horizontal) < 0.1 else 2600.0) * delta)
		velocity.y = minf(velocity.y + (1650.0 if velocity.y > 0 else 1250.0) * delta, 650.0)
	if jump_buffer > 0 and coyote > 0:
		velocity.y = -JUMP_SPEED
		coyote = 0.0
		jump_buffer = 0.0
		dash_time = 0.0
		world.sound.play("jump")
		world.debris.dust(position, 4)
	if jump_cut:
		if velocity.y < -120:
			velocity.y = -120
		jump_cut = false
	move_and_slide()
	position.x = clampf(position.x, 20, world.LEVEL_WIDTH - 20)
	if is_on_floor() and not last_floor:
		world.debris.dust(position, 6)
	last_floor = is_on_floor()
	if position.y > 430:
		hurt(health, Vector2.ZERO, true)
		return
	aim = Vector2(facing, 0)
	if Input.is_action_pressed("up"):
		aim = Vector2(facing if absf(horizontal) > 0.1 else 0, -1).normalized()
	elif Input.is_action_pressed("down") and not grounded:
		aim = Vector2(facing if absf(horizontal) > 0.1 else 0, 1).normalized()
	if (fire_buffer or Input.is_action_pressed("fire")) and fire_cooldown <= 0:
		var shoulder := position + Vector2(facing * 5, -18)
		world.shoot(shoulder, aim)
		fire_cooldown = 0.105
		muzzle_flash = 0.04
		fire_buffer = false
	run_clock += delta * absf(velocity.x) / 14.0
	queue_redraw()

func hurt(amount: int = 1, source: Vector2 = Vector2.ZERO, forced: bool = false) -> void:
	if dead or (not forced and (invulnerable > 0 or dash_time > 0)):
		return
	health = maxi(0, health - amount)
	invulnerable = 1.1
	velocity.y = -130
	world.sound.play("hurt")
	world.kick(2.0)
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, 0.25, 0.4, 0.1)
	if health == 0:
		dead = true
		world.debris.dust(position, 20)
		world.on_death()
	else:
		velocity.x = -signf(source.x - position.x) * 110
	queue_redraw()

func _draw() -> void:
	if dead:
		return
	if invulnerable > 0 and int(invulnerable * 18) % 2 == 0:
		return
	Art.shadow(self, 23)
	Art.draw_hero(self, facing, int(run_clock) if absf(velocity.x) > 10 else 0, not is_on_floor(), invulnerable > 1.0)
	# A separate cannon tracks vertical and diagonal aim in whole pixels.
	if aim.y != 0:
		var shoulder := Vector2(facing * 5, -18)
		for i in range(4, 13, 2):
			draw_rect(Rect2((shoulder + aim * i).round() - Vector2(2, 2), Vector2(4, 4)), Color("efa35f"))
	if muzzle_flash > 0:
		var muzzle := (Vector2(facing * 5, -18) + aim * 15).round()
		draw_rect(Rect2(muzzle - Vector2(3, 3), Vector2(6, 6)), Color("e8ffe2"))
