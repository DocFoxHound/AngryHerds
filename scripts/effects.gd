## Spawns the visual side of destruction: splintering blocks, cartoon poofs, score popups,
## screen shake, and freeze frames and slow motion for big hits. All static: Effects.poof(world, ...).

const Debris := preload("res://scripts/debris.gd")
const Poof := preload("res://scripts/poof.gd")
const PopupText := preload("res://scripts/popup_text.gd")


## Bumped each time the game speed changes, so an older restore doesn't undo a newer change.
static var _time_token := 0


static func shake(node: Node, amount: float) -> void:
	node.get_tree().call_group("camera_shake", "shake", amount)


## A split-second freeze frame that sells a big hit. Skipped during slow motion.
static func hitstop(node: Node, seconds := 0.06) -> void:
	if Engine.time_scale < 1.0:
		return
	_set_speed(node, 0.05, seconds)


## Slows the game down for a dramatic moment (the last wolf), for `seconds` of real time.
static func slow_motion(node: Node, speed := 0.3, seconds := 0.9) -> void:
	_set_speed(node, speed, seconds)


static func _set_speed(node: Node, speed: float, seconds: float) -> void:
	_time_token += 1
	var token := _time_token
	Engine.time_scale = speed
	await node.get_tree().create_timer(seconds, true, false, true).timeout
	if token == _time_token:
		Engine.time_scale = 1.0


## Back to normal speed at once, e.g. when a level starts.
static func reset_speed() -> void:
	_time_token += 1
	Engine.time_scale = 1.0


## A kick of dust and grass where something lands hard. amount about 0..1.
static func dust(world: Node, pos: Vector2, amount: float) -> void:
	amount = clampf(amount, 0.2, 1.0)
	var debris := _debris(world)
	for i in int(6 + amount * 10):
		var side := -1.0 if i % 2 == 0 else 1.0
		var vel := Vector2(side * randf_range(60, 260), randf_range(-200, -60)) * (0.6 + amount)
		debris.add_piece(pos + Vector2(randf_range(-10, 10), 0), vel, _blob(randf_range(4, 9) * (0.6 + amount * 0.6), 7, 0.3),
			Color(0.82, 0.74, 0.6, 0.75), randf_range(0.5, 0.9), 0.0, 0.0, 0.15, 3.5)
	for i in int(3 + amount * 5):
		var vel := Vector2(randf_range(-160, 160), randf_range(-320, -140))
		debris.add_piece(pos, vel, _sliver(randf_range(5, 9), 2.0), Color(0.36, 0.62, 0.26), randf_range(0.6, 1.0), randf() * TAU, randf_range(-12, 12))


static func popup(world: Node, pos: Vector2, text: String, color: Color, font_size := 24) -> void:
	var label := PopupText.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.position = pos
	world.add_child(label)


## A cloud puff plus tufts of fur or wool flying off.
static func poof(world: Node, pos: Vector2, color: Color, radius: float, dizzy := false) -> void:
	var cloud := Poof.new()
	cloud.color = color.lerp(Color.WHITE, 0.55)
	cloud.radius = radius
	cloud.dizzy = dizzy
	cloud.position = pos
	world.add_child(cloud)
	var debris := _debris(world)
	for i in 12:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(150.0, 380.0) + Vector2(0, -100)
		debris.add_piece(pos + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * radius, vel,
			_blob(randf_range(2.5, 5.5), 6, 0.5), color.darkened(randf_range(0.0, 0.25)),
			randf_range(0.6, 1.2), 0.0, randf_range(-6, 6), 0.3, 2.5)


## A blast that damages and shoves everything breakable nearby: the chicken's egg, the pig.
static func explode(world: Node, pos: Vector2, radius: float, power: float, mud := false) -> void:
	for body in world.get_tree().get_nodes_in_group("destructible"):
		var offset: Vector2 = body.global_position - pos
		var dist := offset.length()
		if dist > radius:
			continue
		var falloff := 1.0 - dist / radius
		body.apply_central_impulse(offset.normalized() * power * falloff * 0.6)
		body.take_damage(power * falloff)
	var flash := Poof.new()
	flash.color = Color(0.55, 0.38, 0.22) if mud else Color(1.0, 0.65, 0.2)
	flash.radius = radius * 0.45
	flash.position = pos
	world.add_child(flash)
	var smoke := Poof.new()
	smoke.color = Color(0.45, 0.3, 0.2) if mud else Color(0.4, 0.38, 0.36)
	smoke.radius = radius * 0.3
	smoke.position = pos + Vector2(0, -10)
	world.add_child(smoke)
	var debris := _debris(world)
	var blob := Color(0.45, 0.3, 0.18) if mud else Color(1.0, 0.75, 0.25)
	for i in 18:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(250, 600) + Vector2(0, -150)
		debris.add_piece(pos, vel, _blob(randf_range(3, 7), 7, 0.4), blob.darkened(randf_range(0, 0.3)), randf_range(0.6, 1.2))
	shake(world, 0.7)
	Sfx.play("boom")


static func splash(world: Node, pos: Vector2, lava: bool) -> void:
	var debris := _debris(world)
	var drop := Color(1.0, 0.55, 0.15) if lava else Color(0.75, 0.9, 1.0, 0.9)
	for i in 14:
		var vel := Vector2(randf_range(-120, 120), randf_range(-420, -180))
		debris.add_piece(pos, vel, _blob(randf_range(2.5, 5), 6, 0.3), drop, randf_range(0.5, 0.9))
	if lava:
		var smoke := Poof.new()
		smoke.color = Color(0.35, 0.3, 0.3)
		smoke.radius = 18.0
		smoke.position = pos
		world.add_child(smoke)
	Sfx.play("sizzle" if lava else "splash")


