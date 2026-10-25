## Shared drawing for herd animals and wolves, used by the physics bodies, story actors, the
## map token and menu icons. Call from inside a CanvasItem's _draw(). Each function sets the
## canvas transform itself (position, scale, rotation, flip), then draws at base size:
## animals have radius 22, wolves 20.
##
## Characters are inked cartoons: a dark outline, a shaded side and a highlight, and faces
## that change with mood. The optional pose dictionary animates them:
##   look: Vector2 where the pupils point, length 0..1 (in the character's own frame)
##   blink: 0..1, how far the eyelids are shut
##   squash: Vector2 scale applied along squash_dir (radians), for squash and stretch
##   flash: 0..1 white flash when hit

const Catalog := preload("res://scripts/catalog.gd")

const INK := Color(0.08, 0.06, 0.05)
## The outline around every shape, and its width at base size.
const OUTLINE := Color(0.14, 0.09, 0.07)
const LINE := 2.6
const HOOF := Color(0.26, 0.2, 0.18)
const BEAK := Color(1.0, 0.62, 0.12)


## mood: "angry" (default), "scared", "happy", "scream" (in flight) or "dizzy".
static func animal(ci: CanvasItem, kind: String, at := Vector2.ZERO, scale := 1.0, rot := 0.0,
		mood := "angry", flip := false, pose := {}) -> void:
	_transform(ci, at, scale, rot, flip, pose)
	var data: Dictionary = Catalog.ANIMALS[kind]
	var body: Color = data.color
	var r := 22.0
	var skin := body
	var beaked := kind in ["chicken", "duck", "duckling"]
	_feet(ci, r, BEAK if beaked else HOOF, kind == "bull")
	match kind:
		"sheep":
			skin = Color(0.99, 0.93, 0.88)
			_fleece(ci, r, body)
			# Floppy ears poking out of the wool, then the face patch.
			for side: float in [-1.0, 1.0]:
				_shape(ci, _ellipse(Vector2(side * 17, -3), 8, 4.5, 14, side * 0.5), skin.darkened(0.12))
				ci.draw_colored_polygon(_ellipse(Vector2(side * 17, -3), 4.5, 2, 10, side * 0.5), Color(1.0, 0.72, 0.72))
			_shape(ci, _ellipse(Vector2(0, 3), 14.5, 14), skin)
			ci.draw_colored_polygon(_ellipse(Vector2(4, 8), 9, 7), Color(skin.darkened(0.06), 0.8))
			# A tuft of wool on top of the head.
			for p in [Vector2(-6, -11), Vector2(6, -11), Vector2(0, -13)]:
				ci.draw_circle(p, 6.4 + LINE * 0.5, OUTLINE)
			for p in [Vector2(-6, -11), Vector2(6, -11), Vector2(0, -13)]:
				ci.draw_circle(p, 6.4, body)
				ci.draw_circle(p + Vector2(-1.5, -1.5), 3.2, body.lightened(0.5))
		"goat":
			var horn := Color(0.62, 0.52, 0.4)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _mirror(PackedVector2Array([Vector2(-6, -17), Vector2(-14, -30), Vector2(-24, -33), Vector2(-17, -27), Vector2(-13, -15)]), side), horn)
				_shape(ci, _ellipse(Vector2(side * 21, -6), 8, 4, 12, side * 0.35), body.darkened(0.08))
			_shape(ci, PackedVector2Array([Vector2(-5, 18), Vector2(5, 18), Vector2(1, 33), Vector2(-2, 31)]), body.darkened(0.35))
			_ball(ci, Vector2.ZERO, r, body)
			ci.draw_colored_polygon(_ellipse(Vector2(0, 8), 11, 9), body.lightened(0.25))
		"cow":
			var horn := Color(0.95, 0.9, 0.75)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _mirror(PackedVector2Array([Vector2(-12, -15), Vector2(-20, -30), Vector2(-15, -31), Vector2(-6, -19)]), side), horn)
				_shape(ci, _ellipse(Vector2(side * 22, -8), 8, 4, 12, side * 0.3), body.darkened(0.06))
			_ball(ci, Vector2.ZERO, r, body)
			var spot := Color(0.22, 0.16, 0.12)
			ci.draw_colored_polygon(_ellipse(Vector2(-12, 10), 6.5, 5.5, 12, 0.4), spot)
			ci.draw_colored_polygon(_ellipse(Vector2(13, -12), 6, 4.5, 12, -0.5), spot)
			ci.draw_colored_polygon(_ellipse(Vector2(-14, -8), 3.5, 3, 10), spot)
			_outline_circle(ci, Vector2.ZERO, r)
		"bull":
			var horn := Color(0.96, 0.92, 0.82)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _mirror(PackedVector2Array([Vector2(-12, -14), Vector2(-26, -20), Vector2(-37, -35), Vector2(-24, -11), Vector2(-14, -7)]), side), horn)
			_ball(ci, Vector2.ZERO, r, body)
			ci.draw_colored_polygon(_ellipse(Vector2(0, -15), 7, 5), body.darkened(0.3))
		"chicken":
			var comb := Color(0.92, 0.18, 0.15)
			for x in [-6.0, 0.0, 6.0]:
				ci.draw_circle(Vector2(x, -22), 5.0 + LINE * 0.5, OUTLINE)
			for x in [-6.0, 0.0, 6.0]:
				ci.draw_circle(Vector2(x, -22), 5.0, comb)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _ellipse(Vector2(side * 20, 6), 7, 10, 14, side * -0.3), body.darkened(0.14))
			_ball(ci, Vector2.ZERO, r, body)
		"duck", "duckling":
			for i in 3:
				ci.draw_line(Vector2(-2 + i * 2, -21), Vector2(-5 + i * 5, -30), body.darkened(0.25), 3.0, true)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _ellipse(Vector2(side * 20, 7), 6, 9, 14, side * -0.4), body.darkened(0.12))
			_ball(ci, Vector2.ZERO, r, body)
		"pig":
			for side: float in [-1.0, 1.0]:
				_shape(ci, _mirror(PackedVector2Array([Vector2(-15, -12), Vector2(-21, -29), Vector2(-5, -19)]), side), body.darkened(0.1))
				ci.draw_colored_polygon(_mirror(PackedVector2Array([Vector2(-14, -15), Vector2(-17.5, -24), Vector2(-9, -18)]), side), body.darkened(0.25))
			_ball(ci, Vector2.ZERO, r, body)
	_animal_face(ci, mood, skin, pose, kind)
	_animal_mouth(ci, kind, mood, body)
	_flash(ci, r, pose)


