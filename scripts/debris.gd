extends Node2D
## A burst of short-lived pieces (splinters, chunks, shards, tufts) that fly, bounce off the
## ground and fade. Purely visual: pieces don't collide with the level.

const Levels := preload("res://scripts/levels.gd")
const GRAVITY := 980.0
## Pieces fade out over their last this-many seconds.
const FADE := 0.4

## Where pieces land: the level's floor height at an x. Set by the level; flat when unset.
static var floor_at := Callable()

var pieces: Array[Dictionary] = []


func _ready() -> void:
	z_index = 3


func add_piece(pos: Vector2, vel: Vector2, poly: PackedVector2Array, color: Color, life: float,
		rot := 0.0, spin := 0.0, gravity := 1.0, drag := 0.0) -> void:
	pieces.append({"pos": pos, "vel": vel, "poly": poly, "color": color, "life": life,
		"rot": rot, "spin": spin, "gravity": gravity, "drag": drag})


func _process(delta: float) -> void:
	for p in pieces:
		var vel: Vector2 = p.vel
		var pos: Vector2 = p.pos
		vel.y += GRAVITY * p.gravity * delta
		vel *= exp(-p.drag * delta)
		pos += vel * delta
		var floor_y: float = (floor_at.call(pos.x) if floor_at.is_valid() else Levels.GROUND_Y) - 2.0
		if pos.y > floor_y and vel.y > 0.0 and pos.y < floor_y + 30.0:
			pos.y = floor_y
			vel = Vector2(vel.x * 0.55, -vel.y * 0.3)
			p.spin *= 0.5
		p.vel = vel
		p.pos = pos
		p.rot += p.spin * delta
		p.life -= delta
	pieces = pieces.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	if pieces.is_empty():
		queue_free()
	queue_redraw()


func _draw() -> void:
	for p in pieces:
		var color: Color = p.color
		color.a *= clampf(p.life / FADE, 0.0, 1.0)
		draw_set_transform(p.pos, p.rot)
		draw_colored_polygon(p.poly, color)
