extends Node2D
## The overworld: ten areas along a winding path. Areas not reached yet hide under clouds;
## finishing an area's boss clears the clouds off the next one and the path draws itself on.
## Click an area to walk there and pick a level. Drag (or use the arrow keys) to look around.

const Areas := preload("res://scripts/areas.gd")
const Levels := preload("res://scripts/levels.gd")
const Art := preload("res://scripts/art.gd")
const Ui := preload("res://scripts/ui.gd")
const LineupPanel := preload("res://scripts/lineup_panel.gd")
const StoryData := preload("res://scripts/story_data.gd")

const WORLD_W := 3760.0
const NODES := [Vector2(300, 520), Vector2(660, 330), Vector2(1020, 540), Vector2(1380, 300), Vector2(1740, 520),
	Vector2(2100, 300), Vector2(2460, 530), Vector2(2820, 310), Vector2(3180, 520), Vector2(3480, 290)]

var camera: Camera2D
## Highest area whose clouds are gone.
var revealed := 0
## Area whose clouds are fading during a reveal (alpha in fog_alpha), or -1.
var revealing := -1
var fog_alpha := 1.0
## How much of the path into the revealing area is drawn, 0..1.
var path_progress := 1.0
var token_area := 0
var token_pos := Vector2.ZERO
var token_walking := false
var time := 0.0
var busy := false
var dragging := false
var drag_moved := 0.0
var path_points := []
var ui_root: Control
var overlay: ColorRect
var center: CenterContainer
var stars_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.28, 0.52, 0.78))
	for i in NODES.size() - 1:
		path_points.append(_segment(i))
	revealed = 0
	for a in Areas.AREAS.size():
		if Game.is_area_unlocked(a):
			revealed = a
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	_build_ui()
	var start := clampi(Game.map_area, 0, revealed)
	if Game.reveal_area > 0 and Game.reveal_area <= revealed:
		_play_reveal(Game.reveal_area)
		Game.reveal_area = -1
	else:
		_place_token(start)
		camera.position = _camera_target(NODES[start])
		if Game.map_open_panel:
			_open_area(start)


func _place_token(area: int) -> void:
	token_area = area
	token_pos = NODES[area]


func _camera_target(at: Vector2) -> Vector2:
	return Vector2(clampf(at.x, 640.0, WORLD_W - 640.0), 360.0)


func _process(delta: float) -> void:
	time += delta
	if not dragging and not busy:
		camera.position = camera.position.lerp(_camera_target(token_pos) if token_walking else camera.position, 1.0 - exp(-delta * 4.0))
	if Input.is_action_pressed("ui_left"):
		camera.position.x -= 600.0 * delta
	if Input.is_action_pressed("ui_right"):
		camera.position.x += 600.0 * delta
	camera.position = _camera_target(camera.position)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_moved = 0.0
		else:
			dragging = false
			if drag_moved < 8.0:
				_click(get_global_mouse_position())
	elif event is InputEventMouseMotion and dragging:
		drag_moved += event.relative.length()
		camera.position.x -= event.relative.x
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/title.tscn")


func _click(at: Vector2) -> void:
	if busy:
		return
	for a in revealed + 1:
		if at.distance_to(NODES[a]) < 70.0:
			Sfx.play("click", -6.0)
			_walk_to(a)
			return


## Walks the token along the path to an area, then opens its level list.
func _walk_to(area: int) -> void:
	busy = true
	var route := []
	var step := 1 if area > token_area else -1
	var a := token_area
	while a != area:
		var seg: Array = path_points[mini(a, a + step)]
		if step < 0:
			seg = seg.duplicate()
			seg.reverse()
		route.append_array(seg)
		a += step
	token_walking = true
	for point in route:
		var tween := create_tween()
		tween.tween_property(self, "token_pos", point, 0.035)
		await tween.finished
		camera.position = camera.position.lerp(_camera_target(token_pos), 0.08)
	if route.size() > 0:
		Sfx.play("step", -8.0)
	token_walking = false
	token_area = area
	token_pos = NODES[area]
	busy = false
	_open_area(area)


func _play_reveal(area: int) -> void:
	busy = true
	revealing = area
	fog_alpha = 1.0
	path_progress = 0.0
	_place_token(area - 1)
	camera.position = _camera_target(NODES[area - 1])
	await get_tree().create_timer(0.7).timeout
	Sfx.play("reveal")
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "path_progress", 1.0, 1.6)
	tween.tween_property(self, "fog_alpha", 0.0, 1.6)
	tween.tween_property(camera, "position", _camera_target(NODES[area]), 1.6).set_trans(Tween.TRANS_SINE)
	await tween.finished
	revealing = -1
	busy = false
	_walk_to(area)


# -- Drawing ---------------------------------------------------------------------------------

