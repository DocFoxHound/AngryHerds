## Shared drawing for herd animals and wolves, used by the physics bodies, story actors, the
## map token and menu icons. Call from inside a CanvasItem's _draw(). Each function sets the
## canvas transform itself (position, scale, rotation, flip), then draws at base size:
## animals have radius 22, wolves 20.

const Catalog := preload("res://scripts/catalog.gd")

const INK := Color(0.08, 0.06, 0.05)


## mood: "angry" (default), "scared" or "happy".
static func animal(ci: CanvasItem, kind: String, at := Vector2.ZERO, scale := 1.0, rot := 0.0,
		mood := "angry", flip := false) -> void:
	ci.draw_set_transform(at, rot, Vector2(-scale if flip else scale, scale))
	var data: Dictionary = Catalog.ANIMALS[kind]
	var body: Color = data.color
	var outline := body.darkened(0.35)
	var r := 22.0
	match kind:
		"sheep":
			for i in 12:
				ci.draw_circle(Vector2.from_angle(TAU * i / 12.0) * r * 0.85, 9.5, body.darkened(0.3))
			for i in 12:
				ci.draw_circle(Vector2.from_angle(TAU * i / 12.0) * r * 0.85, 8.0, body)
			ci.draw_circle(Vector2.ZERO, r, body)
		"goat":
			var horn := Color(0.55, 0.45, 0.35)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -18), Vector2(-20, -32), Vector2(-28, -24), Vector2(-14, -14)]), horn)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(6, -18), Vector2(20, -32), Vector2(28, -24), Vector2(14, -14)]), horn)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 18), Vector2(5, 18), Vector2(0, 32)]), body.darkened(0.3))
			_disc(ci, r, body, outline)
		"cow":
			var horn := Color(0.9, 0.85, 0.7)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, -14), Vector2(-24, -30), Vector2(-8, -18)]), horn)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(14, -14), Vector2(24, -30), Vector2(8, -18)]), horn)
			_disc(ci, r, body, outline)
			var spot := Color(0.2, 0.15, 0.1)
			ci.draw_circle(Vector2(-12, 10), 6, spot)
			ci.draw_circle(Vector2(13, -12), 5, spot)
			ci.draw_circle(Vector2(-15, -6), 3, spot)
		"bull":
			var horn := Color(0.95, 0.92, 0.82)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-12, -14), Vector2(-26, -20), Vector2(-36, -34), Vector2(-24, -12), Vector2(-14, -8)]), horn)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(12, -14), Vector2(14, -8), Vector2(24, -12), Vector2(36, -34), Vector2(26, -20)]), horn)
			_disc(ci, r, body, body.darkened(0.4))
			ci.draw_circle(Vector2(0, -16), 6, body.darkened(0.25))
		"chicken":
			var comb := Color(0.9, 0.15, 0.15)
			for x in [-6.0, 0.0, 6.0]:
				ci.draw_circle(Vector2(x, -22), 5.0, comb)
			ci.draw_colored_polygon(_ellipse(Vector2(-19, 6), 7, 10), body.darkened(0.12))
			ci.draw_colored_polygon(_ellipse(Vector2(19, 6), 7, 10), body.darkened(0.12))
			_disc(ci, r, body, outline)
		"duck", "duckling":
			for i in 3:
				ci.draw_line(Vector2(-2 + i * 2, -21), Vector2(-5 + i * 5, -29), body.darkened(0.2), 3.0)
			_disc(ci, r, body, outline)
		"pig":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, -12), Vector2(-20, -28), Vector2(-6, -19)]), body.darkened(0.12))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(16, -12), Vector2(20, -28), Vector2(6, -19)]), body.darkened(0.12))
			_disc(ci, r, body, outline)
	_animal_face(ci, mood)
	match kind:
		"chicken":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 5), Vector2(5, 5), Vector2(0, 13)]), Color(1.0, 0.7, 0.15))
			ci.draw_circle(Vector2(0, 15), 3.0, Color(0.9, 0.15, 0.15))
		"duck", "duckling":
			ci.draw_colored_polygon(_ellipse(Vector2(0, 9), 10, 5), Color(1.0, 0.55, 0.1))
			ci.draw_line(Vector2(-8, 9), Vector2(8, 9), Color(0.75, 0.35, 0.05), 1.5)
		"pig":
			ci.draw_colored_polygon(_ellipse(Vector2(0, 9), 9, 7), body.darkened(0.15))
			ci.draw_circle(Vector2(-3, 9), 2.0, body.darkened(0.55))
			ci.draw_circle(Vector2(3, 9), 2.0, body.darkened(0.55))
		"bull":
			ci.draw_colored_polygon(_ellipse(Vector2(0, 10), 11, 7), Color(0.6, 0.4, 0.35))
			ci.draw_circle(Vector2(-4, 9), 2.0, INK)
			ci.draw_circle(Vector2(4, 9), 2.0, INK)
			ci.draw_arc(Vector2(0, 15), 5.0, 0.2, PI - 0.2, 10, Color(1.0, 0.8, 0.2), 2.0)
		"cow":
			ci.draw_circle(Vector2(0, 9), 7, Color(1.0, 0.75, 0.75))
			ci.draw_circle(Vector2(-3, 9), 1.5, Color(0.5, 0.25, 0.25))
			ci.draw_circle(Vector2(3, 9), 1.5, Color(0.5, 0.25, 0.25))
		_:
			ci.draw_circle(Vector2(0, 9), 6, Color(1.0, 0.75, 0.75))