## Breaks a block into pieces of its material, flying out from where it was.
static func shatter(world: Node, pos: Vector2, rot: float, size: Vector2, color: Color, kind: String,
		velocity: Vector2) -> void:
	var debris := _debris(world)
	var length := maxf(size.x, size.y)
	var thick := minf(size.x, size.y)
	# Unit vector along the block's long side, in world space.
	var axis := Vector2.RIGHT.rotated(rot) if size.x >= size.y else Vector2.DOWN.rotated(rot)
	var inherit := velocity * 0.4
	match kind:
		"wood":
			# Planks snapping into jagged lengths, then slivers and sawdust.
			var count := clampi(int(length / 24.0), 2, 6)
			var seg := length / count
			for i in count:
				var offset := -length / 2.0 + seg * (i + 0.5)
				var vel := inherit + Vector2(randf_range(-150, 150), randf_range(-330, -90)) + axis * offset * 2.5
				debris.add_piece(pos + axis * offset, vel, _plank(seg, thick),
					color.darkened(randf_range(0.0, 0.2)), randf_range(1.6, 2.4), axis.angle(), randf_range(-9, 9))
			for i in 8 + count * 2:
				var at := pos + axis * randf_range(-0.5, 0.5) * length
				var vel := inherit + Vector2.from_angle(randf() * TAU) * randf_range(200, 520) + Vector2(0, -150)
				debris.add_piece(at, vel, _sliver(randf_range(8, 18), randf_range(2, 3.5)),
					color.lightened(randf_range(-0.2, 0.25)), randf_range(0.9, 1.6), randf() * TAU, randf_range(-20, 20))
			for i in 14:
				var vel := inherit * 0.5 + Vector2.from_angle(randf() * TAU) * randf_range(60, 220)
				debris.add_piece(pos + axis * randf_range(-0.5, 0.5) * length, vel, _blob(randf_range(1.5, 2.5), 4, 0.2),
					color.lightened(0.3), randf_range(0.5, 0.9), 0.0, 0.0, 0.25, 3.0)
		"stone":
			var chunks := clampi(int(size.x * size.y / 600.0), 4, 12)
			for i in chunks:
				var at := pos + axis * randf_range(-0.45, 0.45) * length
				var vel := inherit + Vector2(randf_range(-170, 170), randf_range(-280, -60))
				debris.add_piece(at, vel, _blob(thick * randf_range(0.3, 0.5), 7, 0.45),
					color.darkened(randf_range(-0.1, 0.25)), randf_range(1.6, 2.4), randf() * TAU, randf_range(-6, 6))
			var dust := Poof.new()
			dust.color = Color(0.75, 0.72, 0.68)
			dust.radius = clampf(length * 0.25, 16.0, 40.0)
			dust.position = pos
			world.add_child(dust)
		"ice":
			var shards := clampi(int(size.x * size.y / 250.0), 8, 22)
			for i in shards:
				var at := pos + axis * randf_range(-0.5, 0.5) * length
				var vel := inherit + Vector2.from_angle(randf() * TAU) * randf_range(150, 480) + Vector2(0, -140)
				var tint := color.lightened(randf_range(0.0, 0.4))
				tint.a = randf_range(0.6, 0.95)
				debris.add_piece(at, vel, _shard(randf_range(4, 10)), tint, randf_range(0.8, 1.3), randf() * TAU, randf_range(-14, 14))
			for i in 8:
				var vel := Vector2.from_angle(randf() * TAU) * randf_range(40, 160)
				debris.add_piece(pos + axis * randf_range(-0.5, 0.5) * length, vel, _sliver(7, 7),
					Color(1, 1, 1, 0.9), randf_range(0.4, 0.7), PI / 4.0, 0.0, 0.0, 2.0)


static func _debris(world: Node) -> Debris:
	var debris := Debris.new()
	world.add_child(debris)
	return debris


## A length of plank with splintered, jagged ends. X runs along the plank.
static func _plank(length: float, thick: float) -> PackedVector2Array:
	var h := length / 2.0
	var t := thick / 2.0
	return PackedVector2Array([
		Vector2(-h + randf_range(-3, 3), -t), Vector2(h + randf_range(-3, 3), -t),
		Vector2(h + randf_range(2, 7), randf_range(-t, t) * 0.5),
		Vector2(h + randf_range(-3, 3), t), Vector2(-h + randf_range(-3, 3), t),
		Vector2(-h - randf_range(2, 7), randf_range(-t, t) * 0.5),
	])


static func _sliver(length: float, width: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-length / 2.0, 0), Vector2(0, -width / 2.0), Vector2(length / 2.0, 0), Vector2(0, width / 2.0)])


static func _shard(size: float) -> PackedVector2Array:
	var start := randf() * TAU
	return PackedVector2Array([
		Vector2.from_angle(start) * size,
		Vector2.from_angle(start + randf_range(1.6, 2.6)) * size * randf_range(0.3, 0.7),
		Vector2.from_angle(start + randf_range(3.4, 4.6)) * size * randf_range(0.3, 0.7),
	])


## A lumpy round shape: roughness 0 is a regular polygon.
static func _blob(radius: float, sides: int, roughness: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		points.append(Vector2.from_angle(TAU * i / sides) * radius * randf_range(1.0 - roughness, 1.0))
	return points