func _segment(i: int) -> Array:
	# Catmull-Rom between nodes i and i+1, as points.
	var p0: Vector2 = NODES[maxi(i - 1, 0)]
	var p1: Vector2 = NODES[i]
	var p2: Vector2 = NODES[i + 1]
	var p3: Vector2 = NODES[mini(i + 2, NODES.size() - 1)]
	var points := []
	for k in range(1, 25):
		var t := k / 24.0
		var t2 := t * t
		var t3 := t2 * t
		points.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return points


func _draw() -> void:
	# Sea with gentle wave marks.
	draw_rect(Rect2(-200, -200, WORLD_W + 400, 1120), Color(0.28, 0.52, 0.78))
	for i in 80:
		var x := fmod(i * 197.0, WORLD_W)
		var y := fmod(i * 131.0, 720.0)
		draw_arc(Vector2(x + sin(time + i) * 6.0, y), 10.0, PI * 1.1, PI * 1.9, 6, Color(0.6, 0.8, 0.95, 0.5), 2.0)
	# Land: one blob per area, overlapping into a chain.
	for a in NODES.size():
		_island(a)
	# Path up to the furthest area reached.
	for i in NODES.size() - 1:
		var target := i + 1
		var amount := 1.0
		if target > revealed:
			if target != revealing:
				break
			amount = path_progress
		var seg: Array = path_points[i]
		var count := int(seg.size() * amount)
		for k in count:
			if k % 2 == 0:
				draw_circle(seg[k], 6.0, Color(0.45, 0.3, 0.15))
				draw_circle(seg[k], 4.0, Color(0.95, 0.85, 0.6))
	for a in NODES.size():
		_marker(a)
	for a in NODES.size():
		if a > revealed or a == revealing:
			_fog(a, fog_alpha if a == revealing else 1.0)
	# The herd's leader marks where you are.
	var lead: String = Game.lineup_for(1)[0]
	var hop := absf(sin(time * (12.0 if token_walking else 3.0))) * (10.0 if token_walking else 4.0)
	Art.animal(self, lead, token_pos + Vector2(0, -38 - hop), 1.1, 0.0, "happy")
	draw_set_transform(Vector2.ZERO)


func _island(a: int) -> void:
	var area: Dictionary = Areas.AREAS[a]
	var c: Vector2 = NODES[a]
	var color: Color = area.map
	draw_colored_polygon(Art._ellipse(c + Vector2(0, 14), 230, 150, 28), color.darkened(0.25))
	draw_colored_polygon(Art._ellipse(c, 225, 145, 28), color)
	var icon := c + Vector2(-110, -50)
	match area.style:
		"farm":
			draw_rect(Rect2(icon.x - 30, icon.y - 30, 60, 40), Color(0.72, 0.22, 0.18))
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-36, -28), icon + Vector2(0, -56), icon + Vector2(36, -28)]), Color(0.45, 0.2, 0.15))
			draw_rect(Rect2(icon.x - 10, icon.y - 12, 20, 22), Color(0.95, 0.92, 0.85))
		"forest":
			for k in 3:
				var p := icon + Vector2(k * 30 - 30, k % 2 * 10)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-18, 10), p + Vector2(0, -44), p + Vector2(18, 10)]), Color(0.15, 0.38, 0.18))
		"river":
			for k in 3:
				draw_arc(icon + Vector2(k * 20 - 20, k * 8), 26, PI * 1.1, PI * 1.9, 8, Color(0.2, 0.45, 0.85), 5.0)
		"canyon":
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-45, 10), icon + Vector2(-30, -40), icon + Vector2(30, -40), icon + Vector2(45, 10)]), Color(0.7, 0.35, 0.2))
		"peaks":
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-50, 10), icon + Vector2(0, -60), icon + Vector2(50, 10)]), Color(0.6, 0.65, 0.75))
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-16, -38), icon + Vector2(0, -60), icon + Vector2(16, -38)]), Color.WHITE)
		"beach":
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-40, -10), icon + Vector2(40, -10), icon + Vector2(28, 10), icon + Vector2(-28, 10)]), Color(0.45, 0.3, 0.2))
			draw_line(icon + Vector2(0, -10), icon + Vector2(0, -60), Color(0.35, 0.25, 0.15), 3.0)
			draw_rect(Rect2(icon.x, icon.y - 60, 20, 12), Color(0.1, 0.1, 0.1))
		"city":
			for k in 4:
				draw_rect(Rect2(icon.x - 40 + k * 22, icon.y - 20 - (k * 17 % 40), 18, 30 + (k * 17 % 40)), Color(0.45, 0.48, 0.55))
		"graveyard":
			for k in 3:
				var p := icon + Vector2(k * 28 - 28, 0)
				draw_rect(Rect2(p.x - 8, p.y - 18, 16, 20), Color(0.6, 0.58, 0.65))
				draw_circle(p + Vector2(0, -18), 8, Color(0.6, 0.58, 0.65))
		"volcano":
			draw_colored_polygon(PackedVector2Array([icon + Vector2(-50, 10), icon + Vector2(-12, -50), icon + Vector2(12, -50), icon + Vector2(50, 10)]), Color(0.3, 0.15, 0.12))
			draw_circle(icon + Vector2(0, -52), 10, Color(1.0, 0.45, 0.1))
		"castle":
			draw_rect(Rect2(icon.x - 40, icon.y - 30, 80, 40), Color(0.35, 0.35, 0.42))
			for k in 2:
				var tx := icon.x - 40 + k * 64
				draw_rect(Rect2(tx, icon.y - 56, 16, 66), Color(0.3, 0.3, 0.38))
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 4, icon.y - 56), Vector2(tx + 8, icon.y - 76), Vector2(tx + 20, icon.y - 56)]), Color(0.5, 0.12, 0.15))


