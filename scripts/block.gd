extends "res://scripts/destructible.gd"
## A building block: a rectangle, a triangular roof or a round bale/boulder, in one of the
## materials below.

## breaks: which shatter effect it uses. hit / smash: sounds for a knock and for breaking.
const KINDS := {
	"wood": {"color": Color(0.76, 0.53, 0.30), "health": 300.0, "density": 1.0, "points": 500, "breaks": "wood", "hit": "wood", "smash": "wood_break"},
	"redwood": {"color": Color(0.72, 0.24, 0.18), "health": 300.0, "density": 1.0, "points": 500, "breaks": "wood", "hit": "wood", "smash": "wood_break"},
	"hay": {"color": Color(0.93, 0.8, 0.38), "health": 150.0, "density": 0.5, "points": 300, "breaks": "wood", "hit": "hay", "smash": "hay"},
	"cloth": {"color": Color(0.95, 0.93, 0.85), "health": 90.0, "density": 0.3, "points": 200, "breaks": "wood", "hit": "hay", "smash": "hay"},
	"stone": {"color": Color(0.55, 0.56, 0.60), "health": 900.0, "density": 2.5, "points": 800, "breaks": "stone", "hit": "stone", "smash": "stone_break"},
	"ice": {"color": Color(0.70, 0.90, 1.00, 0.85), "health": 120.0, "density": 0.8, "points": 300, "breaks": "ice", "hit": "ice", "smash": "ice_break"},
	"glass": {"color": Color(0.65, 0.92, 0.88, 0.6), "health": 100.0, "density": 0.9, "points": 400, "breaks": "ice", "hit": "ice", "smash": "glass_break"},
	"metal": {"color": Color(0.6, 0.63, 0.7), "health": 1600.0, "density": 2.0, "points": 1000, "breaks": "stone", "hit": "clang", "smash": "clang"},
}

## Blocks soak up part of each knock, and no single knock breaks a fresh one, so hit pieces fly
## and tumble first and break when they crash into something.
const IMPACT_DAMAGE := 0.8
const MAX_HIT := 0.6

var size := Vector2(20, 100)
var color := Color.WHITE
var kind := "wood"
var shape := "rect"
## Seeds the random details (knots, speckles, cracks) so they stay put between redraws.
var look_seed := 0


func configure(p_size: Vector2, p_kind: String, p_shape := "rect") -> void:
	var data: Dictionary = KINDS[p_kind]
	kind = p_kind
	shape = p_shape
	size = p_size
	color = data.color
	max_health = data.health
	damage_threshold = 150.0
	impact_damage = IMPACT_DAMAGE
	max_hit = MAX_HIT
	var area := size.x * size.y
	if shape == "tri":
		area *= 0.5
	elif shape == "circle":
		area *= PI / 4.0
	mass = maxf(data.density * area / 1000.0, 0.2)
	points = data.points
	hit_sound = data.hit


func _ready() -> void:
	super()
	look_seed = randi()
	var collision := CollisionShape2D.new()
	match shape:
		"tri":
			var tri := ConvexPolygonShape2D.new()
			tri.points = _tri_points()
			collision.shape = tri
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = size.x / 2.0
			collision.shape = circle
		_:
			var rect := RectangleShape2D.new()
			rect.size = size
			collision.shape = rect
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.friction = 0.9
	physics_material_override = material


func _tri_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-size.x / 2.0, size.y / 2.0), Vector2(0, -size.y / 2.0), Vector2(size.x / 2.0, size.y / 2.0)])


