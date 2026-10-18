extends "res://scripts/destructible.gd"
## A building block made of wood, stone or ice.

const KINDS := {
	"wood": {"color": Color(0.76, 0.53, 0.30), "health": 300.0, "density": 1.0},
	"stone": {"color": Color(0.55, 0.56, 0.60), "health": 900.0, "density": 2.5},
	"ice": {"color": Color(0.70, 0.90, 1.00, 0.85), "health": 120.0, "density": 0.8},
}

var size := Vector2(20, 100)
var color := Color.WHITE


func configure(p_size: Vector2, kind: String) -> void:
	var data: Dictionary = KINDS[kind]
	size = p_size
	color = data.color
	max_health = data.health
	damage_threshold = 150.0
	mass = data.density * size.x * size.y / 1000.0


func _ready() -> void:
	super()
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.friction = 0.9
	physics_material_override = material


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, color.darkened(damage_ratio() * 0.5))
	draw_rect(rect, color.darkened(0.4), false, 2.0)
	# Cracks appear as the block takes damage.
	if damage_ratio() > 0.3:
		draw_line(-size / 4.0, size / 5.0, color.darkened(0.6), 2.0)
	if damage_ratio() > 0.6:
		draw_line(Vector2(size.x / 4.0, -size.y / 3.0), Vector2(-size.x / 5.0, size.y / 4.0), color.darkened(0.6), 2.0)
