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
	var style: String = area.style
	var bottom := Levels.GROUND_Y + DEPTH
	# Soil, darkening with depth: one strip per ground segment so the shading runs straight down.
	var deep := dirt.darkened(0.45)
	for i in ground.size() - 1:
		var a := ground[i]
		var b := ground[i + 1]
		if b.x - a.x < 0.5:
			continue
		draw_polygon(PackedVector2Array([a, b, Vector2(b.x, bottom), Vector2(a.x, bottom)]),
			PackedColorArray([dirt, dirt, deep, deep]))
	# Layers of rock following the surface.
	for depth: float in [70.0, 150.0]:
		var band := PackedVector2Array()
		for p in ground:
			band.append(p + Vector2(0, depth + sin(p.x * 0.01 + depth) * 8.0))
		draw_polyline(band, dirt.darkened(0.2 + depth * 0.001), 5.0, true)
	# Pebbles.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 160:
		var x := rng.randf_range(ground[0].x, ground[ground.size() - 1].x)
		var at := Vector2(x, surface_y(x) + rng.randf_range(28.0, 210.0))
		var r := rng.randf_range(2.0, 5.5)
		draw_colored_polygon(_pebble(at, r, rng), dirt.darkened(rng.randf_range(0.12, 0.3)))
		draw_circle(at + Vector2(-r, -r) * 0.3, r * 0.3, Color(1, 1, 1, 0.12))
	# Grass (or snow, sand, asphalt) along the top, kept below the line so bodies sit on it.
	var top := PackedVector2Array()
	for p in ground:
		top.append(p + Vector2(0, 8))
	draw_polyline(top, grass, 16.0, true)
	var edge := PackedVector2Array()
	var shine := PackedVector2Array()
	for p in ground:
		edge.append(p + Vector2(0, 16))
		shine.append(p + Vector2(0, 2))
	draw_polyline(edge, grass.darkened(0.3), 4.0, true)
	draw_polyline(shine, grass.lightened(0.18), 3.0, true)
	if style in ["farm", "forest", "river", "graveyard", "castle"]:
		# Tufts of grass poking up, and flowers on the farm.
		var x := ground[0].x
		while x < ground[ground.size() - 1].x:
			x += rng.randf_range(10.0, 22.0)
			var base := Vector2(x, surface_y(x) + 3.0)
			if absf(surface_y(x + 6.0) - surface_y(x - 6.0)) > 8.0:
				continue
			for k in 3:
				var lean := (k - 1) * 3.5 + rng.randf_range(-1.5, 1.5)
				var tip := base + Vector2(lean, -rng.randf_range(6.0, 11.0))
				draw_colored_polygon(PackedVector2Array([base + Vector2(lean - 2.2, 0), tip, base + Vector2(lean + 2.2, 0)]),
					grass.lightened(0.08) if k == 1 else grass.darkened(0.1))
			if style == "farm" and rng.randf() < 0.12:
				var bloom := base + Vector2(rng.randf_range(-3, 3), -rng.randf_range(9.0, 13.0))
				var petal: Color = [Color(1, 1, 1), Color(1.0, 0.85, 0.3), Color(1.0, 0.6, 0.7)][rng.randi() % 3]
				for k in 5:
					draw_circle(bloom + Vector2.from_angle(TAU * k / 5.0) * 2.4, 1.9, petal)
				draw_circle(bloom, 1.5, Color(1.0, 0.75, 0.1))
	elif style == "peaks":
		# Soft lumps of snow.
		var x := ground[0].x
		while x < ground[ground.size() - 1].x:
			x += rng.randf_range(18.0, 40.0)
			draw_circle(Vector2(x, surface_y(x) + 4.0), rng.randf_range(5.0, 9.0), grass)
	if style == "city":
		# Kerb and lane markings on the street.
		for i in range(-40, 120):
			var x := i * 40.0
			if absf(surface_y(x) - Levels.GROUND_Y) < 1.0:
				draw_line(Vector2(x, Levels.GROUND_Y + 34), Vector2(x + 20, Levels.GROUND_Y + 34), Color(0.95, 0.85, 0.3), 3.0)


static func _pebble(at: Vector2, r: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 7:
		points.append(at + Vector2.from_angle(TAU * i / 7.0) * r * rng.randf_range(0.75, 1.0) * Vector2(1.3, 1.0))
	return points


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