static func _animal_face(ci: CanvasItem, mood: String, skin: Color, pose := {}, kind := "") -> void:
	var y := -3.0
	var spread := 8.0
	var size := 1.0
	if kind == "sheep":
		y = -1.0
		spread = 6.5
		size = 0.9
	_eyes(ci, mood, skin, Color.WHITE, pose, spread, y, size)


## Mouth, snout or beak, drawn over the face.
static func _animal_mouth(ci: CanvasItem, kind: String, mood: String, body: Color) -> void:
	var open := mood in ["scream", "scared"]
	match kind:
		"chicken":
			_beak(ci, Vector2(0, 7), 6.0, 7.0, open)
			ci.draw_circle(Vector2(0, 19.0 if open else 16.0), 3.0, Color(0.9, 0.15, 0.15))
		"duck", "duckling":
			if open:
				_shape(ci, _ellipse(Vector2(0, 7), 11, 4.5), BEAK)
				_shape(ci, _ellipse(Vector2(0, 15), 9, 4), BEAK.darkened(0.12))
				ci.draw_colored_polygon(_ellipse(Vector2(0, 11), 6, 2.5), Color(0.5, 0.1, 0.1))
			else:
				_shape(ci, _ellipse(Vector2(0, 9), 11, 5.5), BEAK)
				ci.draw_line(Vector2(-8, 9.5), Vector2(8, 9.5), BEAK.darkened(0.35), 1.5, true)
		"pig":
			_mouth(ci, Vector2(0, 16), mood)
			_shape(ci, _ellipse(Vector2(0, 8), 9, 6.5), body.darkened(0.12))
			ci.draw_colored_polygon(_ellipse(Vector2(-3, 8), 1.6, 2.4), body.darkened(0.55))
			ci.draw_colored_polygon(_ellipse(Vector2(3, 8), 1.6, 2.4), body.darkened(0.55))
		"bull":
			_mouth(ci, Vector2(0, 17), mood)
			_shape(ci, _ellipse(Vector2(0, 10), 11, 7), Color(0.62, 0.42, 0.36))
			ci.draw_circle(Vector2(-4, 9), 2.0, INK)
			ci.draw_circle(Vector2(4, 9), 2.0, INK)
			ci.draw_arc(Vector2(0, 15), 5.0, 0.2, PI - 0.2, 10, Color(1.0, 0.82, 0.25), 2.5, true)
		"cow":
			_mouth(ci, Vector2(0, 17), mood)
			_shape(ci, _ellipse(Vector2(0, 10), 10, 7), Color(1.0, 0.76, 0.76))
			ci.draw_colored_polygon(_ellipse(Vector2(-3.5, 10), 1.5, 2.2), Color(0.5, 0.25, 0.25))
			ci.draw_colored_polygon(_ellipse(Vector2(3.5, 10), 1.5, 2.2), Color(0.5, 0.25, 0.25))
		"sheep":
			_mouth(ci, Vector2(0, 13), mood, 0.8)
			ci.draw_colored_polygon(_ellipse(Vector2(0, 7.5), 3.5, 2.5), Color(0.95, 0.55, 0.6))
		_:
			_mouth(ci, Vector2(0, 16), mood)
			_shape(ci, _ellipse(Vector2(0, 9), 7, 5.5), Color(1.0, 0.76, 0.76))


