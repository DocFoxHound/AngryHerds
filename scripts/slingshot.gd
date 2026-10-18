extends Node2D
## Drag the loaded animal back with the mouse and release to fire.

signal launched(animal: Node)

const MAX_PULL := 110.0
## Launch speed per pixel of pull.
const POWER := 9.0
## How close to the pouch a click must be to grab the animal.
const GRAB_RADIUS := 80.0
const MIN_PULL := 15.0
const FORK_LEFT := Vector2(-16, -6)
const FORK_RIGHT := Vector2(16, -6)
const HEIGHT := 120.0

var animal: RigidBody2D
var dragging := false
var pull := Vector2.ZERO


func load_animal(new_animal: RigidBody2D) -> void:
	animal = new_animal
	animal.global_position = global_position
	pull = Vector2.ZERO
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if animal == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_mouse_position().distance_to(global_position) < GRAB_RADIUS:
			dragging = true
		elif not event.pressed and dragging:
			dragging = false
			_release()
	elif event is InputEventMouseMotion and dragging:
		pull = (get_global_mouse_position() - global_position).limit_length(MAX_PULL)
		animal.global_position = global_position + pull
		queue_redraw()


func _release() -> void:
	if pull.length() < MIN_PULL:
		load_animal(animal)
		return
	var fired = animal
	animal = null
	fired.launch(-pull * POWER)
	pull = Vector2.ZERO
	queue_redraw()
	launched.emit(fired)


func _draw() -> void:
	var wood := Color(0.45, 0.28, 0.12)
	var band := Color(0.35, 0.15, 0.10)
	# Back band, trunk and forks
	draw_line(FORK_RIGHT, pull, band, 5.0)
	draw_line(Vector2(0, 30), Vector2(0, HEIGHT), wood, 12.0)
	draw_line(Vector2(0, 34), FORK_LEFT, wood, 9.0)
	draw_line(Vector2(0, 34), FORK_RIGHT, wood, 9.0)
	draw_line(FORK_LEFT, pull, band, 5.0)
	if dragging:
		_draw_trajectory()


func _draw_trajectory() -> void:
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var velocity := -pull * POWER
	for i in range(1, 25):
		var t := i * 0.06
		var point := pull + velocity * t + 0.5 * gravity * t * t
		draw_circle(point, 3.0, Color(1, 1, 1, 0.8 - i * 0.03))
