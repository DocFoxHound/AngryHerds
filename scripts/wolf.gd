extends "res://scripts/destructible.gd"
## The enemy, in many variants (see Catalog.WOLVES). Knock every wolf out to win. A direct hit
## from a herd animal hurts far more than being bumped by blocks. Wolves growl now and then.

const Catalog := preload("res://scripts/catalog.gd")
const Art := preload("res://scripts/art.gd")

## Direct hits: damage per unit of the animal's mass times its speed above DIRECT_MIN_SPEED.
const DIRECT_DAMAGE := 0.5
const DIRECT_MIN_SPEED := 60.0

var variant := "wolf"
var size := 1.0
var armor := 0.0
var is_boss := false
## 0..1, how far the jaw is open; decays after a growl or laugh.
var growl := 0.0
var growl_timer := 0.0


func _ready() -> void:
	var data: Dictionary = Catalog.WOLVES[variant]
	size = data.size
	max_health = data.health
	armor = data.get("armor", 0.0)
	is_boss = data.get("boss", false)
	damage_threshold = 70.0 * size
	mass = 1.5 * size * size
	points = data.points
	super()
	add_to_group("wolves")
	var shape := CircleShape2D.new()
	shape.radius = Catalog.wolf_radius(variant)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var material := PhysicsMaterial.new()
	material.friction = 0.8
	physics_material_override = material
	body_entered.connect(_on_body_entered)
	growl_timer = randf_range(2.0, 9.0)


func _physics_process(delta: float) -> void:
	super(delta)
	growl_timer -= delta
	if growl_timer <= 0.0:
		growl_timer = randf_range(5.0, 12.0)
		snarl()
	if growl > 0.0:
		growl = maxf(growl - delta * 1.2, 0.0)
		queue_redraw()


## Bares its teeth with a growl (bosses roar).
func snarl() -> void:
	growl = 1.0
	queue_redraw()
	if is_boss:
		Sfx.play("roar", -2.0, 1.0, 1500)
	else:
		Sfx.play("growl", -9.0, 1.15 / size, 1200)


func laugh() -> void:
	growl = 1.0
	growl_timer = randf_range(4.0, 9.0)
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if grace > 0.0 or not body.is_in_group("herd"):
		return
	var speed: float = body.last_speed
	if speed > DIRECT_MIN_SPEED:
		take_damage((speed - DIRECT_MIN_SPEED) * body.mass * DIRECT_DAMAGE)


func take_damage(amount: float) -> void:
	if armor > 0.0 and health > 0.0:
		armor -= amount
		Sfx.play("clang", -4.0)
		if armor > 0.0:
			return
		# The helmet flies off; whatever the hit had left goes through.
		amount = -armor
		armor = 0.0
		Effects.popup(get_parent(), global_position + Vector2(0, -30 * size), "Clang!", Color(0.9, 0.9, 1.0), 22)
		queue_redraw()
	super(amount)


func _break() -> void:
	var data: Dictionary = Catalog.WOLVES[variant]
	Effects.poof(get_parent(), global_position, data.fur, 30.0 * size, true)
	Sfx.play("roar" if is_boss else "wolf")
	Sfx.play("poof")


func _draw() -> void:
	Art.wolf(self, variant, Vector2.ZERO, size, 0.0, damage_ratio(), growl, armor > 0.0)
	draw_set_transform(Vector2.ZERO)
	# Tough wolves show how hurt they are.
	if max_health >= 200.0 and not is_boss and damage_ratio() > 0.0:
		var width := 40.0 * size
		var bar := Rect2(-width / 2.0, -34.0 * size, width, 5.0)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bar.position, Vector2(width * (1.0 - damage_ratio()), 5.0)), Color(0.9, 0.25, 0.2))
