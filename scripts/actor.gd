extends Node2D
## A puppet for the story plays: a herd animal or a wolf that can walk, hop, change mood,
## growl and talk in a speech bubble.

const Art := preload("res://scripts/art.gd")
const Catalog := preload("res://scripts/catalog.gd")
const SCALE := 1.7

## An animal kind, or "wolf:<variant>".
var kind := "sheep"
var mood := "angry"
var face := 1
var walking := false
var step_phase := 0.0
var jump := 0.0
var growl := 0.0
var line := ""
var blink_left := 0.0
var blink_timer := randf_range(1.0, 4.0)


func _process(delta: float) -> void:
	if walking:
		step_phase += delta * 14.0
	jump = maxf(jump - delta * 2.5, 0.0)
	growl = maxf(growl - delta * 0.8, 0.0)
	blink_left -= delta
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink_timer = randf_range(2.0, 5.0)
		blink_left = 0.12
	queue_redraw()


func is_wolf() -> bool:
	return kind.begins_with("wolf:")


func radius() -> float:
	if is_wolf():
		return Catalog.wolf_radius(kind.trim_prefix("wolf:")) * SCALE
	return 22.0 * Catalog.animal_size(kind) * SCALE


func _draw() -> void:
	var r := radius()
	var lift := absf(sin(step_phase)) * 8.0 if walking else 0.0
	lift += sin(jump * PI) * 50.0
	var at := Vector2(0, -r - lift)
	var tilt := sin(step_phase) * 0.08 if walking else 0.0
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(Art._ellipse(Vector2(0, -2), r * 0.9, 5.0), Color(0, 0, 0, 0.2))
	var pose := {"blink": 1.0 if blink_left > 0.0 else 0.0, "look": Vector2(0.6, 0.0)}
	if is_wolf():
		var variant := kind.trim_prefix("wolf:")
		var scale := SCALE * float(Catalog.WOLVES[variant].size)
		pose.mood = "panic" if mood == "scared" else "smug"
		Art.wolf(self, variant, at, scale, tilt, 0.0, maxf(growl, 0.35 if mood == "angry" else 0.0), true, face < 0, pose)
		if mood == "scared":
			draw_set_transform(Vector2.ZERO)
			draw_circle(at + Vector2(r * 0.7, -r * 0.6), 4.0, Color(0.6, 0.85, 1.0))
	else:
		Art.animal(self, kind, at, SCALE * Catalog.animal_size(kind), tilt, mood, face < 0, pose)
	if line != "":
		_bubble(Vector2(0, -r * 2.0 - lift - 24.0))


func _bubble(tip: Vector2) -> void:
	draw_set_transform(Vector2.ZERO)
	var font := ThemeDB.fallback_font
	var width := 300.0
	var text_size := font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, width, 20)
	var box := Rect2(tip.x - text_size.x / 2.0 - 14.0, tip.y - text_size.y - 22.0, text_size.x + 28.0, text_size.y + 16.0)
	# Keep the bubble on screen.
	var screen_x := get_global_transform_with_canvas().origin.x
	var shift := clampf(screen_x + box.position.x, 10.0, 1270.0 - box.size.x) - (screen_x + box.position.x)
	box.position.x += shift
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-10, -14), tip + Vector2(10, -14), tip]), Color.WHITE)
	draw_style_box(_bubble_style(), box)
	draw_multiline_string(font, box.position + Vector2(14, 8 + font.get_ascent(20)), line, HORIZONTAL_ALIGNMENT_CENTER,
		text_size.x, 20, -1, Color(0.15, 0.1, 0.08))


func _bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(14)
	style.border_color = Color(0.2, 0.15, 0.1)
	style.set_border_width_all(2)
	return style
