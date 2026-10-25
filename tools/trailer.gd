extends SceneTree
## Plays a short trailer for the store: the title, the opening story, a shot with each animal's
## ability in a different area, a boss, and the map. Record it with Godot's movie writer:
##   godot --path . --fixed-fps 30 --write-movie export/trailer.avi --script res://tools/trailer.gd
const Autoplay := preload("res://tools/autoplay.gd")

## Level, first animal, caption.
const SHOTS := [
	[3, "sheep", "Fling the herd at the wolves' hideouts"],
	[14, "goat", "Goats charge"],
	[24, "cow", "Cows slam down"],
	[36, "chicken", "Chickens drop egg bombs"],
	[57, "duck", "Ducks split into three"],
	[74, "pig", "Pigs go off like mud bombs"],
	[100, "bull", "Stampede the Wolf King!"],
]


func _initialize() -> void:
	run.call_deferred()


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func caption(text: String, font_size := 40) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_constant_override("outline_size", 14)
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
	label.anchor_right = 1.0
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = -120
	label.offset_bottom = -60
	layer.add_child(label)
	current_scene.add_child(layer)


func run() -> void:
	var game = root.get_node("Game")
	game.saving = false
	game.unlock_all = true
	game.seen_stories = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	change_scene_to_file("res://scenes/title.tscn")
	await wait_seconds(3.0)

	game.story_index = 0
	game.story_then_level = 0
	change_scene_to_file("res://scenes/story.tscn")
	await wait_seconds(12.5)

	for shot in SHOTS:
		game.current_level = shot[0]
		for i in game.lineup.size():
			game.lineup[i] = shot[1]
		change_scene_to_file("res://scenes/main.tscn")
		await wait_seconds(1.6)
		var main = current_scene
		caption(shot[2])
		await _fire(main)
		await wait_seconds(1.2)

	game.reveal_area = 5
	change_scene_to_file("res://scenes/map.tscn")
	await wait_seconds(4.5)

	change_scene_to_file("res://scenes/title.tscn")
	await wait_seconds(0.2)
	current_scene.center.hide()
	caption("100 levels. 10 lands. 7 angry animals.", 44)
	await wait_seconds(3.5)
	quit()


## Aims at the nearest wolf and uses the ability on the way, like the autoplay bot.
func _fire(main) -> void:
	var sling = main.slingshot
	while sling.animal == null or main.loading:
		await physics_frame
	var wolves: Array = main.get_tree().get_nodes_in_group("wolves")
	wolves.sort_custom(func(a, b) -> bool: return a.global_position.x < b.global_position.x)
	var target: Vector2 = wolves[0].global_position
	if main.boss:
		target = main.boss.global_position
	sling.dragging = true
	var pull: Vector2 = Autoplay.aim(sling.global_position, target, sling.POWER)
	# Draw the pull back on screen, with the aiming dots.
	for k in 20:
		sling.pull = pull * (k + 1) / 20.0
		sling.animal.global_position = sling.global_position + sling.pull
		sling.queue_redraw()
		await process_frame
	await wait_seconds(0.4)
	sling.dragging = false
	sling._release()
	var flier = main.flier
	var t := 0.0
	while is_instance_valid(flier) and not flier.done and t < 4.0:
		if flier.can_use_ability() and Autoplay.ability_now(flier, target):
			main._try_ability()
		await physics_frame
		t += 1.0 / 120.0
