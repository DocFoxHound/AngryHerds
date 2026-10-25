extends PanelContainer
## The herd screen: choose which animals go in the lineup, in launch order. Click a slot, then
## an animal to put there. The choice is saved and carries over to every level.

signal closed

const Catalog := preload("res://scripts/catalog.gd")
const Ui := preload("res://scripts/ui.gd")

## How many slots this level uses (the rest of the saved lineup is kept but greyed out).
var slots := Catalog.LINEUP_SIZE
## Animal to welcome with a banner, or "".
var announce := ""
var selected := 0
var slot_buttons: Array[Button] = []
var slot_icons: Array = []
var info_label: Label


func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	if announce != "":
		var data: Dictionary = Catalog.ANIMALS[announce]
		box.add_child(Ui.label(34, "New friend: the %s!" % data.name, Ui.GOLD))
		box.add_child(Ui.label(20, data.about, Color(0.9, 1.0, 0.85)))
		Sfx.play("unlock")
	box.add_child(Ui.label(36 if announce == "" else 26, "Your Herd", Ui.GOLD))
	var subtitle := "They launch left to right. This level takes %d." % slots if slots < Catalog.LINEUP_SIZE else "They launch left to right. Levels use as many as they need."
	box.add_child(Ui.label(18, subtitle, Color(0.9, 0.85, 0.75)))

	var slot_row := Ui.row(10)
	for i in Catalog.LINEUP_SIZE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(76, 76)
		b.toggle_mode = true
		var icon := Ui.AnimalIcon.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(icon)
		b.pressed.connect(_select.bind(i))
		if i >= slots:
			b.disabled = true
			b.modulate.a = 0.45
		slot_row.add_child(b)
		slot_buttons.append(b)
		slot_icons.append(icon)
	box.add_child(slot_row)

	box.add_child(Ui.label(18, "Pick an animal for the highlighted slot:", Color(0.9, 0.85, 0.75)))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for kind in Catalog.LINEUP_ORDER:
		var unlocked := Game.is_animal_unlocked(kind)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 96)
		b.disabled = not unlocked
		var icon := Ui.AnimalIcon.new()
		icon.kind = kind
		icon.locked = not unlocked
		icon.position = Vector2(45, 4)
		icon.size = Vector2(60, 60)
		b.add_child(icon)
		var name_label := Ui.label(16, Catalog.ANIMALS[kind].name if unlocked else "Level %d" % Catalog.ANIMALS[kind].unlock, Ui.INK if unlocked else Color(0.8, 0.75, 0.7))
		name_label.remove_theme_constant_override("outline_size")
		name_label.add_theme_constant_override("outline_size", 0)
		name_label.position = Vector2(0, 66)
		name_label.size = Vector2(150, 24)
		b.add_child(name_label)
		b.pressed.connect(_assign.bind(kind))
		b.mouse_entered.connect(_describe.bind(kind))
		grid.add_child(b)
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	info_label = Ui.label(18, "", Color(0.95, 0.92, 0.8))
	info_label.custom_minimum_size = Vector2(620, 26)
	box.add_child(info_label)
	var buttons := Ui.row()
	buttons.add_child(Ui.button("Done", func() -> void: closed.emit()))
	box.add_child(buttons)
	_refresh()
	_describe(announce if announce != "" else Game.lineup[0])


func _select(index: int) -> void:
	selected = index
	_refresh()


func _assign(kind: String) -> void:
	Game.set_lineup_slot(selected, kind)
	Sfx.play(Catalog.ANIMALS[kind].voice, -8.0, 1.0, 200)
	selected = (selected + 1) % slots
	_refresh()


func _describe(kind: String) -> void:
	var data: Dictionary = Catalog.ANIMALS[kind]
	if Game.is_animal_unlocked(kind):
		info_label.text = "%s: %s" % [data.name, data.about]
	else:
		info_label.text = "Joins the herd at level %d." % data.unlock


func _refresh() -> void:
	var herd := Game.lineup_for(Catalog.LINEUP_SIZE)
	for i in slot_buttons.size():
		slot_buttons[i].button_pressed = i == selected
		slot_icons[i].kind = herd[i]
		slot_icons[i].queue_redraw()
