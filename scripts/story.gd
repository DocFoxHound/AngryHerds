extends Node2D
## Plays one story (see StoryData): a title card, then the steps acted out by puppets on the
## area's scenery. Click to hurry a line along; Skip (or Esc) jumps straight to the end.

const StoryData := preload("res://scripts/story_data.gd")
const Areas := preload("res://scripts/areas.gd")
const Background := preload("res://scripts/background.gd")
const Actor := preload("res://scripts/actor.gd")
const Debris := preload("res://scripts/debris.gd")
const Ui := preload("res://scripts/ui.gd")
const GROUND_Y := 600.0

var story: Dictionary
var actors := {}
var stage: Node2D
var camera: Camera2D
var caption: Label
var title_card: Label
var hurry := false
var finished := false
var trauma := 0.0


func _ready() -> void:
	story = StoryData.STORIES[Game.story_index]
	var area_index := mini(Game.story_index, Areas.AREAS.size() - 1)
	if Game.story_index == Game.ENDING:
		area_index = 0
	var area: Dictionary = Areas.AREAS[area_index]
	Debris.floor_at = func(_x: float) -> float: return GROUND_Y
	var background := Background.new()
	background.setup(area, 1000 + Game.story_index)
	background.position.y = GROUND_Y - Background.GROUND
	add_child(background)
	var ground := Ground.new()
	ground.area = area
	add_child(ground)
	stage = Node2D.new()
	add_child(stage)
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	camera.make_current()
	_build_ui()
	_run()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Ui.make_theme()
	layer.add_child(root)
	caption = Ui.label(28, "", Color(1.0, 0.95, 0.8))
	caption.anchor_right = 1.0
	caption.offset_top = 24
	caption.offset_bottom = 70
	root.add_child(caption)
	title_card = Ui.label(56, story.title, Ui.GOLD)
	title_card.add_theme_constant_override("outline_size", 16)
	title_card.anchor_right = 1.0
	title_card.anchor_top = 0.35
	title_card.anchor_bottom = 0.35
	title_card.offset_bottom = 80
	title_card.modulate.a = 0.0
	root.add_child(title_card)
	var skip := Ui.button("Skip", _finish, Vector2(110, 44))
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.anchor_top = 1.0
	skip.anchor_bottom = 1.0
	skip.offset_left = -130
	skip.offset_right = -20
	skip.offset_top = -64
	skip.offset_bottom = -20
	root.add_child(skip)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hurry = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_finish()
		else:
			hurry = true


func _process(delta: float) -> void:
	trauma = maxf(trauma - delta * 1.5, 0.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 20.0 * trauma * trauma


func _run() -> void:
	var tween := create_tween()
	tween.tween_property(title_card, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.4)
	tween.tween_property(title_card, "modulate:a", 0.0, 0.5)
	await tween.finished
	for step in story.steps:
		if finished:
			return
		await _do(step)
	await _pause(1.5)
	_finish()


func _do(step: Dictionary) -> void:
	if step.has("spawn"):
		var actor := Actor.new()
		actor.kind = step.as
		actor.face = step.get("face", 1)
		actor.mood = step.get("mood", "angry")
		actor.position = Vector2(step.x, GROUND_Y - step.get("y", 0.0))
		if actors.has(step.spawn) and is_instance_valid(actors[step.spawn]):
			actors[step.spawn].queue_free()
		actors[step.spawn] = actor
		stage.add_child(actor)
	elif step.has("move"):
		var actor: Node2D = actors[step.move]
		actor.walking = true
		actor.face = 1 if step.x > actor.position.x else -1
		var walk := create_tween()
		walk.tween_property(actor, "position:x", float(step.x), step.t)
		walk.tween_callback(func() -> void: actor.walking = false)
		if not step.get("go", false):
			await walk.finished
	elif step.has("say"):
		var actor: Node2D = actors[step.say]
		actor.line = step.text
		await _pause(step.get("t", 1.4 + step.text.length() / 22.0))
		actor.line = ""
	elif step.has("caption"):
		caption.text = step.caption
		await _pause(2.2)
	elif step.has("mood"):
		actors[step.mood].mood = step.to
	elif step.has("face"):
		actors[step.face].face = step.dir
	elif step.has("jump"):
		actors[step.jump].jump = 1.0
		Sfx.play("step", -6.0)
		await _pause(0.25)
	elif step.has("growl"):
		actors[step.growl].growl = 1.0
		Sfx.play("growl", -2.0)
		await _pause(0.6)
	elif step.has("sound"):
		Sfx.play(step.sound)
	elif step.has("shake"):
		trauma = minf(trauma + step.shake, 1.0)
	elif step.has("wait"):
		await _pause(step.wait)
	elif step.has("leave"):
		actors[step.leave].queue_free()
		actors.erase(step.leave)


## Waits, cut short by a click.
func _pause(seconds: float) -> void:
	hurry = false
	var left := seconds
	while left > 0.0 and not hurry and not finished and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()
	hurry = false


func _finish() -> void:
	if finished:
		return
	finished = true
	Game.story_finished()


## A flat strip of the area's ground for the actors to stand on.
class Ground extends Node2D:
	var area: Dictionary

	func _draw() -> void:
		draw_rect(Rect2(-400, GROUND_Y, 2100, 300), area.dirt)
		draw_rect(Rect2(-400, GROUND_Y, 2100, 16), area.grass)
		draw_rect(Rect2(-400, GROUND_Y + 14, 2100, 3), area.grass.darkened(0.2))
