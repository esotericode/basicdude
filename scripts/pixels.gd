extends Node2D
## The visible pixels are the source of truth for damage and projectile collision.
const Art = preload("res://scripts/art.gd")
var cells: Dictionary = {}
var origin := Vector2.ZERO
var cell_size := 2
var facing := 1
var flash := 0.0

func build(rows: Array, offset: Vector2, size: int = 2) -> void:
	origin = offset
	cell_size = size
	cells.clear()
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var symbol: String = rows[y][x]
			if Art.COLORS.has(symbol):
				cells[Vector2i(x, y)] = Art.COLORS[symbol]
	queue_redraw()

func cell_position(cell: Vector2i) -> Vector2:
	var p := origin + Vector2(cell) * cell_size
	if facing < 0:
		p.x = -p.x - cell_size
	return p

func chip(world: Node, hit: Vector2, impulse: Vector2, count: int) -> void:
	var sorted: Array = cells.keys()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (global_position + cell_position(a)).distance_squared_to(hit) < (global_position + cell_position(b)).distance_squared_to(hit))
	for i in range(mini(count, sorted.size())):
		var cell: Vector2i = sorted[i]
		world.debris.spawn(global_position + cell_position(cell), cells[cell], impulse, cell_size)
		cells.erase(cell)
	flash = 0.055
	queue_redraw()

func shatter(world: Node, impulse: Vector2) -> void:
	for cell: Vector2i in cells:
		world.debris.spawn(global_position + cell_position(cell), cells[cell], impulse, cell_size)
	cells.clear()
	queue_redraw()

func ray_hit(from: Vector2, to: Vector2) -> float:
	var best := INF
	for cell: Vector2i in cells:
		var rect := Rect2(global_position + cell_position(cell), Vector2(cell_size, cell_size)).grow(1.5)
		best = minf(best, segment_rect(from, to, rect))
	return best

static func segment_rect(from: Vector2, to: Vector2, rect: Rect2) -> float:
	var delta := to - from
	var enter := 0.0
	var leave := 1.0
	for axis in range(2):
		if absf(delta[axis]) < 0.0001:
			if from[axis] < rect.position[axis] or from[axis] > rect.end[axis]:
				return INF
		else:
			var a: float = (rect.position[axis] - from[axis]) / delta[axis]
			var b: float = (rect.end[axis] - from[axis]) / delta[axis]
			enter = maxf(enter, minf(a, b))
			leave = minf(leave, maxf(a, b))
			if enter > leave:
				return INF
	return enter

func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		queue_redraw()

func _draw() -> void:
	for cell: Vector2i in cells:
		draw_rect(Rect2(cell_position(cell), Vector2(cell_size, cell_size)), Color("fff0dc") if flash > 0.0 else cells[cell])
