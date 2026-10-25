extends Node2D
## A cartoon cloud puff that blooms outward and fades. With dizzy on, little stars spin out too.

const LIFE := 0.6

var color := Color.WHITE
var radius := 22.0
var dizzy := false
var age := 0.0
var puffs := []


func _ready() -> void:
	z_index = 5
	var count := 10
	for i in count:
		puffs.append({
			"dir": Vector2.from_angle(TAU * i / count + randf_range(-0.3, 0.3)),
			"dist": radius * randf_range(0.8, 1.5),
			"size": radius * randf_range(0.45, 0.7),
		})


func _process(delta: float) -> void:
	age += delta
	if age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := age / LIFE
	var bloom := 1.0 - pow(1.0 - k, 3.0)
	var alpha := 1.0 - k * k
	if k < 0.2:
		draw_circle(Vector2.ZERO, radius * (0.8 + k * 4.0), Color(1, 1, 1, (0.2 - k) * 4.0))
	for p in puffs:
		var center: Vector2 = p.dir * p.dist * bloom
		var size: float = p.size * (0.5 + bloom * 0.7)
		draw_circle(center, size, Color(color.darkened(0.15), alpha))
		draw_circle(center + Vector2(-size, -size) * 0.2, size * 0.75, Color(color, alpha))
		draw_circle(center + Vector2(-size, -size) * 0.35, size * 0.3, Color(color.lightened(0.5), alpha))
	if dizzy:
		for i in 5:
			var dir := Vector2.from_angle(TAU * i / 5.0 + age * 4.0)
			_star(dir * radius * (0.6 + bloom * 1.6) + Vector2(0, -radius * bloom), 6.0, Color(1.0, 0.9, 0.2, alpha))


func _star(center: Vector2, size: float, star_color: Color) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var r := size if i % 2 == 0 else size * 0.35
		points.append(center + Vector2.from_angle(age * 6.0 + i * TAU / 8.0) * r)
	draw_colored_polygon(points, star_color)
