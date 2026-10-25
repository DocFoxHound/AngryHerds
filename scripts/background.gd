extends Node2D
## Scenery behind the level, themed by area: sky, sun or moon, far landscape and props
## (barns, pines, mesas, skylines, tombstones, volcanoes, castles). Drawn once, in layers that
## scroll at different speeds as the camera moves (parallax); the moving parts (clouds, birds,
## snow, fireflies, embers, windmill sails) live in the Ambience child and Spinner nodes.

const Levels := preload("res://scripts/levels.gd")
const GROUND := Levels.GROUND_Y
const LEFT := -1600.0
const RIGHT := 3600.0

var area: Dictionary
var seed_value := 1
var rng := RandomNumberGenerator.new()
## The layer being painted: the scenery helpers draw onto it.
var ci: CanvasItem
## [node, depth] pairs: depth 1 moves with the camera (infinitely far), 0 stays with the level.
var layers := []
var camera_anchor := Vector2.ZERO
var anchored := false


func setup(p_area: Dictionary, p_seed: int) -> void:
	area = p_area
	seed_value = p_seed


func _ready() -> void:
	z_index = -10
	_add_layer(_paint_sky, 0.92)
	var ambience := Ambience.new()
	ambience.area = area
	ambience.seed_value = seed_value
	add_child(ambience)
	layers.append([ambience, 0.8])
	_add_layer(_paint_far, 0.5)
	_add_layer(_paint_near, 0.25)


func _add_layer(paint: Callable, depth: float) -> void:
	var layer := Layer.new()
	layer.paint = paint
	add_child(layer)
	layers.append([layer, depth])


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	if not anchored:
		camera_anchor = camera.global_position
		anchored = true
	var moved := camera.global_position - camera_anchor
	for pair in layers:
		pair[0].position = Vector2(moved.x * pair[1], moved.y * pair[1] * 0.3)


func _paint_sky(layer: CanvasItem) -> void:
	ci = layer
	rng.seed = seed_value
	var sky: Array = area.sky
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, -1400), Vector2(RIGHT, -1400), Vector2(RIGHT, GROUND + 200), Vector2(LEFT, GROUND + 200)]),
		PackedColorArray([sky[0], sky[0], sky[1], sky[1]]))
	if area.get("night", false):
		for i in 90:
			ci.draw_circle(Vector2(rng.randf_range(LEFT, RIGHT), rng.randf_range(-600, 420)), rng.randf_range(0.8, 2.0), Color(1, 1, 0.9, rng.randf_range(0.4, 0.9)))
		ci.draw_circle(Vector2(1050, 120), 60, Color(1, 1, 0.85, 0.15))
		ci.draw_circle(Vector2(1050, 120), 45, Color(0.98, 0.97, 0.85))
		ci.draw_circle(Vector2(1065, 108), 9, Color(0.88, 0.87, 0.75))
		ci.draw_circle(Vector2(1035, 135), 6, Color(0.88, 0.87, 0.75))
	elif area.style != "volcano":
		var big := 1.4 if area.style == "canyon" else 1.0
		var sun := Vector2(1090, 110)
		for k in 12:
			var a := k * TAU / 12.0
			ci.draw_colored_polygon(PackedVector2Array([sun + Vector2.from_angle(a - 0.07) * 60 * big, sun + Vector2.from_angle(a) * 170 * big,
				sun + Vector2.from_angle(a + 0.07) * 60 * big]), Color(1.0, 0.97, 0.7, 0.1))
		ci.draw_circle(sun, 95 * big, Color(1.0, 0.95, 0.6, 0.12))
		ci.draw_circle(sun, 72 * big, Color(1.0, 0.95, 0.6, 0.25))
		ci.draw_circle(sun, 52 * big, Color(1.0, 0.9, 0.5))
		ci.draw_circle(sun + Vector2(-8, -8) * big, 42 * big, Color(1.0, 0.95, 0.65))