func _break() -> void:
	var data: Dictionary = KINDS[kind]
	Effects.shatter(get_parent(), global_position, global_rotation, size, color, data.breaks, linear_velocity)
	Sfx.play(data.smash)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var fill := color.darkened(damage_ratio() * 0.35)
	var edge := Color(color.darkened(0.6), maxf(color.a, 0.9))
	match shape:
		"tri":
			var points := _tri_points()
			draw_colored_polygon(points, fill)
			if kind in ["redwood", "wood"]:
				# Roof tiles or boards in rows, shaded underneath.
				for i in 3:
					var y := size.y * (0.5 - (i + 1) * 0.25)
					var half := size.x / 2.0 * (1.0 - (i + 1) * 0.25)
					draw_line(Vector2(-half, y), Vector2(half, y), color.darkened(0.25), 2.0, true)
					draw_line(Vector2(-half, y + 2), Vector2(half, y + 2), color.lightened(0.15), 1.0, true)
			# Lit left slope, shaded right slope.
			draw_line(points[0] + Vector2(3, -2), points[1] + Vector2(0, 4), color.lightened(0.3), 2.0, true)
			draw_line(points[1] + Vector2(0, 4), points[2] + Vector2(-3, -2), color.darkened(0.2), 2.0, true)
			points.append(points[0])
			draw_polyline(points, edge, 2.5, true)
		"circle":
			var r := size.x / 2.0
			draw_circle(Vector2.ZERO, r, fill.darkened(0.15))
			draw_circle(Vector2(-r, -r) * 0.07, r * 0.9, fill)
			match kind:
				"hay":
					for k in 4:
						draw_arc(Vector2.ZERO, r * (0.2 + k * 0.2), k, k + TAU * 0.8, 20, color.darkened(0.22), 1.6, true)
				"wood", "redwood":
					for k in 3:
						draw_arc(Vector2(1, 1), r * (0.25 + k * 0.22), 0, TAU, 24, color.darkened(0.2), 1.4, true)
					draw_circle(Vector2(1, 1), r * 0.08, color.darkened(0.3))
				_:
					for k in 5:
						draw_circle(Vector2.from_angle(rng.randf() * TAU) * r * rng.randf_range(0.2, 0.7), r * rng.randf_range(0.06, 0.12), color.darkened(0.15))
			draw_colored_polygon(_oval(Vector2(-r * 0.38, -r * 0.42), r * 0.28, r * 0.16, -0.6), Color(1, 1, 1, 0.3))
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, edge, 2.5, true)
		_:
			_draw_rect(fill, edge, rng)
	# Cracks spread as the block takes damage.
	var crack := color.darkened(0.65)
	for i in int(damage_ratio() * 4.0):
		var points := PackedVector2Array()
		var at := Vector2(rng.randf_range(-0.5, 0.5) * size.x, -size.y / 2.0 if rng.randf() < 0.5 else size.y / 2.0)
		var heading := (-at).normalized()
		for step in 5:
			points.append(at)
			at += heading.rotated(rng.randf_range(-0.9, 0.9)) * minf(size.x, size.y) * 0.3
			at = at.clamp(-size / 2.0, size / 2.0)
		draw_polyline(points, crack, 2.0, true)