## A mouth to go under a snout: open in a scream, a grin when happy, a wobble when dizzy.
static func _mouth(ci: CanvasItem, at: Vector2, mood: String, size := 1.0) -> void:
	match mood:
		"scream", "scared":
			_shape(ci, _ellipse(at + Vector2(0, 2) * size, 5.5 * size, 6.5 * size), Color(0.42, 0.06, 0.08))
			ci.draw_colored_polygon(_ellipse(at + Vector2(0, 6) * size, 3.5 * size, 2.2 * size), Color(0.95, 0.45, 0.5))
		"happy":
			ci.draw_arc(at + Vector2(0, -2) * size, 5.0 * size, 0.3, PI - 0.3, 10, OUTLINE, 2.2, true)
		"dizzy":
			var points := PackedVector2Array()
			for i in 7:
				points.append(at + Vector2(-6 + i * 2, 1.2 * (1 if i % 2 == 0 else -1)) * size)
			ci.draw_polyline(points, OUTLINE, 2.0, true)


static func _beak(ci: CanvasItem, at: Vector2, half: float, length: float, open: bool) -> void:
	if open:
		ci.draw_colored_polygon(_ellipse(at + Vector2(0, 5), half * 0.8, 4), Color(0.45, 0.08, 0.08))
		_shape(ci, PackedVector2Array([at + Vector2(-half, -1), at + Vector2(half, -1), at + Vector2(0, length * 0.7)]), BEAK)
		_shape(ci, PackedVector2Array([at + Vector2(-half * 0.8, 6), at + Vector2(half * 0.8, 6), at + Vector2(0, length + 5)]), BEAK.darkened(0.12))
	else:
		_shape(ci, PackedVector2Array([at + Vector2(-half, -2), at + Vector2(half, -2), at + Vector2(0, length)]), BEAK)