## Distant scenery, behind a veil of haze.
func _paint_far(layer: CanvasItem) -> void:
	ci = layer
	rng.seed = seed_value
	var hills: Array = area.hills
	match area.style:
		"farm":
			_hills(GROUND - 120.0, 110.0, 0.0035, 1.3, hills[0])
			for i in 4:
				_tree_round(Vector2(rng.randf_range(-300, 2200), GROUND - 60), rng.randf_range(0.8, 1.2))
			_barn(Vector2(rng.randf_range(400, 700), GROUND - 40))
			_silo(Vector2(rng.randf_range(800, 950), GROUND - 40))
			_windmill(Vector2(rng.randf_range(1400, 1900), GROUND - 50))
		"forest":
			_mountains(GROUND - 200.0, 220.0, Color(0.55, 0.68, 0.72), false)
			for i in 40:
				_pine(Vector2(rng.randf_range(-600, 2600), GROUND - rng.randf_range(60, 120)), rng.randf_range(0.8, 1.3), hills[0].darkened(0.1))
		"river":
			_hills(GROUND - 100.0, 90.0, 0.004, 2.0, hills[0])
			for i in 5:
				_willow(Vector2(rng.randf_range(-300, 2300), GROUND - 30), rng.randf_range(0.9, 1.3))
			_watermill(Vector2(rng.randf_range(1500, 1900), GROUND - 30))
		"canyon":
			for i in 7:
				_mesa(Vector2(rng.randf_range(-500, 2500), GROUND - 20), rng.randf_range(160, 380), rng.randf_range(90, 260), hills[0])
		"peaks":
			_mountains(GROUND - 120.0, 420.0, hills[0], true)
		"beach":
			ci.draw_rect(Rect2(LEFT, GROUND - 140, RIGHT - LEFT, 400), Color(0.2, 0.55, 0.85))
			ci.draw_rect(Rect2(LEFT, GROUND - 140, RIGHT - LEFT, 6), Color(0.6, 0.85, 1.0))
			_island(Vector2(rng.randf_range(1300, 1800), GROUND - 140))
			_ship_silhouette(Vector2(rng.randf_range(500, 900), GROUND - 140))
		"city":
			_skyline(GROUND - 20.0, Color(0.55, 0.6, 0.7), 140, 380, false)
		"graveyard":
			_hills(GROUND - 90.0, 80.0, 0.004, 0.7, hills[0])
			_church(Vector2(rng.randf_range(1300, 1700), GROUND - 60))
			for i in 4:
				_dead_tree(Vector2(rng.randf_range(-300, 2300), GROUND - 30), rng.randf_range(0.9, 1.4))
		"volcano":
			_volcano(Vector2(1200, GROUND - 60))
		"castle":
			_mountains(GROUND - 150.0, 300.0, hills[0], false)
			_castle(Vector2(1250, GROUND - 60))
	# Haze: distance fades toward the sky colour near the horizon.
	var haze: Color = area.sky[1]
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, GROUND - 320), Vector2(RIGHT, GROUND - 320), Vector2(RIGHT, GROUND + 60), Vector2(LEFT, GROUND + 60)]),
		PackedColorArray([Color(haze, 0.0), Color(haze, 0.0), Color(haze, 0.4), Color(haze, 0.4)]))


## Scenery close behind the level.
func _paint_near(layer: CanvasItem) -> void:
	ci = layer
	rng.seed = seed_value + 1
	var hills: Array = area.hills
	match area.style:
		"farm":
			_hills(GROUND - 50.0, 60.0, 0.006, 0.2, hills[1])
			for i in 5:
				_bush(Vector2(rng.randf_range(-300, 2400), GROUND - rng.randf_range(10, 30)), rng.randf_range(0.7, 1.1), hills[1])
			_fence(GROUND - 6.0, rng.randf_range(-200, 300), 900.0)
			for i in 3:
				_hay_bale(Vector2(rng.randf_range(1200, 2600), GROUND - 14), rng.randf_range(0.8, 1.0))
		"forest":
			_hills(GROUND - 60.0, 50.0, 0.007, 0.5, hills[1])
			for i in 26:
				_pine(Vector2(rng.randf_range(-600, 2600), GROUND - rng.randf_range(10, 40)), rng.randf_range(1.0, 1.5), hills[1].darkened(0.15))
		"river":
			_hills(GROUND - 40.0, 40.0, 0.008, 1.0, hills[1])
			for i in 30:
				_reed(Vector2(rng.randf_range(-400, 2500), GROUND - 4))
		"canyon":
			for i in 5:
				_mesa(Vector2(rng.randf_range(-500, 2500), GROUND), rng.randf_range(100, 220), rng.randf_range(50, 130), hills[1])
			for i in 8:
				_cactus(Vector2(rng.randf_range(-400, 2400), GROUND - 4), rng.randf_range(0.7, 1.2))
		"peaks":
			_mountains(GROUND - 40.0, 260.0, hills[1], true)
			for i in 24:
				_pine(Vector2(rng.randf_range(-600, 2600), GROUND - rng.randf_range(0, 30)), rng.randf_range(0.9, 1.4), Color(0.25, 0.4, 0.35), true)
		"beach":
			for i in 6:
				_palm(Vector2(rng.randf_range(-500, 450) if i < 3 else rng.randf_range(1500, 2600), GROUND - 4), rng.randf_range(0.9, 1.3))
		"city":
			_skyline(GROUND, Color(0.42, 0.45, 0.55), 80, 260, true)
		"graveyard":
			_hills(GROUND - 40.0, 40.0, 0.007, 2.2, hills[1])
			for i in 18:
				_tombstone(Vector2(rng.randf_range(-400, 2500), GROUND - rng.randf_range(0, 20)))
		"volcano":
			_mountains(GROUND - 30.0, 200.0, hills[1], false)
		"castle":
			_hills(GROUND - 40.0, 50.0, 0.006, 0.9, hills[1])


