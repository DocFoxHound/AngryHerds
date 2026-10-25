extends RigidBody2D
## A herd animal fired from the slingshot. Most kinds have an ability, triggered once by clicking
## mid-flight (see Catalog.ANIMALS): goat dash, cow pound, chicken egg bomb, duck split, pig
## blast, bull stampede. Sheep just fly.

signal settled(animal: Node)
## The duck's split spawns ducklings, which fly and settle on their own.
signal spawned(animal: Node)

const Effects := preload("res://scripts/effects.gd")
const Catalog := preload("res://scripts/catalog.gd")
const Art := preload("res://scripts/art.gd")

const RADIUS := 22.0
## The animal counts as stopped after moving slower than this for STILL_SECONDS.
const STILL_SPEED := 30.0
const STILL_SECONDS := 0.5
const MAX_FLIGHT_SECONDS := 8.0
## Once it touches the ground the animal gets rolling resistance, and its turn ends once it has
## only been trundling along (slower than SLOW_SPEED) for SLOW_SECONDS, or ROLL_SECONDS after
## landing. Blocks and wolves don't count, so it keeps its follow-through when crashing into them.
const ROLL_DAMP := 1.2
const ROLL_ANGULAR_DAMP := 4.0
const SLOW_SPEED := 160.0
const SLOW_SECONDS := 1.0
const ROLL_SECONDS := 4.0
const DASH_SPEED := 1400.0
const POUND_SPEED := 1500.0
const STAMPEDE_SPEED := 1100.0
const STAMPEDE_SECONDS := 0.8
## The pig goes off this long after its first bump if nobody clicked.
const PIG_FUSE := 1.2

var kind := "sheep"
## Waiting in line: no collisions until loaded into the slingshot.
var display_only := false
## Leaving this area counts as settled.
var bounds := Rect2(-300, -3000, 2200, 3940)
var flight_time := -1.0
var still_time := 0.0
var slow_time := 0.0
## Seconds since it first touched the ground, or -1 before then.
var landed_time := -1.0
var done := false
var ability_used := false
var size := 1.0
## Seconds left on the speed lines (goat dash, bull stampede).
var dash_time := 0.0
var stampede_time := 0.0
var pounding := false
var fuse := -1.0
var last_speed := 0.0
var mood := "angry"


func _ready() -> void:
	add_to_group("herd")
	var data: Dictionary = Catalog.ANIMALS[kind]
	size = Catalog.animal_size(kind)
	mass = data.mass
	freeze = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	# No air drag, so the flight matches the slingshot's aiming dots exactly.
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	var shape := CircleShape2D.new()
	shape.radius = RADIUS * size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.bounce = 0.2
	material.friction = 0.8
	physics_material_override = material
	set_collidable(not display_only)


func set_collidable(on: bool) -> void:
	collision_layer = 1 if on else 0
	collision_mask = 1 if on else 0


func hint() -> String:
	var data: Dictionary = Catalog.ANIMALS[kind]
	return "%s: %s" % [data.name, data.about]


func launch(velocity: Vector2) -> void:
	freeze = false
	linear_velocity = velocity
	flight_time = 0.0
	var voice: String = Catalog.ANIMALS[kind].voice
	if voice != "":
		Sfx.play(voice, -3.0)


func can_use_ability() -> bool:
	return flight_time >= 0.0 and not done and not ability_used and Catalog.ANIMALS[kind].ability != ""


func use_ability() -> void:
	ability_used = true
	var world := get_parent()
	match Catalog.ANIMALS[kind].ability:
		"split":
			var side := linear_velocity.normalized().orthogonal()
			for angle in [-0.2, 0.2]:
				var chick: RigidBody2D = get_script().new()
				chick.kind = "duckling"
				chick.bounds = bounds
				chick.position = global_position + side * signf(angle) * 30.0
				chick.add_collision_exception_with(self)
				world.add_child(chick)
				chick.launch(linear_velocity.rotated(angle))
				spawned.emit(chick)
		"dash":
			linear_velocity = linear_velocity.normalized() * maxf(linear_velocity.length() * 1.8, DASH_SPEED)
			dash_time = 0.6
		"pound":
			linear_velocity = Vector2(linear_velocity.x * 0.15, POUND_SPEED)
			angular_velocity = 0.0
			mass *= 2.0
			pounding = true
		"egg":
			var egg := Egg.new()
			egg.position = global_position + Vector2(0, RADIUS * size + 6.0)
			egg.add_collision_exception_with(self)
			world.add_child(egg)
			egg.linear_velocity = Vector2(linear_velocity.x * 0.3, 650.0)
			linear_velocity = Vector2(linear_velocity.x * 1.1, -520.0)
		"explode":
			_blast()
			return
		"stampede":
			var dir := signf(linear_velocity.x) if linear_velocity.x != 0.0 else 1.0
			linear_velocity = Vector2(dir * STAMPEDE_SPEED, 0.0)
			gravity_scale = 0.0
			mass *= 1.5
			stampede_time = STAMPEDE_SECONDS
			dash_time = STAMPEDE_SECONDS
			Sfx.play("snort")
	Effects.poof(world, global_position, Color.WHITE, 12.0)
	Sfx.play("ability")