## Big cartoon eyes. mood picks the shape: "angry" (lids and brows slanted down to the middle),
## "scream"/"scared"/"panic" (wide, tiny pupils, raised brows), "happy"/"laugh" (shut arcs),
## "dizzy" (spirals), "smug" (heavy half-shut lids) or "wince" (squeezed shut).
static func _eyes(ci: CanvasItem, mood: String, skin: Color, iris: Color, pose := {}, spread := 8.0,
		y := -3.0, size := 1.0) -> void:
	var look: Vector2 = pose.get("look", Vector2.ZERO)
	var blink: float = pose.get("blink", 0.0)
	var rx := 5.4 * size
	var ry := 6.4 * size
	var wide := mood in ["scream", "scared", "panic"]
	if wide:
		rx *= 1.15
		ry *= 1.2
	for side: float in [-1.0, 1.0]:
		var c := Vector2(side * spread * size, y)
		match mood:
			"happy", "laugh":
				ci.draw_arc(c + Vector2(0, 2), rx * 0.9, PI + 0.25, TAU - 0.25, 10, OUTLINE, 2.6, true)
				continue
			"wince":
				ci.draw_polyline(PackedVector2Array([c + Vector2(-rx * side, -ry * 0.6), c + Vector2(rx * 0.7 * side, 0), c + Vector2(-rx * side, ry * 0.6)]), OUTLINE, 2.6, true)
				continue
			"dizzy":
				var spiral := PackedVector2Array()
				for i in 18:
					var a := i * 0.7 * side
					spiral.append(c + Vector2.from_angle(a) * (0.6 + i * 0.28) * size)
				ci.draw_circle(c, rx * 0.95, Color.WHITE)
				ci.draw_polyline(spiral, OUTLINE, 1.6, true)
				_outline_ellipse(ci, c, rx * 0.95, rx * 0.95)
				continue
		if blink > 0.75:
			ci.draw_line(c + Vector2(-rx, 1), c + Vector2(rx, 1), OUTLINE, 2.6, true)
			continue
		ci.draw_colored_polygon(_ellipse(c, rx, ry), Color.WHITE)
		var pupil_r := (1.9 if wide else 3.0) * size
		var p := c + Vector2(look.x * (rx - pupil_r - 0.6), look.y * (ry - pupil_r - 0.6))
		if iris != Color.WHITE:
			ci.draw_circle(p, pupil_r + 1.6 * size, iris)
		ci.draw_circle(p, pupil_r, INK)
		ci.draw_circle(p + Vector2(-1, -1) * size, pupil_r * 0.38, Color(1, 1, 1, 0.9))
		# Eyelid from the top: half-shut when smug, slanted when angry, lowered by a blink.
		var lid := blink
		if mood == "smug":
			lid = maxf(lid, 0.45)
		var top := c.y - ry - 2.0
		if mood == "angry":
			var inner := c + Vector2(-side * rx, -ry * 0.05 + lid * ry)
			var outer := c + Vector2(side * rx, -ry * 0.75 + lid * ry)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(outer.x + side * 2, top), Vector2(inner.x - side * 2, top),
				inner + Vector2(-side * 2, 0), outer + Vector2(side * 2, 0)]), skin)
			_outline_ellipse(ci, c, rx, ry)
			ci.draw_line(outer + Vector2(side * 2.5, -1.5), inner + Vector2(-side * 2.5, 0.5), INK, 3.6 * size, true)
		elif lid > 0.05:
			var edge := c.y - ry + lid * ry * 2.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - rx - 1, top), Vector2(c.x + rx + 1, top),
				Vector2(c.x + rx + 1, edge), Vector2(c.x - rx - 1, edge)]), skin)
			_outline_ellipse(ci, c, rx, ry)
			ci.draw_line(Vector2(c.x - rx, edge), Vector2(c.x + rx, edge), OUTLINE, 2.2, true)
		else:
			_outline_ellipse(ci, c, rx, ry)
		if wide:
			# Brows shot up in alarm.
			ci.draw_line(c + Vector2(-side * rx * 0.6, -ry - 4), c + Vector2(side * rx * 1.1, -ry - 1), INK, 2.6, true)