# -- Scenery pieces --------------------------------------------------------------------------

func _hills(base: float, height: float, freq: float, phase: float, color: Color) -> void:
	var rim := PackedVector2Array()
	for x in range(int(LEFT), int(RIGHT) + 1, 40):
		var wave := 0.6 + 0.3 * sin(x * freq + phase) + 0.1 * sin(x * freq * 2.7 + phase * 3.0)
		rim.append(Vector2(x, base - height * wave + height * 0.5))
	# Shaded strip by strip: lit along the crest, darker toward the foot.
	var foot := color.darkened(0.15)
	for i in rim.size() - 1:
		ci.draw_polygon(PackedVector2Array([rim[i], rim[i + 1], Vector2(rim[i + 1].x, GROUND + 300), Vector2(rim[i].x, GROUND + 300)]),
			PackedColorArray([color.lightened(0.06), color.lightened(0.06), foot, foot]))
	ci.draw_polyline(rim, color.lightened(0.22), 3.0, true)


func _mountains(base: float, height: float, color: Color, snowy: bool) -> void:
	var x := LEFT
	while x < RIGHT:
		var w := rng.randf_range(260, 520)
		var h := height * rng.randf_range(0.6, 1.0)
		var peak := Vector2(x + w / 2.0, base - h)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, base + 60), peak, Vector2(x + w, base + 60)]), color)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x + w / 2.0, base + 60), peak, Vector2(x + w, base + 60)]), color.darkened(0.1))
		if snowy:
			var cap := 0.28
			ci.draw_colored_polygon(PackedVector2Array([peak, peak.lerp(Vector2(x + w, base + 60), cap),
				peak.lerp(Vector2(x + w / 2.0, base + 60), cap * 0.7) + Vector2(0, 8), peak.lerp(Vector2(x, base + 60), cap)]), Color(0.97, 0.98, 1.0))
		x += w * rng.randf_range(0.55, 0.85)


func _tree_round(at: Vector2, s: float) -> void:
	var trunk := Color(0.42, 0.29, 0.17)
	ci.draw_rect(Rect2(at.x - 6 * s, at.y - 30 * s, 12 * s, 40 * s), trunk)
	ci.draw_rect(Rect2(at.x + 1 * s, at.y - 30 * s, 5 * s, 40 * s), trunk.darkened(0.2))
	var leaf := Color(0.3, 0.58, 0.3)
	var blobs := [Vector2(0, -50), Vector2(-20, -36), Vector2(20, -38), Vector2(-8, -66), Vector2(12, -60)]
	var sizes := [30.0, 20.0, 22.0, 18.0, 18.0]
	for i in blobs.size():
		ci.draw_circle(at + blobs[i] * s, sizes[i] * s, leaf.darkened(0.18))
	for i in blobs.size():
		ci.draw_circle(at + (blobs[i] + Vector2(-4, -5)) * s, sizes[i] * 0.8 * s, leaf)
	for i in 3:
		ci.draw_circle(at + (blobs[i + 2] + Vector2(-7, -9)) * s, sizes[i + 2] * 0.35 * s, leaf.lightened(0.18))


func _pine(at: Vector2, s: float, color: Color, snow := false) -> void:
	ci.draw_rect(Rect2(at.x - 4 * s, at.y - 14 * s, 8 * s, 20 * s), Color(0.35, 0.22, 0.12))
	for k in 3:
		var y := at.y - (14 + k * 22) * s
		var half := (30 - k * 7) * s
		ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - half, y), Vector2(at.x, y - 40 * s), Vector2(at.x + half, y)]), color.lightened(k * 0.05))
		if snow:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - half * 0.4, y - 24 * s), Vector2(at.x, y - 40 * s), Vector2(at.x + half * 0.4, y - 24 * s)]), Color(0.97, 0.98, 1.0))


