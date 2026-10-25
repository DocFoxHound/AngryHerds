extends Node2D
## Drag the loaded animal back with the mouse and release to fire.

signal launched(animal: Node)

const MAX_PULL := 110.0
## Launch speed per pixel of pull.
const POWER := 10.0
## How close to the pouch a click must be to grab the animal.
const GRAB_RADIUS := 80.0
const MIN_PULL := 15.0
const FORK_LEFT := Vector2(-16, -6)
const FORK_RIGHT := Vector2(16, -6)
const HEIGHT := 120.0

var animal: RigidBody2D
var dragging := false
var pull := Vector2.ZERO
## Off once the level is over.
var enabled := true


func load_animal(new_animal: RigidBody2D) -> void:
	animal = new_animal
	animal.global_position = global_position
	pull = Vector2.ZERO
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if animal == null or not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_mouse_position().distance_to(global_position) < GRAB_RADIUS:
			dragging = true
			get_viewport().set_input_as_handled()
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
	var pull_strength := clampf(pull.length() / MAX_PULL, 0.4, 1.0)
	animal = null
	fired.launch(-pull * POWER)
	pull = Vector2.ZERO
	queue_redraw()
	Sfx.play("launch", linear_to_db(pull_strength))
	launched.emit(fired)


## Takes the loaded animal back out, e.g. to count it as a spare when the level is won.
func unload() -> RigidBody2D:
	var taken := animal
	animal = null
	dragging = false
	pull = Vector2.ZERO
	queue_redraw()
	return taken


func _draw() -> void:
	var band := Color(0.42, 0.16, 0.1)
	# Back band, trunk and forks
	_band(FORK_RIGHT, pull, band.darkened(0.2))
	_branch(Vector2(0, HEIGHT + 6), Vector2(0, 32), 13.0)
	_branch(Vector2(0, 40), FORK_LEFT + Vector2(-2, -4), 9.0)
	_branch(Vector2(0, 40), FORK_RIGHT + Vector2(2, -4), 9.0)
	# Rope binding where the branches fork.
	draw_rect(Rect2(-8, 38, 16, 14), Color(0.85, 0.75, 0.55))
	for k in 4:
		draw_line(Vector2(-8, 40 + k * 3.5), Vector2(8, 38 + k * 3.5), Color(0.6, 0.5, 0.35), 1.5)
	draw_rect(Rect2(-8, 38, 16, 14), Color(0.25, 0.15, 0.08), false, 1.5)
	_band(FORK_LEFT, pull, band)
	# Leather pouch.
	var pouch := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pouch.append(pull + Vector2(cos(a) * 11.0, sin(a) * 6.0))
	draw_colored_polygon(pouch, Color(0.4, 0.24, 0.14))
	pouch.append(pouch[0])
	draw_polyline(pouch, Color(0.18, 0.1, 0.06), 2.0, true)
	if dragging:
		_draw_trajectory()


## A rounded, shaded length of branch with a dark outline.
func _branch(from: Vector2, to: Vector2, width: float) -> void:
	var wood := Color(0.55, 0.35, 0.17)
	var side := (to - from).normalized().orthogonal()
	draw_line(from, to, Color(0.22, 0.12, 0.06), width + 4.0, true)
	draw_line(from, to, wood, width, true)
	draw_line(from - side * width * 0.25, to - side * width * 0.25, wood.lightened(0.2), width * 0.3, true)
	draw_circle(to, width / 2.0 + 2.0, Color(0.22, 0.12, 0.06))
	draw_circle(to, width / 2.0, wood)


func _band(from: Vector2, to: Vector2, color: Color) -> void:
	# Thinner the further it stretches.
	var width := lerpf(6.0, 3.5, clampf(from.distance_to(to) / (MAX_PULL + 20.0), 0.0, 1.0))
	draw_line(from, to, Color(0.15, 0.06, 0.04), width + 2.5, true)
	draw_line(from, to, color, width, true)


func _draw_trajectory() -> void:
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var velocity := -pull * POWER
	# A long dotted path, so it shows where even far shots come down.
	for i in range(1, 37):
		var t := i * 0.06
		var point := pull + velocity * t + 0.5 * gravity * t * t
		var alpha := 0.85 - i * 0.018
		draw_circle(point, 4.0, Color(0.2, 0.15, 0.1, alpha * 0.35))
		draw_circle(point, 3.0, Color(1, 1, 1, alpha))
