extends StaticBody2D
## The level's ground: a solid strip under the generated ground line, drawn in the area's
## colours, plus static platforms (mesas, piers, rooftops, ramparts) and water or lava pools.

const Levels := preload("res://scripts/levels.gd")
const DEPTH := 500.0

var ground := PackedVector2Array()
var platforms := []
var area: Dictionary


func setup(level: Dictionary, p_area: Dictionary) -> void:
	ground = level.ground
	platforms = level.platforms
	area = p_area


func _ready() -> void:
	z_index = 2
	# One convex slice per ground segment: always valid, unlike decomposing the whole outline.
	for i in ground.size() - 1:
		var a := ground[i]
		var b := ground[i + 1]
		if b.x - a.x < 0.5:
			continue
		var slice := ConvexPolygonShape2D.new()
		slice.points = PackedVector2Array([a, b, Vector2(b.x, Levels.GROUND_Y + DEPTH), Vector2(a.x, Levels.GROUND_Y + DEPTH)])
		var collision := CollisionShape2D.new()
		collision.shape = slice
		add_child(collision)
	for p in platforms:
		var rect := RectangleShape2D.new()
		var height: float = p[1] + DEPTH * 0.5
		rect.size = Vector2(p[2], height)
		var collision := CollisionShape2D.new()
		collision.shape = rect
		collision.position = Vector2(p[0], Levels.GROUND_Y - p[1] + height / 2.0)
		add_child(collision)
	var material := PhysicsMaterial.new()
	material.friction = 0.9
	physics_material_override = material
	var behind := PlatformArt.new()
	behind.terrain = self
	add_child(behind)


## Height of the ground's top edge (a y coordinate) at x.
func surface_y(x: float) -> float:
	if ground.is_empty() or x <= ground[0].x:
		return ground[0].y if not ground.is_empty() else Levels.GROUND_Y
	var lo := 0
	var hi := ground.size() - 1
	if x >= ground[hi].x:
		return ground[hi].y
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if ground[mid].x <= x:
			lo = mid
		else:
			hi = mid
	var a := ground[lo]
	var b := ground[hi]
	return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.001))


## The lowest solid point under x: the ground or the top of a platform.
func floor_y(x: float) -> float:
	var y := surface_y(x)
	for p in platforms:
		if absf(x - p[0]) <= p[2] / 2.0:
			y = minf(y, Levels.GROUND_Y - p[1])
	return y


func _draw() -> void:
	var dirt: Color = area.dirt
	var grass: Color = area.grass
	var outline := ground.duplicate()
	outline.append(Vector2(ground[ground.size() - 1].x, Levels.GROUND_Y + DEPTH))
	outline.append(Vector2(ground[0].x, Levels.GROUND_Y + DEPTH))
	draw_colored_polygon(outline, dirt)
	# Speckles in the dirt.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 220:
		var x := rng.randf_range(ground[0].x, ground[ground.size() - 1].x)
		var y := surface_y(x) + rng.randf_range(24.0, 200.0)
		draw_circle(Vector2(x, y), rng.randf_range(2.0, 5.0), dirt.darkened(rng.randf_range(0.08, 0.2)))
	# Grass (or snow, sand, asphalt) along the top, kept below the line so bodies sit on it.
	var top := PackedVector2Array()
	for p in ground:
		top.append(p + Vector2(0, 8))
	draw_polyline(top, grass, 16.0)
	var edge := PackedVector2Array()
	for p in ground:
		edge.append(p + Vector2(0, 16))
	draw_polyline(edge, grass.darkened(0.2), 3.0)
	if area.style == "city":
		# Kerb and lane markings on the street.
		for i in range(-40, 120):
			var x := i * 40.0
			if absf(surface_y(x) - Levels.GROUND_Y) < 1.0:
				draw_line(Vector2(x, Levels.GROUND_Y + 34), Vector2(x + 20, Levels.GROUND_Y + 34), Color(0.95, 0.85, 0.3), 3.0)


## Platforms are drawn behind the ground so their bases disappear into it.
class PlatformArt extends Node2D:
	var terrain

	func _ready() -> void:
		z_as_relative = false
		z_index = -1

	func _draw() -> void:
		var style: String = terrain.area.platform
		var dirt: Color = terrain.area.dirt
		for p in terrain.platforms:
			var x0: float = p[0] - p[2] / 2.0
			var w: float = p[2]
			var top: float = Levels.GROUND_Y - p[1]
			var rect := Rect2(x0, top, w, p[1] + 200.0)
			match style:
				"building":
					draw_rect(rect, Color(0.5, 0.52, 0.58))
					for row in int(p[1] / 34.0) + 6:
						for col in int(w / 28.0):
							var lit := (row * 7 + col * 3) % 5 == 0
							draw_rect(Rect2(x0 + 8 + col * 28, top + 14 + row * 34, 14, 18), Color(1.0, 0.9, 0.55) if lit else Color(0.3, 0.35, 0.45))
					draw_rect(Rect2(x0 - 4, top, w + 8, 8), Color(0.38, 0.4, 0.45))
				"pier":
					for k in int(w / 40.0) + 1:
						draw_rect(Rect2(x0 + 6 + k * 40, top, 10, p[1] + 200.0), Color(0.45, 0.3, 0.18))
					draw_rect(Rect2(x0, top, w, 14), Color(0.62, 0.42, 0.25))
					draw_line(Vector2(x0, top + 7), Vector2(x0 + w, top + 7), Color(0.45, 0.3, 0.18), 1.0)
				"stump":
					draw_rect(rect, Color(0.45, 0.3, 0.18))
					draw_rect(Rect2(x0, top, w, 10), Color(0.75, 0.6, 0.4))
					for k in 4:
						draw_line(Vector2(x0 + w * (0.2 + k * 0.2), top + 12), Vector2(x0 + w * (0.2 + k * 0.2), top + p[1] + 100), Color(0.35, 0.22, 0.12), 2.0)
				"rampart":
					draw_rect(rect, Color(0.5, 0.5, 0.55))
					for row in int(p[1] / 20.0) + 8:
						var offset := 0.0 if row % 2 == 0 else 20.0
						for col in int(w / 40.0) + 1:
							draw_rect(Rect2(x0 + offset + col * 40 - 20, top + row * 20, 40, 20), Color(0.38, 0.38, 0.42), false, 1.5)
				"crypt":
					draw_rect(rect, Color(0.42, 0.4, 0.45))
					draw_rect(Rect2(x0 + w / 2 - 14, top + 20, 28, 40), Color(0.15, 0.12, 0.18))
					draw_rect(Rect2(x0 - 4, top, w + 8, 8), Color(0.5, 0.48, 0.55))
				_:
					# Rock: mesa, cliff, basalt.
					var rock: Color = {"mesa": Color(0.75, 0.4, 0.25), "cliff": Color(0.55, 0.58, 0.65), "basalt": Color(0.22, 0.18, 0.2)}.get(style, dirt.lightened(0.1))
					draw_rect(rect, rock)
					for k in 5:
						draw_line(Vector2(x0, top + 16 + k * 22), Vector2(x0 + w, top + 22 + k * 22), rock.darkened(0.15), 2.0)
					if style == "cliff":
						draw_rect(Rect2(x0 - 3, top, w + 6, 10), Color(0.97, 0.98, 1.0))
					elif style == "basalt":
						draw_rect(Rect2(x0, top, w, 4), Color(1.0, 0.45, 0.1, 0.6))