func _barn(at: Vector2) -> void:
	var red := Color(0.74, 0.22, 0.18)
	var trim := Color(0.96, 0.93, 0.86)
	var ink := Color(0.3, 0.1, 0.08)
	var wall := Rect2(at.x - 70, at.y - 90, 140, 130)
	ci.draw_rect(wall, red)
	# Boards, and shade under the eaves and down the right side.
	for k in 9:
		ci.draw_line(Vector2(wall.position.x + 15 * (k + 1), wall.position.y + 4), Vector2(wall.position.x + 15 * (k + 1), at.y + 40), red.darkened(0.12), 1.5)
	ci.draw_rect(Rect2(at.x + 46, wall.position.y, 24, 130), Color(0, 0, 0, 0.12))
	ci.draw_rect(Rect2(wall.position.x, wall.position.y, 140, 10), Color(0, 0, 0, 0.18))
	var roof := PackedVector2Array([Vector2(at.x - 82, at.y - 86), Vector2(at.x - 42, at.y - 142), Vector2(at.x + 42, at.y - 142), Vector2(at.x + 82, at.y - 86)])
	ci.draw_colored_polygon(roof, Color(0.42, 0.2, 0.16))
	for k in 4:
		var t := (k + 1) / 5.0
		ci.draw_line(roof[0].lerp(roof[1], t), roof[3].lerp(roof[2], t), Color(0.34, 0.16, 0.13), 2.0)
	roof.append(roof[0])
	ci.draw_polyline(roof, ink, 2.5, true)
	ci.draw_line(Vector2(at.x - 82, at.y - 86), Vector2(at.x + 82, at.y - 86), trim, 4.0)
	var door := Rect2(at.x - 26, at.y - 60, 52, 100)
	ci.draw_rect(door, trim)
	ci.draw_rect(door.grow(-4), red.darkened(0.18))
	ci.draw_line(door.position + Vector2(4, 4), door.end - Vector2(4, 4), trim, 3.0)
	ci.draw_line(Vector2(door.position.x + 4, door.end.y - 4), Vector2(door.end.x - 4, door.position.y + 4), trim, 3.0)
	var loft := Rect2(at.x - 13, at.y - 122, 26, 24)
	ci.draw_rect(loft, trim)
	ci.draw_rect(loft.grow(-3), Color(0.25, 0.12, 0.1))
	ci.draw_colored_polygon(PackedVector2Array([loft.position + Vector2(3, 24), loft.position + Vector2(9, 12), loft.position + Vector2(15, 16), loft.position + Vector2(23, 24)]), Color(0.95, 0.8, 0.35))
	ci.draw_rect(wall, ink, false, 2.5)


func _silo(at: Vector2) -> void:
	var metal := Color(0.78, 0.8, 0.83)
	# A rounded tank: vertical strips from lit left to shaded right.
	for k in 8:
		var t := k / 7.0
		var shade := metal.lightened(0.15 - t * 0.15).darkened(maxf(t - 0.5, 0.0) * 0.5)
		ci.draw_rect(Rect2(at.x - 24 + k * 6, at.y - 150, 6.5, 190), shade)
	ci.draw_circle(Vector2(at.x, at.y - 150), 24, Color(0.55, 0.58, 0.63))
	ci.draw_circle(Vector2(at.x - 6, at.y - 156), 13, Color(0.68, 0.7, 0.75))
	for k in 6:
		ci.draw_line(Vector2(at.x - 24, at.y - 20 - k * 22), Vector2(at.x + 24, at.y - 20 - k * 22), Color(0.6, 0.62, 0.66), 2.0)
	ci.draw_rect(Rect2(at.x - 24, at.y - 150, 48, 190), Color(0.3, 0.32, 0.36), false, 2.0)


func _windmill(at: Vector2) -> void:
	var tower := PackedVector2Array([Vector2(at.x - 26, at.y + 40), Vector2(at.x - 12, at.y - 150), Vector2(at.x + 12, at.y - 150), Vector2(at.x + 26, at.y + 40)])
	ci.draw_colored_polygon(tower, Color(0.92, 0.9, 0.84))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x + 4, at.y + 40), Vector2(at.x + 2, at.y - 150), Vector2(at.x + 12, at.y - 150), Vector2(at.x + 26, at.y + 40)]), Color(0.8, 0.78, 0.72))
	ci.draw_rect(Rect2(at.x - 7, at.y - 22, 14, 22), Color(0.45, 0.3, 0.2))
	tower.append(tower[0])
	ci.draw_polyline(tower, Color(0.4, 0.36, 0.3), 2.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 18, at.y - 148), Vector2(at.x, at.y - 172), Vector2(at.x + 18, at.y - 148)]), Color(0.45, 0.2, 0.15))
	# The sails turn: they're a Spinner on top of the drawn tower.
	var sails := Spinner.new()
	sails.position = Vector2(at.x, at.y - 150)
	ci.add_child.call_deferred(sails)