## Dark ellipse under each foot, so the round body reads as standing.
static func _feet(ci: CanvasItem, r: float, color: Color, big := false) -> void:
	var w := 6.0 if big else 5.0
	for side: float in [-1.0, 1.0]:
		_shape(ci, _ellipse(Vector2(side * 9, r - 1), w, 4.5), color)


## The sheep's woolly outline: a ring of puffs around a fluffy body.
static func _fleece(ci: CanvasItem, r: float, wool: Color) -> void:
	var puffs := 13
	for i in puffs:
		ci.draw_circle(Vector2.from_angle(TAU * i / puffs) * r * 0.86, 8.6 + LINE * 0.5, OUTLINE)
	ci.draw_circle(Vector2.ZERO, r, wool.darkened(0.12))
	for i in puffs:
		var at := Vector2.from_angle(TAU * i / puffs) * r * 0.86
		ci.draw_circle(at, 8.6, wool.darkened(0.12))
		ci.draw_circle(at + Vector2(-1.6, -2.0), 6.4, wool)
		ci.draw_circle(at + Vector2(-2.6, -3.2), 2.6, wool.lightened(0.6))
	ci.draw_circle(Vector2(-2, -2), r * 0.8, wool)


## hurt 0..1 reddens the fur and adds a plaster; growl 0..1 opens the jaw.
## show_armor false once the helmet has been knocked off.
## pose also takes mood: "smug" (default), "panic", "wince" or "laugh".
static func wolf(ci: CanvasItem, variant: String, at := Vector2.ZERO, scale := 1.0, rot := 0.0,
		hurt := 0.0, growl := 0.0, show_armor := true, flip := false, pose := {}) -> void:
	_transform(ci, at, scale, rot, flip, pose)
	var data: Dictionary = Catalog.WOLVES[variant]
	var extras: Array = data.get("extras", [])
	var base: Color = data.fur
	var fur := base.lerp(Color(0.85, 0.3, 0.3, base.a), hurt * 0.5)
	var ink := Color(OUTLINE, fur.a)
	var mood: String = pose.get("mood", "smug")
	if "glow" in extras:
		ci.draw_circle(Vector2.ZERO, 31, Color(0.6, 1.0, 0.8, 0.16))
		ci.draw_circle(Vector2.ZERO, 26, Color(0.6, 1.0, 0.8, 0.2))
	if "cape" in extras:
		_shape(ci, PackedVector2Array([Vector2(-14, 8), Vector2(14, 8), Vector2(26, 30), Vector2(-26, 30)]), Color(0.55, 0.1, 0.15))
		ci.draw_line(Vector2(-25, 29), Vector2(25, 29), Color(1.0, 0.85, 0.3), 2.0)
	# Ears, pinned back when scared.
	var droop := 6.0 if mood in ["panic", "wince"] else 0.0
	for side: float in [-1.0, 1.0]:
		_shape(ci, _mirror(PackedVector2Array([Vector2(-17, -7), Vector2(-14 - droop, -29 + droop), Vector2(-3, -16)]), side), fur.darkened(0.15), ink)
		ci.draw_colored_polygon(_mirror(PackedVector2Array([Vector2(-13.5, -11), Vector2(-12.5 - droop * 0.8, -22 + droop), Vector2(-7, -15)]), side), Color(0.88, 0.62, 0.62, fur.a))
	if "horns" in extras:
		var horn := Color(0.2, 0.15, 0.12)
		for side: float in [-1.0, 1.0]:
			_shape(ci, _mirror(PackedVector2Array([Vector2(-10, -16), Vector2(-20, -34), Vector2(-4, -19)]), side), horn)
	# Head, with a pale fur ruff on the cheeks.
	_ball(ci, Vector2.ZERO, 20, fur, ink)
	var cheek := fur.lightened(0.28)
	for side: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(_mirror(PackedVector2Array([Vector2(-19, 3), Vector2(-23, 9), Vector2(-17, 9), Vector2(-20, 14), Vector2(-12, 13), Vector2(-9, 6)]), side), cheek)
	if "scarf" in extras:
		_shape(ci, PackedVector2Array([Vector2(-17, 12), Vector2(17, 12), Vector2(14, 20), Vector2(-14, 20)]), Color(0.85, 0.15, 0.2))
		_shape(ci, PackedVector2Array([Vector2(8, 16), Vector2(15, 16), Vector2(18, 30), Vector2(11, 30)]), Color(0.75, 0.1, 0.15))
	if "tie" in extras:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 17), Vector2(6, 17), Vector2(0, 21)]), Color(0.95, 0.95, 0.95))
		_shape(ci, PackedVector2Array([Vector2(-2, 19), Vector2(2, 19), Vector2(4, 29), Vector2(0, 33), Vector2(-4, 29)]), Color(0.8, 0.1, 0.1))
	# Eyes, set in a yellow iris (green for ghosts).
	var iris := Color(0.4, 1.0, 0.8) if "glow" in extras else Color(1.0, 0.82, 0.12)
	var eye_mood := mood
	if mood == "smug" and growl > 0.4:
		eye_mood = "angry"
	_eyes(ci, eye_mood, fur, iris, pose, 7.5, -5.0, 0.95)
	if mood in ["smug", "laugh"] and not ("mask" in extras or "shades" in extras):
		# Mean brows over the lids.
		for side: float in [-1.0, 1.0]:
			ci.draw_line(Vector2(side * 13, -13), Vector2(side * 3.5, -9), Color(INK, fur.a), 3.0, true)
	# Snout and mouth.
	var snout := fur.lightened(0.3)
	var jaw := growl
	if mood == "laugh":
		jaw = maxf(jaw, 0.8)
	elif mood == "panic":
		jaw = maxf(jaw, 0.35)
	if jaw > 0.05:
		var open := 3.0 + jaw * 5.0
		_shape(ci, _ellipse(Vector2(0, 12 + open * 0.4), 7, open), Color(0.45, 0.05, 0.08), ink)
		ci.draw_colored_polygon(_ellipse(Vector2(0, 12 + open * 0.9), 4, 1.8), Color(0.9, 0.45, 0.5))
	_shape(ci, _ellipse(Vector2(0, 7), 9, 6.5), snout, ink)
	if jaw > 0.05:
		for side: float in [-1.0, 1.0]:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(side * 6, 11), Vector2(side * 3, 11), Vector2(side * 4.5, 15)]), Color.WHITE)
	elif mood == "smug":
		# A lopsided smirk with one fang showing.
		ci.draw_polyline(PackedVector2Array([Vector2(-5, 12), Vector2(1, 12.5), Vector2(6, 10)]), ink, 1.8, true)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(2.5, 12), Vector2(4.5, 11.5), Vector2(3.6, 15)]), Color.WHITE)
	else:
		ci.draw_line(Vector2(-4, 12), Vector2(4, 12), ink, 1.8, true)
	_shape(ci, _ellipse(Vector2(0, 3.5), 3.6, 2.6), Color(INK, fur.a), ink)
	ci.draw_circle(Vector2(-1, 2.6), 1.0, Color(1, 1, 1, 0.6))
	if mood == "panic":
		# A bead of sweat.
		_shape(ci, PackedVector2Array([Vector2(16, -16), Vector2(19, -10), Vector2(16, -7), Vector2(13, -10)]), Color(0.65, 0.88, 1.0), ink)
	if hurt > 0.35:
		# A sticking plaster on the forehead.
		var tan := Color(0.95, 0.78, 0.6)
		_shape(ci, _ellipse(Vector2(-7, -15), 7, 2.6, 12, -0.5), tan, ink)
		ci.draw_rect(Rect2(-9, -17, 4, 4), tan.darkened(0.1))
	if "scar" in extras:
		ci.draw_line(Vector2(-12, -15), Vector2(-4, 1), Color(0.6, 0.15, 0.15, fur.a), 1.8, true)
	if "mask" in extras:
		_shape(ci, PackedVector2Array([Vector2(-19, -10), Vector2(19, -10), Vector2(18, -1), Vector2(-18, -1)]), INK)
		ci.draw_circle(Vector2(-7, -5), 2.5, iris)
		ci.draw_circle(Vector2(7, -5), 2.5, iris)
	if "eyepatch" in extras:
		ci.draw_line(Vector2(-18, -13), Vector2(17, 0), INK, 1.6, true)
		_shape(ci, _ellipse(Vector2(7, -5), 5.5, 5.5), INK)
	if "shades" in extras:
		ci.draw_colored_polygon(_ellipse(Vector2(-7, -5), 6, 4), INK)
		ci.draw_colored_polygon(_ellipse(Vector2(7, -5), 6, 4), INK)
		ci.draw_line(Vector2(-2, -6), Vector2(2, -6), INK, 2.0)
		ci.draw_line(Vector2(-10, -7), Vector2(-7, -8), Color(1, 1, 1, 0.5), 1.5)
	# Hats
	if "bandana" in extras:
		var red := Color(0.8, 0.12, 0.12)
		_shape(ci, PackedVector2Array([Vector2(-19, -8), Vector2(-14, -17), Vector2(0, -21), Vector2(14, -17), Vector2(19, -8)]), red)
		_shape(ci, PackedVector2Array([Vector2(17, -10), Vector2(27, -14), Vector2(25, -4)]), red)
		ci.draw_circle(Vector2(-6, -15), 1.5, Color.WHITE)
		ci.draw_circle(Vector2(6, -14), 1.5, Color.WHITE)
	if "tricorn" in extras:
		var hat := Color(0.12, 0.1, 0.12)
		_shape(ci, PackedVector2Array([Vector2(-28, -14), Vector2(0, -22), Vector2(28, -14), Vector2(16, -36), Vector2(-16, -36)]), hat)
		ci.draw_line(Vector2(-27, -14.5), Vector2(27, -14.5), Color(0.9, 0.75, 0.3), 2.0)
		ci.draw_circle(Vector2(0, -27), 4, Color.WHITE)
	if "cowboy" in extras:
		var hat := Color(0.45, 0.3, 0.15)
		_shape(ci, _ellipse(Vector2(0, -15), 27, 5), hat.darkened(0.15))
		_shape(ci, PackedVector2Array([Vector2(-13, -15), Vector2(-11, -31), Vector2(0, -27), Vector2(11, -31), Vector2(13, -15)]), hat)
		ci.draw_line(Vector2(-12, -18), Vector2(12, -18), Color(0.25, 0.15, 0.08), 3.0)
	if "buckethat" in extras:
		var hat := Color(0.4, 0.55, 0.35)
		_shape(ci, PackedVector2Array([Vector2(-24, -11), Vector2(24, -11), Vector2(14, -19), Vector2(-14, -19)]), hat.darkened(0.15))
		_shape(ci, PackedVector2Array([Vector2(-14, -18), Vector2(14, -18), Vector2(11, -31), Vector2(-11, -31)]), hat)
	if "tophat" in extras:
		var hat := Color(0.1, 0.1, 0.12)
		_shape(ci, _rect(Rect2(-22, -17, 44, 5)), hat)
		_shape(ci, _rect(Rect2(-13, -42, 26, 26)), hat)
		ci.draw_rect(Rect2(-12, -22, 24, 4), Color(0.7, 0.1, 0.1))
	if "leafcrown" in extras:
		for i in 7:
			var a := PI + 0.25 + i * (PI - 0.5) / 6.0
			_shape(ci, _ellipse(Vector2.from_angle(a) * 19.0, 5, 3, 10, a), Color(0.3, 0.6, 0.2))
	if "crown" in extras:
		var gold := Color(1.0, 0.82, 0.2)
		_shape(ci, PackedVector2Array([Vector2(-14, -17), Vector2(14, -17), Vector2(16, -36), Vector2(8, -26), Vector2(0, -38), Vector2(-8, -26), Vector2(-16, -36)]), gold)
		ci.draw_circle(Vector2(0, -22), 2.5, Color(0.8, 0.1, 0.2))
	if show_armor and "hardhat" in extras:
		var yellow := Color(1.0, 0.8, 0.1)
		_shape(ci, _half_disc(Vector2(0, -12), 17), yellow)
		_shape(ci, _rect(Rect2(-22, -14, 44, 4)), yellow.darkened(0.15))
		ci.draw_line(Vector2(0, -27), Vector2(0, -14), yellow.darkened(0.25), 3.0)
	if show_armor and "knight" in extras:
		var steel := Color(0.7, 0.72, 0.78)
		_shape(ci, _half_disc(Vector2(0, -2), 22), steel)
		_shape(ci, _rect(Rect2(-21, -9, 42, 7)), steel.darkened(0.1))
		ci.draw_rect(Rect2(-15, -7, 30, 3), INK)
		_shape(ci, PackedVector2Array([Vector2(-3, -24), Vector2(3, -24), Vector2(0, -38)]), Color(0.8, 0.15, 0.15))
	_flash(ci, 20, pose)


