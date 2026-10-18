extends Node2D
## Builds the level, feeds animals to the slingshot, and tracks win/lose.

const Animal := preload("res://scripts/animal.gd")
const Block := preload("res://scripts/block.gd")
const Wolf := preload("res://scripts/wolf.gd")
const Slingshot := preload("res://scripts/slingshot.gd")

const GROUND_Y := 640.0
const HERD := ["sheep", "cow", "goat", "sheep", "cow"]

var slingshot: Slingshot
var herd_index := 0
var wolves_left := 0
var game_over := false
var status_label: Label
var message_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.55, 0.80, 0.95))
	_build_ground()
	_build_level()
	slingshot = Slingshot.new()
	slingshot.position = Vector2(220, GROUND_Y - Slingshot.HEIGHT)
	slingshot.launched.connect(_on_launched)
	add_child(slingshot)
	_build_hud()
	_load_next_animal()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.position = Vector2(640, GROUND_Y + 100)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3200, 200)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	ground.add_child(collision)
	var grass := ColorRect.new()
	grass.color = Color(0.35, 0.65, 0.25)
	grass.size = shape.size
	grass.position = -shape.size / 2.0
	ground.add_child(grass)
	add_child(ground)


func _build_level() -> void:
	# Left hut: wooden posts and roof, a wolf inside and one on top.
	_add_block(Vector2(780, GROUND_Y - 50), Vector2(20, 100), "wood")
	_add_block(Vector2(860, GROUND_Y - 50), Vector2(20, 100), "wood")
	_add_block(Vector2(820, GROUND_Y - 110), Vector2(130, 20), "wood")
	_add_wolf(Vector2(820, GROUND_Y - Wolf.RADIUS))
	_add_wolf(Vector2(820, GROUND_Y - 120 - Wolf.RADIUS))

	# Right tower: stone base, ice floor, wooden top floor.
	_add_block(Vector2(1010, GROUND_Y - 70), Vector2(24, 140), "stone")
	_add_block(Vector2(1110, GROUND_Y - 70), Vector2(24, 140), "stone")
	_add_block(Vector2(1060, GROUND_Y - 150), Vector2(150, 20), "ice")
	_add_block(Vector2(1020, GROUND_Y - 200), Vector2(20, 80), "wood")
	_add_block(Vector2(1100, GROUND_Y - 200), Vector2(20, 80), "wood")
	_add_block(Vector2(1060, GROUND_Y - 250), Vector2(120, 20), "wood")
	_add_wolf(Vector2(1060, GROUND_Y - Wolf.RADIUS))
	_add_wolf(Vector2(1060, GROUND_Y - 160 - Wolf.RADIUS))


func _add_block(pos: Vector2, size: Vector2, kind: String) -> void:
	var block := Block.new()
	block.configure(size, kind)
	block.position = pos
	add_child(block)


func _add_wolf(pos: Vector2) -> void:
	var wolf := Wolf.new()
	wolf.position = pos
	wolf.destroyed.connect(_on_wolf_destroyed)
	add_child(wolf)
	wolves_left += 1


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	status_label = Label.new()
	status_label.position = Vector2(20, 16)
	status_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(status_label)
	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 40)
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 8)
	hud.add_child(message_label)
	_update_hud()


func _update_hud() -> void:
	status_label.text = "Animals: %d    Wolves: %d    (R to restart)" % [HERD.size() - herd_index, wolves_left]


func _load_next_animal() -> void:
	var animal := Animal.new()
	animal.kind = HERD[herd_index]
	animal.settled.connect(_on_animal_settled)
	add_child(animal)
	slingshot.load_animal(animal)


func _on_launched(_animal: Node) -> void:
	herd_index += 1
	_update_hud()


func _on_animal_settled(animal: Node) -> void:
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(animal):
		animal.queue_free()
	if game_over:
		return
	if herd_index < HERD.size():
		_load_next_animal()
		return
	# Out of animals: give falling pieces a moment to finish the job.
	await get_tree().create_timer(2.0).timeout
	if not game_over:
		game_over = true
		message_label.text = "The wolves survived!\nPress R to try again"


func _on_wolf_destroyed(_wolf: Node) -> void:
	wolves_left -= 1
	_update_hud()
	if wolves_left == 0 and not game_over:
		game_over = true
		message_label.text = "The herd wins!\nPress R to play again"