func _fence(y: float, x0: float, length: float) -> void:
	var wood := Color(0.88, 0.82, 0.7)
	var ink := Color(0.45, 0.38, 0.3)
	for rail_y: float in [y - 28, y - 15]:
		ci.draw_rect(Rect2(x0, rail_y, length, 5), wood)
		ci.draw_line(Vector2(x0, rail_y + 5), Vector2(x0 + length, rail_y + 5), ink, 1.5)
	var x := x0
	while x < x0 + length:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 4), Vector2(x, y - 34), Vector2(x + 3.5, y - 38), Vector2(x + 7, y - 34), Vector2(x + 7, y + 4)]), wood)
		ci.draw_rect(Rect2(x + 4.5, y - 34, 2.5, 38), wood.darkened(0.15))
		ci.draw_polyline(PackedVector2Array([Vector2(x, y + 4), Vector2(x, y - 34), Vector2(x + 3.5, y - 38), Vector2(x + 7, y - 34), Vector2(x + 7, y + 4)]), ink, 1.5, true)
		x += 40.0


func _bush(at: Vector2, s: float, color: Color) -> void:
	var leaf := color.darkened(0.12)
	for p: Vector2 in [Vector2(-18, 0), Vector2(0, -10), Vector2(18, 0)]:
		ci.draw_circle(at + p * s, 16 * s, leaf.darkened(0.15))
	for p: Vector2 in [Vector2(-19, -3), Vector2(-1, -13), Vector2(17, -3)]:
		ci.draw_circle(at + p * s, 12 * s, leaf)
	ci.draw_circle(at + Vector2(-5, -18) * s, 5 * s, leaf.lightened(0.2))


## A round bale of hay lying on its side.
func _hay_bale(at: Vector2, s: float) -> void:
	var hay := Color(0.92, 0.78, 0.38)
	ci.draw_rect(Rect2(at.x - 22 * s, at.y - 20 * s, 44 * s, 34 * s), hay.darkened(0.08))
	for k in 4:
		ci.draw_line(Vector2(at.x - 18 * s + k * 12 * s, at.y - 20 * s), Vector2(at.x - 18 * s + k * 12 * s, at.y + 14 * s), hay.darkened(0.22), 1.5)
	ci.draw_circle(Vector2(at.x + 22 * s, at.y - 3 * s), 17 * s, hay)
	for k in 3:
		ci.draw_arc(Vector2(at.x + 22 * s, at.y - 3 * s), (4 + k * 4.5) * s, k, k + 5.0, 12, hay.darkened(0.2), 1.5)
	ci.draw_arc(Vector2(at.x + 22 * s, at.y - 3 * s), 17 * s, 0, TAU, 24, hay.darkened(0.4), 1.5)


func _willow(at: Vector2, s: float) -> void:
	ci.draw_rect(Rect2(at.x - 7 * s, at.y - 70 * s, 14 * s, 80 * s), Color(0.42, 0.32, 0.22))
	ci.draw_circle(at + Vector2(0, -90) * s, 38 * s, Color(0.42, 0.6, 0.32))
	for k in 9:
		var x := at.x + (k - 4) * 9 * s
		ci.draw_line(Vector2(x, at.y - 90 * s), Vector2(x + (k - 4) * 2 * s, at.y - (20 + absi(k - 4) * 6) * s), Color(0.38, 0.56, 0.28), 4.0 * s)


func _watermill(at: Vector2) -> void:
	ci.draw_rect(Rect2(at.x - 50, at.y - 90, 100, 90), Color(0.65, 0.55, 0.45))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 60, at.y - 88), Vector2(at.x, at.y - 130), Vector2(at.x + 60, at.y - 88)]), Color(0.45, 0.3, 0.22))
	var hub := Vector2(at.x - 60, at.y - 30)
	ci.draw_arc(hub, 40, 0, TAU, 24, Color(0.4, 0.28, 0.18), 6.0)
	for k in 8:
		ci.draw_line(hub, hub + Vector2.from_angle(k * TAU / 8.0) * 40, Color(0.4, 0.28, 0.18), 3.0)


func _reed(at: Vector2) -> void:
	var h := rng.randf_range(24, 46)
	ci.draw_line(at, at + Vector2(rng.randf_range(-6, 6), -h), Color(0.35, 0.5, 0.25), 2.0)
	ci.draw_line(at + Vector2(0, -h * 0.6), at + Vector2(0, -h * 0.95), Color(0.45, 0.3, 0.18), 5.0)


func _mesa(at: Vector2, w: float, h: float, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - w / 2, at.y + 40), Vector2(at.x - w / 2 + 20, at.y - h), Vector2(at.x + w / 2 - 20, at.y - h), Vector2(at.x + w / 2, at.y + 40)]), color)
	for k in 3:
		var y := at.y - h + 20 + k * h / 3.5
		ci.draw_line(Vector2(at.x - w / 2 + 14, y), Vector2(at.x + w / 2 - 14, y), color.darkened(0.12), 3.0)