func _draw_rect(fill: Color, edge: Color, rng: RandomNumberGenerator) -> void:
	var half := size / 2.0
	var corner := minf(4.0, minf(size.x, size.y) / 4.0)
	var body := _rounded(Rect2(-half, size), corner)
	draw_colored_polygon(body, fill)
	var long_x := size.x >= size.y
	match kind:
		"wood", "redwood":
			# Planks with wavy grain, a knot, and nails at the ends.
			var grain := color.darkened(0.2)
			var length := size.x if long_x else size.y
			var across := size.y if long_x else size.x
			var lines := clampi(int(across / 7.0), 1, 4)
			for i in lines:
				var o := -across / 2.0 + across * (i + 1) / (lines + 1)
				var points := PackedVector2Array()
				for k in 6:
					var t := -length / 2.0 + 3.0 + (length - 6.0) * k / 5.0
					var wobble := sin(t * 0.08 + i * 2.0) * 1.2
					points.append(Vector2(t, o + wobble) if long_x else Vector2(o + wobble, t))
				draw_polyline(points, grain, 1.0, true)
			var knot_t := rng.randf_range(-0.3, 0.3) * length
			var knot := Vector2(knot_t, rng.randf_range(-0.2, 0.2) * across) if long_x else Vector2(rng.randf_range(-0.2, 0.2) * across, knot_t)
			draw_colored_polygon(_oval(knot, 3.5 if long_x else 2.2, 2.2 if long_x else 3.5), color.darkened(0.3))
			draw_colored_polygon(_oval(knot, 1.6, 1.2), color.darkened(0.45))
			if length > 40.0:
				for end in [-1.0, 1.0]:
					var t: float = end * (length / 2.0 - 5.0)
					for o in ([-across * 0.25, across * 0.25] if across > 14.0 else [0.0]):
						draw_circle(Vector2(t, o) if long_x else Vector2(o, t), 1.6, color.darkened(0.55))
		"ice", "glass":
			# Inner frost line and glossy streaks.
			var inner := _rounded(Rect2(-half + Vector2(3, 3), size - Vector2(6, 6)), maxf(corner - 2.0, 0.0))
			inner.append(inner[0])
			draw_polyline(inner, Color(1, 1, 1, 0.35), 1.5, true)
			var streak := minf(size.x, size.y) * 0.5
			for k in 2:
				var c := Vector2(-half.x * 0.35 + k * streak * 0.6, -half.y * 0.25 + k * streak * 0.4)
				var d := Vector2(streak * 0.35, -streak * 0.35)
				d = d.limit_length(minf(size.x, size.y) * 0.45)
				draw_line(c - d, c + d, Color(1, 1, 1, 0.55 - k * 0.2), 3.0 - k, true)
		"metal":
			draw_line(Vector2(-half.x + 3, -half.y + 3), Vector2(half.x - 3, -half.y + 3), Color(1, 1, 1, 0.35), 2.0)
			for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var at := c * (half - Vector2(5, 5))
				draw_circle(at, 2.4, color.darkened(0.35))
				draw_circle(at + Vector2(-0.6, -0.6), 1.0, color.lightened(0.35))
		"stone":
			# Staggered bricks with mortar lines and a little texture.
			var mortar := color.darkened(0.25)
			var rows := maxi(1, int(round(size.y / 16.0)))
			var row_h := size.y / rows
			for row in rows:
				var y0 := -half.y + row * row_h
				if row > 0:
					draw_line(Vector2(-half.x + 1, y0), Vector2(half.x - 1, y0), mortar, 1.5)
				var brick := clampf(size.x / maxf(round(size.x / 28.0), 1.0), 14.0, 40.0)
				var x := -half.x + (brick * 0.5 if row % 2 == 1 else brick)
				while x < half.x - 4.0:
					draw_line(Vector2(x, y0 + 1), Vector2(x, y0 + row_h - 1), mortar, 1.5)
					x += brick
				draw_line(Vector2(-half.x + 3, y0 + 2.5), Vector2(half.x - 3, y0 + 2.5), color.lightened(0.15), 1.0)
			for k in int(size.x * size.y / 400.0):
				draw_circle(Vector2(rng.randf_range(-half.x + 3, half.x - 3), rng.randf_range(-half.y + 3, half.y - 3)), rng.randf_range(0.8, 1.6), color.darkened(rng.randf_range(0.1, 0.25)))
		"hay":
			for k in int(size.x * size.y / 60.0):
				var at := Vector2(rng.randf_range(-half.x + 3, half.x - 4), rng.randf_range(-half.y + 3, half.y - 3))
				draw_line(at, at + Vector2(rng.randf_range(4, 9), rng.randf_range(-1.5, 1.5)), color.darkened(0.2) if k % 2 else color.lightened(0.25), 1.0, true)
			for t in [-0.25, 0.25]:
				if long_x:
					draw_line(Vector2(size.x * t, -half.y + 1), Vector2(size.x * t, half.y - 1), Color(0.55, 0.35, 0.18), 2.0)
				else:
					draw_line(Vector2(-half.x + 1, size.y * t), Vector2(half.x - 1, size.y * t), Color(0.55, 0.35, 0.18), 2.0)
		"cloth":
			for i in 3:
				var y := -half.y + size.y * (i + 1) / 4.0
				draw_line(Vector2(-half.x, y), Vector2(half.x, y), color.darkened(0.15), 1.0)
	# Bevel: light along the top and left, shade along the bottom and right.
	var light := Color(1, 1, 1, 0.28)
	var shade := Color(0, 0, 0, 0.18)
	draw_line(Vector2(-half.x + corner, -half.y + 1.5), Vector2(half.x - corner, -half.y + 1.5), light, 3.0)
	draw_line(Vector2(-half.x + 1.5, -half.y + corner), Vector2(-half.x + 1.5, half.y - corner), light, 3.0)
	draw_line(Vector2(-half.x + corner, half.y - 1.5), Vector2(half.x - corner, half.y - 1.5), shade, 3.0)
	draw_line(Vector2(half.x - 1.5, -half.y + corner), Vector2(half.x - 1.5, half.y - corner), shade, 3.0)
	body.append(body[0])
	draw_polyline(body, edge, 2.5, true)


## A rectangle with its corners rounded off.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if radius <= 0.5:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var corners := [Vector2(rect.end.x - radius, rect.position.y + radius), Vector2(rect.end.x - radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius), Vector2(rect.position.x + radius, rect.position.y + radius)]
	for i in 4:
		for k in 4:
			points.append(corners[i] + Vector2.from_angle(-PI / 2.0 + (i + k / 3.0) * PI / 2.0) * radius)
	return points


static func _oval(center: Vector2, rx: float, ry: float, rot := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return points
