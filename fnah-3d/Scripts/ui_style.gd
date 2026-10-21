extends RefCounted
class_name UiStyle

static func box(bg: Color, radius: int = 0, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	return s


static func label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Płaski przycisk z trzema stanami (bez ramki fokusu)
static func flat_button(b: Button, normal: Color, hover: Color, pressed: Color, margin_left: float = 0.0) -> void:
	var styles := {"normal": normal, "hover": hover, "pressed": pressed, "hover_pressed": pressed}
	for key in styles:
		var s := box(styles[key])
		if margin_left > 0.0:
			s.content_margin_left = margin_left
		b.add_theme_stylebox_override(key, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
