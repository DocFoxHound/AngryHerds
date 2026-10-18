extends "res://scripts/destructible.gd"
## The enemy. Knock every wolf out to win.

const RADIUS := 20.0


func _ready() -> void:
	max_health = 100.0
	damage_threshold = 70.0
	mass = 1.5
	super()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.friction = 0.8
	physics_material_override = material


func _draw() -> void:
	var fur := Color(0.45, 0.45, 0.50).lerp(Color(0.8, 0.3, 0.3), damage_ratio())
	# Ears
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -8), Vector2(-12, -28), Vector2(-4, -16)]), fur.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(16, -8), Vector2(12, -28), Vector2(4, -16)]), fur.darkened(0.2))
	draw_circle(Vector2.ZERO, RADIUS, fur)
	# Snout
	draw_circle(Vector2(0, 7), 8, fur.lightened(0.3))
	draw_circle(Vector2(0, 4), 3, Color.BLACK)
	# Eyes
	draw_circle(Vector2(-7, -5), 3.5, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2(7, -5), 3.5, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2(-7, -5), 1.5, Color.BLACK)
	draw_circle(Vector2(7, -5), 1.5, Color.BLACK)
