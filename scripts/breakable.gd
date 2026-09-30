extends StaticBody2D
const Pixels = preload("res://scripts/pixels.gd")
const Art = preload("res://scripts/art.gd")
var world: Node
var sprite: Node2D
var core := false
var health := 5
var alive := true

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 3
	sprite = Pixels.new()
	add_child(sprite)
	sprite.build(Art.CORE if core else Art.CRATE, Vector2(-16, -32))
	if core:
		health = 12
	else:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(32, 32)
		shape.shape = rect
		shape.position.y = -16
		add_child(shape)

func hit(point: Vector2, impulse: Vector2) -> void:
	if not alive:
		return
	health -= 1
	sprite.chip(world, point, impulse * 0.55, 3 if core else 8)
	world.impact(point, Color("efa35f"), 4)
	world.sound.play("hit")
	world.kick(0.6)
	if health <= 0:
		alive = false
		sprite.shatter(world, impulse * 0.5)
		collision_layer = 0
		world.sound.play("break")
		world.kick(2.4 if core else 1.2)
		if core:
			world.open_exit()
		else:
			world.crates_broken += 1
		queue_free()