static func _animal_face(ci: CanvasItem, mood: String) -> void:
	match mood:
		"happy":
			ci.draw_arc(Vector2(-7, -2), 4.0, PI, TAU, 8, INK, 2.0)
			ci.draw_arc(Vector2(7, -2), 4.0, PI, TAU, 8, INK, 2.0)
		"scared":
			ci.draw_circle(Vector2(-7, -3), 5, Color.WHITE)
			ci.draw_circle(Vector2(7, -3), 5, Color.WHITE)
			ci.draw_circle(Vector2(-7, -3), 1.5, INK)
			ci.draw_circle(Vector2(7, -3), 1.5, INK)
			ci.draw_line(Vector2(-12, -12), Vector2(-4, -14), INK, 2.5)
			ci.draw_line(Vector2(12, -12), Vector2(4, -14), INK, 2.5)
		_:
			ci.draw_circle(Vector2(-7, -3), 4, Color.WHITE)
			ci.draw_circle(Vector2(7, -3), 4, Color.WHITE)
			ci.draw_circle(Vector2(-6, -2), 2, INK)
			ci.draw_circle(Vector2(6, -2), 2, INK)
			ci.draw_line(Vector2(-12, -11), Vector2(-3, -7), INK, 3.0)
			ci.draw_line(Vector2(12, -11), Vector2(3, -7), INK, 3.0)


