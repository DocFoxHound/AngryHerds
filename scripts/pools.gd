extends Node2D
## Water and lava pools. Drawn over sinking things (and under the ground's edges). Anything
## whose centre drops below a pool's surface is lost to it: main.gd asks which pool, if any.

const Levels := preload("res://scripts/levels.gd")

var pools := []
var time := 0.0


func _ready() -> void:
	z_index = 1


func pool_at(pos: Vector2) -> String:
	for p in pools:
		if pos.x > p[0] and pos.x < p[1] and pos.y > Levels.GROUND_Y - p[2] + 6.0:
			return p[3]
	return ""


func _process(delta: float) -> void:
	time += delta
	if not pools.is_empty():
		queue_redraw()


func _draw() -> void:
	for p in pools:
		var lava: bool = p[3] == "lava"
		var x0: float = p[0]
		var x1: float = p[1]
		var surface: float = Levels.GROUND_Y - p[2]
		var body := Color(1.0, 0.42, 0.08, 0.95) if lava else Color(0.2, 0.5, 0.85, 0.62)
		draw_rect(Rect2(x0, surface, x1 - x0, 200.0), body)
		var deep := Color(0.8, 0.2, 0.05, 0.9) if lava else Color(0.1, 0.3, 0.6, 0.5)
		draw_rect(Rect2(x0, surface + 40.0, x1 - x0, 160.0), deep)
		# Wavy surface line.
		var wave := PackedVector2Array()
		var x := x0
		while x <= x1:
			wave.append(Vector2(x, surface + sin(x * 0.05 + time * 2.5) * 2.5))
			x += 8.0
		draw_polyline(wave, Color(1.0, 0.85, 0.3) if lava else Color(0.85, 0.95, 1.0, 0.9), 3.0)
		if lava:
			# Bubbles popping up.
			for i in 6:
				var phase := fmod(time * 0.7 + i * 0.37, 1.0)
				var bx := lerpf(x0 + 10.0, x1 - 10.0, fmod(i * 0.618 + floor(time * 0.7 + i * 0.37) * 0.3, 1.0))
				draw_circle(Vector2(bx, surface + 4.0 - phase * 6.0), 3.0 + phase * 3.0, Color(1.0, 0.75, 0.2, 1.0 - phase))
