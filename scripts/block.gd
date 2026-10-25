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

var size := Vector2(20, 100)
var color := Color.WHITE
var kind := "wood"
var shape := "rect"


func configure(p_size: Vector2, p_kind: String, p_shape := "rect") -> void:
	var data: Dictionary = KINDS[p_kind]
	kind = p_kind
	shape = p_shape
	size = p_size
	color = data.color
	max_health = data.health
	damage_threshold = 150.0
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
	var fill := color.darkened(damage_ratio() * 0.5)
	var edge := color.darkened(0.4)
	match shape:
		"tri":
			var points := _tri_points()
			draw_colored_polygon(points, fill)
			if kind in ["redwood", "wood"]:
				for i in 3:
					var y := size.y * (0.5 - (i + 1) * 0.25)
					var half := size.x / 2.0 * (1.0 - (i + 1) * 0.25)
					draw_line(Vector2(-half, y), Vector2(half, y), color.darkened(0.2), 1.0)
			points.append(points[0])
			draw_polyline(points, edge, 2.0)
		"circle":
			var r := size.x / 2.0
			draw_circle(Vector2.ZERO, r, fill)
			if kind == "hay":
				draw_arc(Vector2.ZERO, r * 0.65, 0, TAU, 20, color.darkened(0.2), 2.0)
				draw_arc(Vector2.ZERO, r * 0.3, 0, TAU, 12, color.darkened(0.2), 2.0)
			elif kind == "wood":
				draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 20, color.darkened(0.25), 1.5)
				draw_arc(Vector2.ZERO, r * 0.25, 0, TAU, 12, color.darkened(0.25), 1.5)
			else:
				draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.25, color.lightened(0.2))
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, edge, 2.0)
		_:
			_draw_rect(fill, edge)
	# Cracks appear as the block takes damage.
	var crack := color.darkened(0.6)
	if damage_ratio() > 0.3:
		draw_line(-size / 5.0, size / 6.0, crack, 2.0)
	if damage_ratio() > 0.6:
		draw_line(Vector2(size.x / 5.0, -size.y / 4.0), Vector2(-size.x / 6.0, size.y / 5.0), crack, 2.0)


func _draw_rect(fill: Color, edge: Color) -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, fill)
	match kind:
		"wood", "redwood":
			# Grain along the long side.
			var grain := color.darkened(0.18)
			if size.y > size.x:
				draw_line(Vector2(-size.x * 0.15, -size.y * 0.45), Vector2(-size.x * 0.15, size.y * 0.45), grain, 1.0)
				draw_line(Vector2(size.x * 0.2, -size.y * 0.3), Vector2(size.x * 0.2, size.y * 0.4), grain, 1.0)
			else:
				draw_line(Vector2(-size.x * 0.45, -size.y * 0.15), Vector2(size.x * 0.45, -size.y * 0.15), grain, 1.0)
				draw_line(Vector2(-size.x * 0.3, size.y * 0.2), Vector2(size.x * 0.4, size.y * 0.2), grain, 1.0)
		"ice", "glass":
			draw_line(-size / 2.0 + Vector2(3, 3), Vector2(-size.x / 2.0 + 3, size.y / 2.0 - 3), Color(1, 1, 1, 0.6), 2.0)
		"metal":
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				draw_circle(corner * (size / 2.0 - Vector2(4, 4)), 1.8, color.darkened(0.35))
		"stone":
			draw_line(Vector2(-size.x / 2.0, 0), Vector2(size.x / 2.0, 0), color.darkened(0.15), 1.0)
		"hay", "cloth":
			for i in 3:
				var y := -size.y / 2.0 + size.y * (i + 1) / 4.0
				draw_line(Vector2(-size.x / 2.0, y), Vector2(size.x / 2.0, y), color.darkened(0.15), 1.0)
	draw_rect(rect, edge, false, 2.0)