## hurt 0..1 reddens the fur and squints the eyes; growl 0..1 opens the jaw.
## show_armor false once the helmet has been knocked off.
static func wolf(ci: CanvasItem, variant: String, at := Vector2.ZERO, scale := 1.0, rot := 0.0,
		hurt := 0.0, growl := 0.0, show_armor := true, flip := false) -> void:
	ci.draw_set_transform(at, rot, Vector2(-scale if flip else scale, scale))
	var data: Dictionary = Catalog.WOLVES[variant]
	var extras: Array = data.get("extras", [])
	var base: Color = data.fur
	var fur := base.lerp(Color(0.85, 0.3, 0.3, base.a), hurt * 0.7)
	if "glow" in extras:
		ci.draw_circle(Vector2.ZERO, 30, Color(0.6, 1.0, 0.8, 0.18))
		ci.draw_circle(Vector2.ZERO, 25, Color(0.6, 1.0, 0.8, 0.2))
	if "cape" in extras:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, 8), Vector2(14, 8), Vector2(26, 30), Vector2(-26, 30)]), Color(0.55, 0.1, 0.15))
		ci.draw_line(Vector2(-26, 30), Vector2(26, 30), Color(1.0, 0.85, 0.3), 2.0)
	# Ears
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, -8), Vector2(-12, -28), Vector2(-4, -16)]), fur.darkened(0.2))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(16, -8), Vector2(12, -28), Vector2(4, -16)]), fur.darkened(0.2))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-13, -12), Vector2(-11.5, -22), Vector2(-7, -15)]), Color(0.85, 0.6, 0.6, fur.a))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(13, -12), Vector2(11.5, -22), Vector2(7, -15)]), Color(0.85, 0.6, 0.6, fur.a))
	if "horns" in extras:
		var horn := Color(0.2, 0.15, 0.12)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, -16), Vector2(-20, -34), Vector2(-4, -19)]), horn)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(10, -16), Vector2(4, -19), Vector2(20, -34)]), horn)
	ci.draw_circle(Vector2.ZERO, 20, fur)
	ci.draw_arc(Vector2.ZERO, 20, 0, TAU, 32, fur.darkened(0.3), 1.5)
	if "scarf" in extras:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-17, 12), Vector2(17, 12), Vector2(14, 20), Vector2(-14, 20)]), Color(0.85, 0.15, 0.2))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 16), Vector2(15, 16), Vector2(18, 30), Vector2(11, 30)]), Color(0.75, 0.1, 0.15))
	if "tie" in extras:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 17), Vector2(6, 17), Vector2(0, 21)]), Color(0.95, 0.95, 0.95))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-2, 19), Vector2(2, 19), Vector2(4, 29), Vector2(0, 33), Vector2(-4, 29)]), Color(0.8, 0.1, 0.1))
	# Snout and mouth
	ci.draw_circle(Vector2(0, 7), 8, fur.lightened(0.3))
	if growl > 0.05:
		ci.draw_colored_polygon(_ellipse(Vector2(0, 12), 6, 2.0 + growl * 4.0), Color(0.45, 0.05, 0.08))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 10), Vector2(-3, 10), Vector2(-4, 13)]), Color.WHITE)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(3, 10), Vector2(5, 10), Vector2(4, 13)]), Color.WHITE)
	else:
		ci.draw_line(Vector2(-4, 11), Vector2(4, 11), fur.darkened(0.5), 1.5)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(2, 11), Vector2(4, 11), Vector2(3, 14)]), Color.WHITE)
	ci.draw_circle(Vector2(0, 4), 3, INK)
	# Eyes and mean brows
	var eye := Color(0.4, 1.0, 0.8) if "glow" in extras else Color(1.0, 0.85, 0.1)
	if hurt > 0.0:
		ci.draw_line(Vector2(-10, -5), Vector2(-4, -5), INK, 2.5)
		ci.draw_line(Vector2(4, -5), Vector2(10, -5), INK, 2.5)
	else:
		ci.draw_circle(Vector2(-7, -5), 3.5, eye)
		ci.draw_circle(Vector2(7, -5), 3.5, eye)
		ci.draw_circle(Vector2(-7, -5), 1.5, INK)
		ci.draw_circle(Vector2(7, -5), 1.5, INK)
	ci.draw_line(Vector2(-12, -11), Vector2(-3, -8), INK, 2.5)
	ci.draw_line(Vector2(12, -11), Vector2(3, -8), INK, 2.5)
	if "scar" in extras:
		ci.draw_line(Vector2(-11, -14), Vector2(-4, 1), Color(0.6, 0.15, 0.15), 1.5)
	if "mask" in extras:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-19, -9), Vector2(19, -9), Vector2(18, -1), Vector2(-18, -1)]), INK)
		ci.draw_circle(Vector2(-7, -5), 2.5, eye)
		ci.draw_circle(Vector2(7, -5), 2.5, eye)
	if "eyepatch" in extras:
		ci.draw_line(Vector2(-18, -13), Vector2(17, 0), INK, 1.5)
		ci.draw_circle(Vector2(7, -5), 5, INK)
	if "shades" in extras:
		ci.draw_colored_polygon(_ellipse(Vector2(-7, -5), 6, 4), INK)
		ci.draw_colored_polygon(_ellipse(Vector2(7, -5), 6, 4), INK)
		ci.draw_line(Vector2(-2, -6), Vector2(2, -6), INK, 2.0)
	# Hats
	if "bandana" in extras:
		var red := Color(0.8, 0.12, 0.12)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-19, -8), Vector2(-14, -17), Vector2(0, -21), Vector2(14, -17), Vector2(19, -8)]), red)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(17, -10), Vector2(27, -14), Vector2(25, -4)]), red)
		ci.draw_circle(Vector2(-6, -15), 1.5, Color.WHITE)
		ci.draw_circle(Vector2(6, -14), 1.5, Color.WHITE)
	if "tricorn" in extras:
		var hat := Color(0.12, 0.1, 0.12)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-28, -14), Vector2(0, -22), Vector2(28, -14), Vector2(16, -36), Vector2(-16, -36)]), hat)
		ci.draw_line(Vector2(-28, -14), Vector2(28, -14), Color(0.9, 0.75, 0.3), 2.0)
		ci.draw_circle(Vector2(0, -27), 4, Color.WHITE)
	if "cowboy" in extras:
		var hat := Color(0.45, 0.3, 0.15)
		ci.draw_colored_polygon(_ellipse(Vector2(0, -15), 27, 5), hat.darkened(0.15))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-13, -15), Vector2(-11, -31), Vector2(0, -27), Vector2(11, -31), Vector2(13, -15)]), hat)
		ci.draw_line(Vector2(-13, -18), Vector2(13, -18), Color(0.25, 0.15, 0.08), 3.0)
	if "buckethat" in extras:
		var hat := Color(0.4, 0.55, 0.35)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-24, -11), Vector2(24, -11), Vector2(14, -19), Vector2(-14, -19)]), hat.darkened(0.15))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, -18), Vector2(14, -18), Vector2(11, -31), Vector2(-11, -31)]), hat)
	if "tophat" in extras:
		var hat := Color(0.1, 0.1, 0.12)
		ci.draw_rect(Rect2(-22, -17, 44, 5), hat)
		ci.draw_rect(Rect2(-13, -42, 26, 26), hat)
		ci.draw_rect(Rect2(-13, -22, 26, 4), Color(0.7, 0.1, 0.1))
	if "leafcrown" in extras:
		for i in 7:
			var a := PI + 0.25 + i * (PI - 0.5) / 6.0
			ci.draw_colored_polygon(_ellipse(Vector2.from_angle(a) * 19.0, 5, 3), Color(0.3, 0.6, 0.2))
	if "crown" in extras:
		var gold := Color(1.0, 0.82, 0.2)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, -17), Vector2(14, -17), Vector2(16, -36), Vector2(8, -26), Vector2(0, -38), Vector2(-8, -26), Vector2(-16, -36)]), gold)
		ci.draw_circle(Vector2(0, -22), 2.5, Color(0.8, 0.1, 0.2))
	if show_armor and "hardhat" in extras:
		var yellow := Color(1.0, 0.8, 0.1)
		ci.draw_colored_polygon(_half_disc(Vector2(0, -12), 17), yellow)
		ci.draw_rect(Rect2(-22, -14, 44, 4), yellow.darkened(0.15))
		ci.draw_line(Vector2(0, -28), Vector2(0, -14), yellow.darkened(0.25), 3.0)
	if show_armor and "knight" in extras:
		var steel := Color(0.7, 0.72, 0.78)
		ci.draw_colored_polygon(_half_disc(Vector2(0, -2), 22), steel)
		ci.draw_rect(Rect2(-21, -9, 42, 7), steel.darkened(0.1))
		ci.draw_rect(Rect2(-15, -7, 30, 3), INK)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, -24), Vector2(3, -24), Vector2(0, -38)]), Color(0.8, 0.15, 0.15))


static func _disc(ci: CanvasItem, r: float, body: Color, outline: Color) -> void:
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r, 0, TAU, 32, outline, 2.0)


static func _ellipse(center: Vector2, rx: float, ry: float, sides := 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points


## The top half of a disc, flat side down.
static func _half_disc(center: Vector2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		points.append(center + Vector2.from_angle(PI + PI * i / 12.0) * r)
	return points