# -- Drawing helpers ----------------------------------------------------------------------------

## Sets the canvas transform: position, rotation, the pose's squash and stretch, then scale and flip.
static func _transform(ci: CanvasItem, at: Vector2, scale: float, rot: float, flip: bool, pose: Dictionary) -> void:
	var xf := Transform2D(rot, at)
	var squash: Vector2 = pose.get("squash", Vector2.ONE)
	if squash != Vector2.ONE:
		var dir: float = pose.get("squash_dir", 0.0)
		xf = xf * Transform2D(dir, Vector2.ZERO) * Transform2D(0.0, squash, 0.0, Vector2.ZERO) * Transform2D(-dir, Vector2.ZERO)
	xf = xf * Transform2D(0.0, Vector2(-scale if flip else scale, scale), 0.0, Vector2.ZERO)
	ci.draw_set_transform_matrix(xf)


## A shaded, outlined ball: the body of most characters.
static func _ball(ci: CanvasItem, center: Vector2, r: float, color: Color, ink := OUTLINE) -> void:
	ci.draw_circle(center, r, color.darkened(0.2))
	ci.draw_circle(center + Vector2(-r, -r) * 0.09, r * 0.88, color)
	ci.draw_colored_polygon(_ellipse(center + Vector2(-r * 0.42, -r * 0.5), r * 0.32, r * 0.18, 12, -0.6), Color(color.lightened(0.55), 0.55 * color.a))
	_outline_circle(ci, center, r, ink)


