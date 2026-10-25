extends Node2D
## A score number that pops in, floats up and fades.

const LIFE := 1.2

var text := ""
var color := Color.WHITE
var font_size := 24
var age := 0.0


func _ready() -> void:
	z_index = 20


func _process(delta: float) -> void:
	age += delta
	position.y -= 45.0 * delta
	if age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var alpha := clampf((LIFE - age) / 0.4, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (1.0 + 0.5 * maxf(0.0, 1.0 - age * 8.0)))
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(-width / 2.0, 0.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 7, Color(0.15, 0.08, 0.02, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))
