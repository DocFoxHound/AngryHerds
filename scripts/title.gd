extends Node2D
## The start menu: pick one of three save slots to continue or start a new game, toggle
## sound, or quit. A sheep and a wolf chase each other back and forth behind it.

const Areas := preload("res://scripts/areas.gd")
const Background := preload("res://scripts/background.gd")
const Actor := preload("res://scripts/actor.gd")
const Ui := preload("res://scripts/ui.gd")
const GROUND_Y := 640.0

var chasers := []
var direction := 1.0
var center: CenterContainer
var slot_box: VBoxContainer


func _ready() -> void:
	var area: Dictionary = Areas.AREAS[0]
	RenderingServer.set_default_clear_color(area.sky[1])
	var background := Background.new()
	background.setup(area, 7)
	add_child(background)
	var ground := ColorRect.new()
	ground.color = area.grass
	ground.position = Vector2(-200, GROUND_Y)
	ground.size = Vector2(1700, 200)
	add_child(ground)
	for kind in ["wolf:wolf", "sheep", "sheep", "goat"]:
		var actor := Actor.new()
		actor.kind = kind
		actor.walking = true
		actor.scale = Vector2.ONE * 0.7
		add_child(actor)
		chasers.append(actor)
	_reset_chase()
	_build_ui()


func _reset_chase() -> void:
	# Wolves chase the herd one way, then the herd chases them back.
	for i in chasers.size():
		var actor: Node2D = chasers[i]
		var lead := i * 90.0 + (160.0 if i > 0 else 0.0)
		actor.position = Vector2(-120.0 - lead if direction > 0 else 1400.0 + lead, GROUND_Y)
		actor.face = int(direction)
		if actor.kind.begins_with("wolf"):
			actor.mood = "angry" if direction > 0 else "scared"
		else:
			actor.mood = "scared" if direction > 0 else "angry"
	if direction > 0:
		chasers.reverse()


func _process(delta: float) -> void:
	var done := true
	for actor in chasers:
		actor.position.x += direction * 170.0 * delta
		if (direction > 0 and actor.position.x < 1500.0) or (direction < 0 and actor.position.x > -220.0):
			done = false
	if done:
		direction = -direction
		_reset_chase()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Ui.make_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var title := Ui.label(96, "AngryHerds", Ui.GOLD)
	title.add_theme_constant_override("outline_size", 24)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	title.anchor_right = 1.0
	title.offset_top = 40
	root.add_child(title)
	var subtitle := Ui.label(24, "The farm animals strike back!", Color(1, 0.97, 0.9))
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 182
	root.add_child(subtitle)
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 150
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_show_slots()


func _show_slots() -> void:
	for child in center.get_children():
		child.queue_free()
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(Ui.label(28, "Choose a save", Ui.GOLD))
	for n in range(1, Game.SLOTS + 1):
		var info := Game.slot_summary(n)
		var row := Ui.row(12)
		var text := "Save %d:   Level %d   ★ %d" % [n, info.level, info.stars] if info.used else "Save %d:   Empty" % n
		var name_label := Ui.label(22, text)
		name_label.custom_minimum_size = Vector2(300, 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_label)
		var play := Ui.go_button("Play" if info.used else "New Game", _play.bind(n), Vector2(170, 52))
		play.add_theme_font_size_override("font_size", 26)
		row.add_child(play)
		var delete := Ui.button("Delete", _confirm_delete.bind(n), Vector2(110, 46))
		delete.disabled = not info.used
		row.add_child(delete)
		box.add_child(row)
	var bottom := Ui.row()
	var sound := Ui.button("Sound: On" if Game.sound_on else "Sound: Off", func() -> void: pass, Vector2(160, 46))
	sound.pressed.connect(func() -> void:
		Game.set_sound(not Game.sound_on)
		sound.text = "Sound: On" if Game.sound_on else "Sound: Off")
	bottom.add_child(sound)
	var screen := Ui.button("Fullscreen: On" if Game.fullscreen else "Fullscreen: Off", func() -> void: pass, Vector2(200, 46))
	screen.pressed.connect(func() -> void:
		Game.set_fullscreen(not Game.fullscreen)
		screen.text = "Fullscreen: On" if Game.fullscreen else "Fullscreen: Off")
	bottom.add_child(screen)
	bottom.add_child(Ui.button("Quit", func() -> void: get_tree().quit(), Vector2(120, 46)))
	box.add_child(bottom)
	box.add_child(Ui.label(15, "Progress saves automatically as you play.", Color(0.85, 0.8, 0.7)))
	center.add_child(panel)


func _play(n: int) -> void:
	Game.load_slot(n)
	Game.start()


func _confirm_delete(n: int) -> void:
	for child in center.get_children():
		child.queue_free()
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(Ui.label(28, "Delete Save %d?" % n, Color(1.0, 0.6, 0.5)))
	box.add_child(Ui.label(20, "All its stars and progress will be gone for good."))
	var row := Ui.row()
	row.add_child(Ui.button("Keep it", _show_slots))
	row.add_child(Ui.button("Delete", func() -> void:
		Game.delete_slot(n)
		_show_slots()))
	box.add_child(row)
	center.add_child(panel)