static func _outline_circle(ci: CanvasItem, center: Vector2, r: float, ink := OUTLINE) -> void:
	ci.draw_arc(center, r, 0, TAU, 40, ink, LINE, true)


static func _outline_ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float) -> void:
	var points := _ellipse(center, rx, ry)
	points.append(points[0])
	ci.draw_polyline(points, OUTLINE, 1.6, true)


## A filled polygon with an inked outline.
static func _shape(ci: CanvasItem, points: PackedVector2Array, fill: Color, ink := OUTLINE) -> void:
	ci.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	ci.draw_polyline(closed, Color(ink, ink.a * fill.a), LINE * 0.8, true)


## White overlay that flashes when a character is hit.
static func _flash(ci: CanvasItem, r: float, pose: Dictionary) -> void:
	var amount: float = pose.get("flash", 0.0)
	if amount > 0.0:
		ci.draw_circle(Vector2.ZERO, r + 1.0, Color(1, 1, 1, amount * 0.8))


## The left-hand version of a symmetric shape, mirrored when side is +1.
static func _mirror(points: PackedVector2Array, side: float) -> PackedVector2Array:
	if side < 0.0:
		return points
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(-p.x, p.y))
	out.reverse()
	return out


static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


static func _ellipse(center: Vector2, rx: float, ry: float, sides := 16, rot := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return points


## The top half of a disc, flat side down.
static func _half_disc(center: Vector2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		points.append(center + Vector2.from_angle(PI + PI * i / 12.0) * r)
	return points
