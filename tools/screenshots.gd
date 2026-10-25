extends SceneTree
## Renders the store pictures for .slop/: a thumbnail, a trailer poster and gameplay
## screenshots. Needs a window (not --headless); --disable-vsync keeps it from stalling when
## the window is hidden:
##   godot --disable-vsync --path . --script res://tools/screenshots.gd -- <out dir>
const Autoplay := preload("res://tools/autoplay.gd")

var out := ""


func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	run.call_deferred()


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func grab() -> Image:
	await process_frame
	await process_frame
	return root.get_viewport().get_texture().get_image()


func shot(name: String) -> void:
	(await grab()).save_png(out + "/" + name + ".png")
	print("saved ", name)


func run() -> void:
	var game = root.get_node("Game")
	game.saving = false
	game.unlock_all = true

	change_scene_to_file("res://scenes/title.tscn")
	await wait_seconds(2.0)
	await shot("title")

	game.story_index = 0
	game.story_then_level = 0
	change_scene_to_file("res://scenes/story.tscn")
	await wait_seconds(10.6)
	await shot("story")

	# Aiming on the farm, with the trajectory showing; also the thumbnail and trailer poster.
	await _level(3, "sheep")
	var main = current_scene
	var sling = main.slingshot
	var target := _first_wolf(main)
	sling.dragging = true
	sling.pull = Autoplay.aim(sling.global_position, target, sling.POWER)
	sling.animal.global_position = sling.global_position + sling.pull
	sling.queue_redraw()
	main.hud.set_hint("")
	await shot("aim")
	var image := await _with_title()
	var crop_height := int(image.get_width() * 430.0 / 920.0)
	var thumb := image.get_region(Rect2i(0, image.get_height() - crop_height, image.get_width(), crop_height))
	thumb.resize(920, 430, Image.INTERPOLATE_LANCZOS)
	thumb.save_png(out + "/../thumbnail.png")
	image.save_png(out + "/trailer-poster.png")
	print("saved thumbnail and poster")

	# Abilities in action, caught just after they fire.
	for n in [33, 35, 36, 38, 40]:
		if await _action(n, "chicken", "egg", 0.45):
			break
	for n in [57, 54, 56]:
		if await _action(n, "duck", "pirates", 0.15):
			break
	await _action(100, "bull", "boss", 0.35)

	for i in game.lineup.size():
		game.lineup[i] = ["sheep", "goat", "cow", "chicken", "duck", "pig"][i]
	game.map_area = 4
	game.map_open_panel = false
	change_scene_to_file("res://scenes/map.tscn")
	await wait_seconds(1.5)
	await shot("map")
	current_scene._open_herd()
	await wait_seconds(0.5)
	await shot("herd")
	quit()


func _level(n: int, kind: String) -> void:
	var game = root.get_node("Game")
	game.current_level = n
	for i in game.lineup.size():
		game.lineup[i] = kind
	change_scene_to_file("res://scenes/main.tscn")
	await wait_seconds(2.6)


func _first_wolf(main) -> Vector2:
	if main.boss:
		return main.boss.global_position
	var wolves: Array = main.get_tree().get_nodes_in_group("wolves")
	wolves.sort_custom(func(a, b) -> bool: return a.global_position.x < b.global_position.x)
	return wolves[0].global_position


## Fires at the first wolf, uses the ability on the way, and saves a frame `after` seconds later.
## Returns whether the ability got used (the shot is only worth keeping then).
func _action(n: int, kind: String, name: String, after: float) -> bool:
	await _level(n, kind)
	var main = current_scene
	var sling = main.slingshot
	var target := _first_wolf(main)
	sling.pull = Autoplay.aim(sling.global_position, target, sling.POWER)
	sling.animal.global_position = sling.global_position + sling.pull
	sling._release()
	var flier = main.flier
	while is_instance_valid(flier) and not flier.ability_used and not flier.done:
		var now: bool = Autoplay.ability_now(flier, target)
		if kind == "chicken":
			# Bomb on the way down, so the blast lands in the picture.
			now = flier.linear_velocity.y > 0.0 and target.x - flier.global_position.x < 220.0
		if flier.can_use_ability() and now:
			main._try_ability()
		await physics_frame
	if not is_instance_valid(flier) or not flier.ability_used:
		return false
	await wait_seconds(after)
	await shot(name)
	return true


func _with_title() -> Image:
	var label := Label.new()
	label.text = "AngryHerds"
	label.position = Vector2(380, 230)
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	label.add_theme_constant_override("outline_size", 24)
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.add_child(label)
	current_scene.add_child(layer)
	var image := await grab()
	layer.queue_free()
	return image
