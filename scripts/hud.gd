extends CanvasLayer
## In-level screen text and menus: status line, hints, level banner, the Herd button, the boss
## health bar, the pause menu, the herd screen and the results card.

signal retry_pressed
signal next_pressed
signal map_pressed
signal skip_pressed
signal herd_changed

const Ui := preload("res://scripts/ui.gd")
const LineupPanel := preload("res://scripts/lineup_panel.gd")

var root: Control
var status_label: Label
var hint_label: Label
var banner_label: Label
var herd_button: Button
var boss_box: VBoxContainer
var boss_name: Label
var boss_bar: ProgressBar
var overlay: ColorRect
var center: CenterContainer
## Herd slots this level uses, for the herd screen.
var slots := 3


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Ui.make_theme()
	add_child(root)

	status_label = Ui.label(24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.position = Vector2(20, 14)
	root.add_child(status_label)

	herd_button = Ui.button("Herd", open_herd, Vector2(110, 44))
	herd_button.anchor_left = 1.0
	herd_button.anchor_right = 1.0
	herd_button.offset_left = -130
	herd_button.offset_right = -20
	herd_button.offset_top = 14
	herd_button.offset_bottom = 58
	root.add_child(herd_button)

	boss_box = VBoxContainer.new()
	boss_box.anchor_left = 0.5
	boss_box.anchor_right = 0.5
	boss_box.offset_left = -200
	boss_box.offset_right = 200
	boss_box.offset_top = 60
	boss_box.hide()
	boss_name = Ui.label(22, "", Color(1.0, 0.6, 0.5))
	boss_box.add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size = Vector2(400, 16)
	boss_bar.max_value = 1.0
	boss_bar.add_theme_stylebox_override("background", Ui.box(Color(0, 0, 0, 0.5), 6))
	boss_bar.add_theme_stylebox_override("fill", Ui.box(Color(0.85, 0.2, 0.2), 6))
	boss_box.add_child(boss_bar)
	root.add_child(boss_box)

	hint_label = Ui.label(20)
	_span_width(hint_label, 1.0, -48.0, -14.0)
	root.add_child(hint_label)

	banner_label = Ui.label(52, "", Ui.GOLD)
	banner_label.add_theme_constant_override("outline_size", 14)
	_span_width(banner_label, 0.25, -60.0, 60.0)
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	root.add_child(overlay)
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)


func set_status(text: String) -> void:
	status_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func show_herd_button(on: bool) -> void:
	herd_button.visible = on


func show_banner(text: String) -> void:
	banner_label.text = text
	var tween := create_tween()
	tween.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.6)
	tween.tween_property(banner_label, "modulate:a", 0.0, 0.6)


func set_boss(boss_title: String, health: float) -> void:
	boss_box.visible = boss_title != ""
	boss_name.text = boss_title
	boss_bar.value = health


func is_menu_open() -> bool:
	return overlay.visible


func hide_overlay() -> void:
	overlay.hide()


func open_herd(announce := "") -> void:
	var panel := LineupPanel.new()
	panel.slots = slots
	panel.announce = announce
	panel.closed.connect(func() -> void:
		hide_overlay()
		herd_changed.emit())
	_show_panel(panel)


func show_pause() -> void:
	var box := _open_panel()
	box.add_child(Ui.label(44, "Paused", Ui.GOLD))
	var resume := Ui.go_button("Keep Playing", hide_overlay)
	box.add_child(resume)
	var buttons := Ui.row()
	buttons.add_child(Ui.button("Map", func() -> void: map_pressed.emit()))
	buttons.add_child(Ui.button("Restart", func() -> void: retry_pressed.emit()))
	box.add_child(buttons)
	box.add_child(Ui.label(17, "Drag back from the slingshot and let go. Click mid-flight for the animal's ability.\nR restarts, Esc pauses.", Color(0.9, 0.85, 0.75)))
	resume.grab_focus.call_deferred()


## can_skip adds a Skip button (offered after losing the same level twice).
func show_results(won: bool, score: int, stars: int, best: int, new_best: bool, has_next: bool, can_skip := false) -> void:
	var box := _open_panel()
	box.add_child(Ui.label(44, "The herd wins!" if won else "The wolves survived!", Ui.GOLD if won else Color(1.0, 0.55, 0.45)))
	if won:
		var row := Ui.StarRow.new()
		box.add_child(row)
		var tween := create_tween()
		for i in stars:
			tween.tween_interval(0.35)
			tween.tween_callback(func() -> void:
				row.filled = i + 1
				row.queue_redraw()
				Sfx.play("star", 0.0, 1.0 + i * 0.15))
	box.add_child(Ui.label(30, "Score: %d" % score))
	if won:
		box.add_child(Ui.label(22, "New best!" if new_best else "Best: %d" % best, Color(0.6, 1.0, 0.6) if new_best else Color.WHITE))
	# One big green button for the obvious next step, the rest small underneath.
	var go: Button
	if won and has_next:
		go = Ui.go_button("Next Level", func() -> void: next_pressed.emit())
	elif won:
		go = Ui.go_button("Back to Map", func() -> void: map_pressed.emit())
	else:
		go = Ui.go_button("Try Again", func() -> void: retry_pressed.emit())
	box.add_child(go)
	go.grab_focus.call_deferred()
	var buttons := Ui.row()
	if has_next or not won:
		buttons.add_child(Ui.button("Map", func() -> void: map_pressed.emit()))
	if won:
		buttons.add_child(Ui.button("Play Again", func() -> void: retry_pressed.emit(), Vector2(160, 50)))
	if can_skip:
		buttons.add_child(Ui.button("Skip level", func() -> void: skip_pressed.emit(), Vector2(160, 50)))
	box.add_child(buttons)
	if can_skip:
		box.add_child(Ui.label(17, "Tricky one! Skip ahead, and come back for stars any time.", Color(0.9, 0.85, 0.75)))


## Clears the overlay and returns a fresh panel's content box.
func _open_panel() -> VBoxContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_show_panel(panel)
	return box


func _show_panel(panel: Control) -> void:
	for child in center.get_children():
		child.queue_free()
	center.add_child(panel)
	overlay.show()
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.2)


## Stretches a label across the screen at a fraction of its height.
func _span_width(l: Label, anchor_y: float, top: float, bottom: float) -> void:
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = anchor_y
	l.anchor_bottom = anchor_y
	l.offset_top = top
	l.offset_bottom = bottom
