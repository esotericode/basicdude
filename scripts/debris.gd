extends Node2D
## One batched renderer; sleeping fragments stop simulating. No physics node per pixel.
const MAX_FRAGMENTS := 900
var fragments: Array = []
var world: Node
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 2026
	z_index = 8

func spawn(point: Vector2, color: Color, impulse: Vector2, size: int = 2) -> void:
	if fragments.size() >= MAX_FRAGMENTS:
		fragments.pop_front()
	fragments.append({"p": point, "v": impulse + Vector2(rng.randf_range(-75, 75), rng.randf_range(-165, -35)), "c": color, "s": size, "life": rng.randf_range(10, 15), "sleep": false, "bounce": 0})

func dust(point: Vector2, count: int = 5) -> void:
	for i in range(count):
		spawn(point + Vector2(rng.randf_range(-7, 7), -2), Color("465663"), Vector2(rng.randf_range(-45, 45), 80), 1)

func _physics_process(delta: float) -> void:
	for i in range(fragments.size() - 1, -1, -1):
		var f: Dictionary = fragments[i]
		f.life -= delta
		if f.life <= 0:
			fragments.remove_at(i)
			continue
		if f.sleep:
			continue
		f.v.y = minf(f.v.y + 850.0 * delta, 600.0)
		var previous: Vector2 = f.p
		var next: Vector2 = previous + f.v * delta
		# Swept top-surface collision keeps fast fragments from falling through platforms.
		var floor_y: float = world.landing_surface(previous, next, f.s)
		if floor_y < INF:
			next.y = floor_y - f.s
			f.v.y *= -0.32
			f.v.x *= 0.58
			f.bounce += 1
			if absf(f.v.y) < 22 or f.bounce >= 4:
				f.sleep = true
		f.p = next
	queue_redraw()

func _draw() -> void:
	for f: Dictionary in fragments:
		var color: Color = f.c
		color.a *= minf(1.0, f.life / 2.0)
		draw_rect(Rect2(f.p.round(), Vector2(f.s, f.s)), color)
