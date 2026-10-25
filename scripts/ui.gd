## Shared look for menus: the wooden theme, labels, buttons, star rows and animal icons.

const Art := preload("res://scripts/art.gd")
const GOLD := Color(1.0, 0.85, 0.2)
const INK := Color(0.2, 0.1, 0.03)


static func make_theme() -> Theme:
	var theme := Theme.new()
	var panel := box(Color(0.22, 0.14, 0.08, 0.95), 18)
	panel.border_color = Color(0.6, 0.38, 0.16)
	panel.set_border_width_all(4)
	panel.set_content_margin_all(24)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("normal", "Button", box(Color(0.85, 0.55, 0.2), 10))
	theme.set_stylebox("hover", "Button", box(Color(0.95, 0.66, 0.28), 10))
	theme.set_stylebox("pressed", "Button", box(Color(0.7, 0.42, 0.14), 10))
	theme.set_stylebox("disabled", "Button", box(Color(0.4, 0.33, 0.28), 10))
	var focus := box(Color(0, 0, 0, 0), 10)
	focus.border_color = Color(1, 0.95, 0.7)
	focus.set_border_width_all(3)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_font_size("font_size", "Button", 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(0.7, 0.65, 0.6))
	theme.set_color("font_outline_color", "Label", Color(0.12, 0.06, 0.02))
	theme.set_constant("outline_size", "Label", 8)
	return theme


static func box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(8)
	return style


static func label(font_size: int, text := "", color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, action: Callable, min_size := Vector2(140, 50)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.pressed.connect(func() -> void: Sfx.play("click", -6.0))
	b.pressed.connect(action)
	return b


static func row(separation := 16) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", separation)
	return r


## A row of stars, the first `filled` of them gold.
class StarRow extends Control:
	var count := 3
	var filled := 0
	var star_size := 26.0

	func _ready() -> void:
		custom_minimum_size = Vector2(count * star_size * 2.3, star_size * 2.1)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in count:
			var center := Vector2(star_size * (1.15 + i * 2.3), star_size * 1.05)
			var points := PackedVector2Array()
			for k in 10:
				var r := star_size if k % 2 == 0 else star_size * 0.45
				points.append(center + Vector2.from_angle(-PI / 2.0 + k * TAU / 10.0) * r)
			draw_colored_polygon(points, Color(1.0, 0.85, 0.2) if i < filled else Color(0, 0, 0, 0.35))
			points.append(points[0])
			draw_polyline(points, Color(0.35, 0.2, 0.05), 2.0)


## Draws a herd animal (or "?" for a locked one) centred in its rect.
class AnimalIcon extends Control:
	var kind := "sheep"
	var locked := false
	var mood := "angry"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var scale := minf(size.x, size.y) / 60.0
		if locked:
			draw_circle(size / 2.0, 22.0 * scale, Color(0, 0, 0, 0.35))
			var font := ThemeDB.fallback_font
			draw_string(font, size / 2.0 + Vector2(-9, 11) * scale, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(32 * scale), Color(1, 1, 1, 0.6))
			return
		Art.animal(self, kind, size / 2.0 + Vector2(0, 3) * scale, scale, 0.0, mood)