func _cactus(at: Vector2, s: float) -> void:
	var green := Color(0.35, 0.58, 0.32)
	ci.draw_rect(Rect2(at.x - 8 * s, at.y - 70 * s, 16 * s, 70 * s), green)
	ci.draw_circle(at + Vector2(0, -70) * s, 8 * s, green)
	ci.draw_rect(Rect2(at.x - 26 * s, at.y - 44 * s, 18 * s, 8 * s), green)
	ci.draw_rect(Rect2(at.x - 26 * s, at.y - 64 * s, 8 * s, 24 * s), green)
	ci.draw_rect(Rect2(at.x + 8 * s, at.y - 34 * s, 16 * s, 8 * s), green)
	ci.draw_rect(Rect2(at.x + 16 * s, at.y - 52 * s, 8 * s, 22 * s), green)


func _island(at: Vector2) -> void:
	ci.draw_colored_polygon(_oval(at, 160, 26), Color(0.9, 0.82, 0.55))
	ci.draw_colored_polygon(_oval(at + Vector2(0, -16), 120, 26), Color(0.35, 0.6, 0.35))
	_palm(at + Vector2(30, -20), 0.8)


func _ship_silhouette(at: Vector2) -> void:
	var dark := Color(0.25, 0.25, 0.35, 0.7)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 70, at.y - 24), Vector2(at.x + 70, at.y - 24), Vector2(at.x + 50, at.y), Vector2(at.x - 50, at.y)]), dark)
	ci.draw_line(Vector2(at.x, at.y - 24), Vector2(at.x, at.y - 120), dark, 4.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x + 4, at.y - 112), Vector2(at.x + 50, at.y - 80), Vector2(at.x + 4, at.y - 40)]), dark)
	ci.draw_rect(Rect2(at.x - 2, at.y - 132, 22, 12), Color(0.1, 0.1, 0.12, 0.8))


func _palm(at: Vector2, s: float) -> void:
	var trunk := PackedVector2Array()
	for k in 7:
		trunk.append(at + Vector2(sin(k * 0.3) * 14 * s, -k * 20 * s))
	ci.draw_polyline(trunk, Color(0.6, 0.45, 0.28), 10 * s)
	var top := trunk[trunk.size() - 1]
	for k in 6:
		var dir := Vector2.from_angle(PI + 0.3 + k * 0.5)
		ci.draw_line(top, top + dir * 60 * s + Vector2(0, 20 * s), Color(0.25, 0.55, 0.25), 7 * s)


func _skyline(base: float, color: Color, min_h: float, max_h: float, windows: bool) -> void:
	var x := LEFT
	while x < RIGHT:
		var w := rng.randf_range(70, 150)
		var h := rng.randf_range(min_h, max_h)
		ci.draw_rect(Rect2(x, base - h, w, h + 60), color)
		if windows:
			for row in int(h / 30.0):
				for col in int((w - 10) / 22.0):
					if rng.randf() < 0.7:
						var lit := rng.randf() < 0.25
						ci.draw_rect(Rect2(x + 10 + col * 22, base - h + 12 + row * 30, 10, 14), Color(1.0, 0.9, 0.55) if lit else color.darkened(0.25))
		if rng.randf() < 0.2:
			ci.draw_line(Vector2(x + w / 2, base - h), Vector2(x + w / 2, base - h - 40), color, 3.0)
		x += w + rng.randf_range(0, 20)


func _church(at: Vector2) -> void:
	var dark := Color(0.1, 0.08, 0.15)
	ci.draw_rect(Rect2(at.x - 70, at.y - 80, 140, 80), dark)
	ci.draw_rect(Rect2(at.x + 30, at.y - 170, 40, 100), dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x + 24, at.y - 168), Vector2(at.x + 50, at.y - 230), Vector2(at.x + 76, at.y - 168)]), dark)
	ci.draw_line(Vector2(at.x + 50, at.y - 230), Vector2(at.x + 50, at.y - 256), dark, 3.0)
	ci.draw_line(Vector2(at.x + 40, at.y - 246), Vector2(at.x + 60, at.y - 246), dark, 3.0)
	ci.draw_rect(Rect2(at.x - 40, at.y - 60, 14, 22), Color(1.0, 0.85, 0.4, 0.8))


func _dead_tree(at: Vector2, s: float) -> void:
	var dark := Color(0.12, 0.1, 0.15)
	ci.draw_line(at, at + Vector2(0, -110) * s, dark, 10 * s)
	ci.draw_line(at + Vector2(0, -70) * s, at + Vector2(-40, -110) * s, dark, 5 * s)
	ci.draw_line(at + Vector2(0, -90) * s, at + Vector2(35, -130) * s, dark, 5 * s)
	ci.draw_line(at + Vector2(-25, -95) * s, at + Vector2(-30, -125) * s, dark, 3 * s)
	ci.draw_line(at + Vector2(20, -112) * s, at + Vector2(45, -112) * s, dark, 3 * s)


