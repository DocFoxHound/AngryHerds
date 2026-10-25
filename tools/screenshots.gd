extends SceneTree
## Renders the store pictures for .slop/: a thumbnail and gameplay screenshots. Needs a window
## (not --headless):
##   godot --path . --script res://tools/screenshots.gd -- <out dir>
const PULL := Vector2(-100, 45)

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
	change_scene_to_file("res://scenes/main.tscn")
	await wait_seconds(1.0)
	var slingshot = current_scene.slingshot

	# Aiming, with the trajectory showing.
	slingshot.dragging = true
	slingshot.pull = PULL
	slingshot.animal.global_position = slingshot.global_position + PULL
	slingshot.queue_redraw()
	await shot("aim")

	# The thumbnail: the aiming shot with a title, cropped to the store's 920x430.
	var title := _title()
	var image := await grab()
	title.queue_free()
	var crop_height := int(image.get_width() * 430.0 / 920.0)
	image = image.get_region(Rect2i(0, image.get_height() - crop_height, image.get_width(), crop_height))
	image.resize(920, 430, Image.INTERPOLATE_LANCZOS)
	image.save_png(out + "/thumbnail.png")
	print("saved thumbnail")

	slingshot.dragging = false
	slingshot._release()
	await wait_seconds(0.45)
	await shot("flight")
	await wait_seconds(0.5)
	await shot("impact")
	await wait_seconds(2.5)
	await shot("aftermath")
	quit()


func _title() -> CanvasLayer:
	var label := Label.new()
	label.text = "AngryHerds"
	label.position = Vector2(380, 230)
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	label.add_theme_constant_override("outline_size", 24)
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.add_child(label)
	current_scene.add_child(layer)
	return layer
