extends Node2D
## Dotted path left by the last shot, so the next one can be adjusted.

const MAX_POINTS := 300

var points := PackedVector2Array()


func add(point: Vector2) -> void:
	if points.size() < MAX_POINTS:
		points.append(point)
		queue_redraw()


func clear() -> void:
	points.clear()
	queue_redraw()


func _draw() -> void:
	for i in points.size():
		draw_circle(points[i], 4.5 if i % 4 == 0 else 2.5, Color(1, 1, 1, 0.65))