func _tombstone(at: Vector2) -> void:
	var stone := Color(0.42, 0.4, 0.48)
	if rng.randf() < 0.4:
		ci.draw_rect(Rect2(at.x - 3, at.y - 34, 6, 34), stone)
		ci.draw_rect(Rect2(at.x - 12, at.y - 26, 24, 6), stone)
	else:
		ci.draw_rect(Rect2(at.x - 12, at.y - 26, 24, 26), stone)
		ci.draw_circle(Vector2(at.x, at.y - 26), 12, stone)
		ci.draw_line(Vector2(at.x - 5, at.y - 22), Vector2(at.x + 5, at.y - 22), stone.darkened(0.3), 2.0)


func _volcano(at: Vector2) -> void:
	var rock := Color(0.28, 0.16, 0.14)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 520, at.y + 80), Vector2(at.x - 70, at.y - 330), Vector2(at.x + 70, at.y - 330), Vector2(at.x + 520, at.y + 80)]), rock)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 70, at.y - 330), Vector2(at.x + 70, at.y - 330), Vector2(at.x + 40, at.y - 300), Vector2(at.x - 40, at.y - 300)]), Color(1.0, 0.45, 0.1))
	for k in 3:
		var drip := Vector2(at.x - 40 + k * 40, at.y - 300)
		ci.draw_line(drip, drip + Vector2(rng.randf_range(-60, 60), rng.randf_range(80, 200)), Color(1.0, 0.4, 0.08, 0.9), 6.0)
	for k in 6:
		ci.draw_circle(Vector2(at.x + k * 25 - 40, at.y - 360 - k * 40), 30 + k * 8, Color(0.25, 0.2, 0.2, 0.5))


func _castle(at: Vector2) -> void:
	var stone := Color(0.32, 0.32, 0.4)
	ci.draw_rect(Rect2(at.x - 220, at.y - 180, 440, 240), stone)
	for k in 11:
		ci.draw_rect(Rect2(at.x - 220 + k * 40, at.y - 200, 22, 20), stone)
	for tx in [-250.0, -90.0, 90.0, 250.0]:
		var tall := 300.0 if absf(tx) < 100 else 240.0
		ci.draw_rect(Rect2(at.x + tx - 34, at.y - tall, 68, tall + 60), stone.darkened(0.08))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x + tx - 42, at.y - tall), Vector2(at.x + tx, at.y - tall - 90), Vector2(at.x + tx + 42, at.y - tall)]), Color(0.45, 0.12, 0.15))
		ci.draw_line(Vector2(at.x + tx, at.y - tall - 90), Vector2(at.x + tx, at.y - tall - 130), Color(0.2, 0.2, 0.2), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(at.x + tx, at.y - tall - 130), Vector2(at.x + tx + 30, at.y - tall - 120), Vector2(at.x + tx, at.y - tall - 110)]), Color(0.6, 0.1, 0.15))
		ci.draw_rect(Rect2(at.x + tx - 8, at.y - tall + 40, 16, 26), Color(1.0, 0.8, 0.3, 0.7))
	ci.draw_colored_polygon(_oval(Vector2(at.x, at.y + 20), 40, 60), Color(0.12, 0.1, 0.12))