## The pig's mud bomb. The pig is spent afterwards.
func _blast() -> void:
	ability_used = true
	fuse = -1.0
	Effects.explode(get_parent(), global_position, 150.0, 1400.0, true)
	visible = false
	set_collidable(false)
	set_deferred("freeze", true)
	if not done:
		done = true
		settled.emit(self)


func poof() -> void:
	if not visible:
		return
	Effects.poof(get_parent(), global_position, Catalog.ANIMALS[kind].color, RADIUS * size)
	Sfx.play("poof", -4.0)


## Dropped in water or lava: splash and count as done.
func sink(lava: bool) -> void:
	if done:
		return
	Effects.splash(get_parent(), global_position, lava)
	visible = false
	set_deferred("freeze", true)
	set_collidable(false)
	done = true
	settled.emit(self)


func _on_body_entered(body: Node) -> void:
	if flight_time < 0.0:
		return
	if landed_time < 0.0 and body is StaticBody2D:
		landed_time = 0.0
		linear_damp = ROLL_DAMP
		angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
		angular_damp = ROLL_ANGULAR_DAMP
	if pounding:
		pounding = false
		Effects.shake(self, 0.6)
		Effects.poof(get_parent(), global_position + Vector2(0, RADIUS), Color(0.6, 0.5, 0.35), 34.0)
		Sfx.play("stone_break")
	elif last_speed > 250.0:
		Sfx.play("thud", linear_to_db(clampf(last_speed / 1200.0, 0.2, 1.0)))
	if kind == "pig" and not ability_used and fuse < 0.0:
		fuse = PIG_FUSE
	if stampede_time > 0.0:
		Effects.shake(self, 0.3)


func _physics_process(delta: float) -> void:
	if flight_time < 0.0 or done:
		return
	flight_time += delta
	last_speed = linear_velocity.length()
	if dash_time > 0.0:
		dash_time -= delta
		queue_redraw()
	if stampede_time > 0.0:
		stampede_time -= delta
		if stampede_time <= 0.0:
			gravity_scale = 1.0
	if fuse > 0.0:
		fuse -= delta
		queue_redraw()
		if fuse <= 0.0:
			_blast()
			return
	still_time = still_time + delta if last_speed < STILL_SPEED else 0.0
	var rolling_over := false
	if fuse > 0.0:
		# A lit pig always gets to go off.
		still_time = 0.0
	elif landed_time >= 0.0:
		landed_time += delta
		slow_time = slow_time + delta if last_speed < SLOW_SPEED else 0.0
		rolling_over = slow_time > SLOW_SECONDS or landed_time > ROLL_SECONDS
	if still_time > STILL_SECONDS or rolling_over or flight_time > MAX_FLIGHT_SECONDS or not bounds.has_point(global_position):
		done = true
		settled.emit(self)


func _draw() -> void:
	if dash_time > 0.0:
		var back := (-linear_velocity.normalized()).rotated(-rotation)
		for offset: float in [-12.0, 0.0, 12.0]:
			var start := (back * RADIUS + back.orthogonal() * offset) * size
			draw_line(start, start + back * (30.0 + absf(offset)) * size, Color(1, 1, 1, clampf(dash_time / 0.6, 0.0, 1.0)), 3.0)
	Art.animal(self, kind, Vector2.ZERO, size, 0.0, mood)
	if fuse > 0.0:
		draw_set_transform(Vector2.ZERO)
		draw_circle(Vector2(0, -RADIUS * size - 8.0), 5.0, Color(1.0, 0.3 + 0.5 * absf(sin(fuse * 15.0)), 0.1))


## The chicken's egg: bursts on whatever it touches.
class Egg extends RigidBody2D:
	var burst := false

	func _ready() -> void:
		mass = 0.6
		contact_monitor = true
		max_contacts_reported = 2
		continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
		var shape := CircleShape2D.new()
		shape.radius = 9.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)
		body_entered.connect(func(_body: Node) -> void: _burst.call_deferred())
		Sfx.play("egg")

	func _process(_delta: float) -> void:
		if global_position.y > 2000.0:
			queue_free()

	func _burst() -> void:
		if burst or not is_inside_tree():
			return
		burst = true
		Effects.explode(get_parent(), global_position, 120.0, 1100.0)
		queue_free()

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(7, -7), Vector2(9, 2), Vector2(6, 9), Vector2(0, 11), Vector2(-6, 9), Vector2(-9, 2), Vector2(-7, -7)]), Color(1.0, 0.97, 0.88))
		draw_circle(Vector2(-3, -3), 2.0, Color(1, 1, 1))
