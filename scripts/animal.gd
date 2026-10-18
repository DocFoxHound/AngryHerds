extends RigidBody2D
## A herd animal fired from the slingshot.

signal settled(animal: Node)

const RADIUS := 22.0
## The animal counts as stopped after moving slower than this for STILL_SECONDS.
const STILL_SPEED := 15.0
const STILL_SECONDS := 1.0
const MAX_FLIGHT_SECONDS := 10.0

const TYPES := {
	"sheep": {"color": Color(0.95, 0.95, 0.92), "horns": false, "spots": false},
	"cow": {"color": Color(0.98, 0.96, 0.90), "horns": true, "spots": true},
	"goat": {"color": Color(0.80, 0.68, 0.50), "horns": true, "spots": false},
}

var kind := "sheep"
var flight_time := -1.0
var still_time := 0.0
var done := false


func _ready() -> void:
	mass = 3.0
	freeze = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.bounce = 0.2
	material.friction = 0.8
	physics_material_override = material


func launch(velocity: Vector2) -> void:
	freeze = false
	linear_velocity = velocity
	flight_time = 0.0


func _physics_process(delta: float) -> void:
	if flight_time < 0.0 or done:
		return
	flight_time += delta
	still_time = still_time + delta if linear_velocity.length() < STILL_SPEED else 0.0
	var off_screen := global_position.x > 1400.0 or global_position.x < -100.0 or global_position.y > 900.0
	if still_time > STILL_SECONDS or flight_time > MAX_FLIGHT_SECONDS or off_screen:
		done = true
		settled.emit(self)


func _draw() -> void:
	var data: Dictionary = TYPES[kind]
	var body: Color = data.color
	if data.horns:
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -14), Vector2(-24, -30), Vector2(-8, -18)]), Color(0.9, 0.85, 0.7))
		draw_colored_polygon(PackedVector2Array([Vector2(14, -14), Vector2(24, -30), Vector2(8, -18)]), Color(0.9, 0.85, 0.7))
	draw_circle(Vector2.ZERO, RADIUS, body)
	if data.spots:
		draw_circle(Vector2(-10, 10), 6, Color(0.2, 0.15, 0.1))
		draw_circle(Vector2(12, -12), 5, Color(0.2, 0.15, 0.1))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, body.darkened(0.35), 2.0)
	# Angry eyes and brows
	draw_circle(Vector2(-7, -3), 4, Color.WHITE)
	draw_circle(Vector2(7, -3), 4, Color.WHITE)
	draw_circle(Vector2(-6, -2), 2, Color.BLACK)
	draw_circle(Vector2(6, -2), 2, Color.BLACK)
	draw_line(Vector2(-12, -11), Vector2(-3, -7), Color.BLACK, 3.0)
	draw_line(Vector2(12, -11), Vector2(3, -7), Color.BLACK, 3.0)
	# Snout
	draw_circle(Vector2(0, 9), 6, Color(1.0, 0.75, 0.75))