static func _oval(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points


## One layer of scenery, painted once by the Background.
class Layer extends Node2D:
	var paint: Callable

	func _draw() -> void:
		paint.call(self)


## Windmill sails, turning slowly.
class Spinner extends Node2D:
	func _process(delta: float) -> void:
		rotation += delta * 0.7

	func _draw() -> void:
		var wood := Color(0.5, 0.35, 0.2)
		for k in 4:
			var dir := Vector2.from_angle(k * TAU / 4.0)
			var side := dir.orthogonal()
			draw_line(Vector2.ZERO, dir * 82, wood, 4.0, true)
			var sail := PackedVector2Array([dir * 20 + side * 2, dir * 80 + side * 2, dir * 80 + side * 19, dir * 20 + side * 14])
			draw_colored_polygon(sail, Color(0.96, 0.95, 0.9))
			for t in [0.4, 0.7]:
				draw_line(dir * 80 * t + side * 2, dir * 80 * t + side * (14 + 5 * t), Color(0.7, 0.66, 0.6), 1.0)
			sail.append(sail[0])
			draw_polyline(sail, Color(0.45, 0.4, 0.34), 1.5, true)
		draw_circle(Vector2.ZERO, 8, Color(0.4, 0.3, 0.2))
		draw_circle(Vector2(-2, -2), 3, Color(0.6, 0.48, 0.35))


## Clouds, birds and weather, redrawn every frame. Birds take off when something crashes.
class Ambience extends Node2D:
	var area: Dictionary
	var seed_value := 1
	var clouds := []
	var flakes := []
	var birds := []
	var time := 0.0

	func _ready() -> void:
		add_to_group("camera_shake")
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + 5
		var dark: bool = area.get("night", false) or area.style == "volcano"
		var count := 4 if dark else 7
		for i in count:
			clouds.append({"pos": Vector2(rng.randf_range(-400, 2200), rng.randf_range(30, 240)),
				"scale": rng.randf_range(0.6, 1.3), "speed": rng.randf_range(5, 15)})
		if not dark and area.style in ["farm", "forest", "river", "beach", "canyon"]:
			var flock := Vector2(rng.randf_range(-200, 600), rng.randf_range(120, 260))
			for i in 5:
				birds.append({"pos": flock + Vector2(i * 26 - absf(i - 2) * 6, absf(i - 2) * 14), "vel": Vector2(rng.randf_range(38, 46), 0),
					"phase": rng.randf() * TAU})
		var weather: String = area.get("weather", "")
		if weather != "":
			for i in 70 if weather == "snow" else 30:
				flakes.append(Vector2(rng.randf_range(-400, 2200), rng.randf_range(-300, 700)))

	## Called through the "camera_shake" group: a big crash startles the birds.
	func shake(amount: float) -> void:
		if amount < 0.3:
			return
		for bird in birds:
			bird.vel = Vector2(randf_range(160, 260), randf_range(-160, -80))

	func _process(delta: float) -> void:
		time += delta
		for cloud in clouds:
			var pos: Vector2 = cloud.pos
			pos.x += cloud.speed * delta
			if pos.x > 2300.0:
				pos.x = -500.0
			cloud.pos = pos
		for bird in birds:
			var vel: Vector2 = bird.vel
			vel = vel.lerp(Vector2(42, 0), 1.0 - exp(-delta * 0.3))
			bird.vel = vel
			bird.pos += vel * delta
			if bird.pos.x > 2400.0 or bird.pos.y < -600.0:
				bird.pos = Vector2(-500.0, randf_range(120, 260))
		var weather: String = area.get("weather", "")
		for i in flakes.size():
			var p: Vector2 = flakes[i]
			match weather:
				"snow":
					p += Vector2(sin(time + i) * 20.0, 60.0) * delta
				"embers":
					p += Vector2(sin(time * 2.0 + i) * 15.0, -50.0) * delta
				"fireflies":
					p += Vector2(sin(time * 0.8 + i * 1.3), cos(time * 0.6 + i)) * 20.0 * delta
			if p.y > 720.0:
				p.y = -300.0
			elif p.y < -300.0:
				p.y = 720.0
			flakes[i] = p
		queue_redraw()

	func _draw() -> void:
		var dark: bool = area.get("night", false) or area.style == "volcano"
		var puff := Color(0.3, 0.25, 0.3, 0.6) if dark else Color(1, 1, 1, 0.95)
		var under := Color(0.25, 0.2, 0.25, 0.6) if dark else Color(0.82, 0.88, 0.96, 0.95)
		var puffs := [Vector2(-40, 8), Vector2(-14, -12), Vector2(18, -8), Vector2(44, 8), Vector2(0, 10)]
		for cloud in clouds:
			# A shaded underside, the white puffs, then a lit top.
			for offset: Vector2 in puffs:
				draw_circle(cloud.pos + (offset + Vector2(0, 6)) * cloud.scale, 28.0 * cloud.scale, under)
			for offset: Vector2 in puffs:
				draw_circle(cloud.pos + offset * cloud.scale, 26.0 * cloud.scale, puff)
			if not dark:
				draw_circle(cloud.pos + Vector2(-18, -18) * cloud.scale, 14.0 * cloud.scale, Color(1, 1, 1, 1))
		for bird in birds:
			var flap := sin(time * 9.0 + bird.phase) * 5.0
			var at: Vector2 = bird.pos
			draw_polyline(PackedVector2Array([at + Vector2(-8, -flap), at + Vector2(-3, 0), at, at + Vector2(3, 0), at + Vector2(8, -flap)]),
				Color(0.2, 0.2, 0.28), 2.0, true)
		var weather: String = area.get("weather", "")
		for i in flakes.size():
			match weather:
				"snow":
					draw_circle(flakes[i], 2.5, Color(1, 1, 1, 0.9))
				"embers":
					draw_circle(flakes[i], 2.0, Color(1.0, 0.6 + 0.3 * sin(time * 5.0 + i), 0.2, 0.9))
				"fireflies":
					draw_circle(flakes[i], 2.5, Color(0.8, 1.0, 0.4, 0.5 + 0.5 * sin(time * 3.0 + i * 2.0)))