func _marker(a: int) -> void:
	var c: Vector2 = NODES[a]
	var area: Dictionary = Areas.AREAS[a]
	var unlocked := a <= revealed
	var stars := Game.area_stars(a)
	var ring := Ui.GOLD if stars >= 30 else Color(0.95, 0.9, 0.8)
	draw_circle(c, 30, Color(0.25, 0.15, 0.08))
	draw_circle(c, 26, ring if unlocked else Color(0.5, 0.5, 0.5))
	var font := ThemeDB.fallback_font
	var number := str(a + 1)
	var w := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(font, c + Vector2(-w / 2.0, 10), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.25, 0.15, 0.08))
	if unlocked:
		var text := "%s   %d/30 ★" % [area.name, stars]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string_outline(font, c + Vector2(-tw / 2.0, 62), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0.15, 0.08, 0.02))
		draw_string(font, c + Vector2(-tw / 2.0, 62), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)


func _fog(a: int, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var c: Vector2 = NODES[a]
	for k in 9:
		var offset := Vector2(cos(k * 2.3) * 140.0, sin(k * 1.7) * 80.0)
		draw_circle(c + offset, 90.0 + (k % 3) * 20.0, Color(0.9, 0.92, 0.96, alpha * 0.85))
	draw_circle(c, 120.0, Color(1, 1, 1, alpha * 0.9))
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-12, 18), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0.5, 0.55, 0.65, alpha))


# -- Menus -----------------------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = Ui.make_theme()
	layer.add_child(ui_root)
	stars_label = Ui.label(28, "★ %d / %d" % [Game.total_stars(), Levels.COUNT * 3], Ui.GOLD)
	stars_label.position = Vector2(20, 14)
	ui_root.add_child(stars_label)
	var buttons := Ui.row(10)
	buttons.anchor_left = 1.0
	buttons.anchor_right = 1.0
	buttons.offset_left = -300
	buttons.offset_right = -20
	buttons.offset_top = 14
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(Ui.button("Herd", _open_herd, Vector2(110, 44)))
	buttons.add_child(Ui.button("Menu", func() -> void: get_tree().change_scene_to_file("res://scenes/title.tscn"), Vector2(110, 44)))
	ui_root.add_child(buttons)
	var help := Ui.label(17, "Click an area to travel there. Drag or use the arrow keys to look around.", Color(0.95, 0.95, 1.0))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.anchor_right = 1.0
	help.offset_top = -36
	ui_root.add_child(help)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	ui_root.add_child(overlay)
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)


func _show_panel(panel: Control) -> void:
	for child in center.get_children():
		child.queue_free()
	center.add_child(panel)
	overlay.show()


func _open_herd() -> void:
	var panel := LineupPanel.new()
	panel.closed.connect(func() -> void: overlay.hide())
	_show_panel(panel)


## The area's ten levels.
func _open_area(a: int) -> void:
	Game.map_area = a
	var area: Dictionary = Areas.AREAS[a]
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(Ui.label(38, "%d. %s" % [a + 1, area.name], Ui.GOLD))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	for i in Levels.PER_AREA:
		var level := a * Levels.PER_AREA + i + 1
		var cell := VBoxContainer.new()
		var unlocked := Game.is_unlocked(level)
		var text := Levels.label(level)
		if i == Levels.PER_AREA - 1:
			text += "\nBOSS"
		var b := Ui.button(text if unlocked else "Locked", func() -> void: Game.play_level(level), Vector2(118, 64))
		b.disabled = not unlocked
		cell.add_child(b)
		var stars := Ui.StarRow.new()
		stars.star_size = 10.0
		stars.filled = Game.stars_for(level)
		cell.add_child(stars)
		grid.add_child(cell)
	box.add_child(grid)
	var buttons := Ui.row()
	if a in Game.seen_stories:
		buttons.add_child(Ui.button("Story", func() -> void: Game.play_story(a)))
	buttons.add_child(Ui.button("Herd", _open_herd))
	var close := Ui.button("Close", func() -> void: overlay.hide())
	buttons.add_child(close)
	box.add_child(buttons)
	_show_panel(panel)
