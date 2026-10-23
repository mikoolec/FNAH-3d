extends Control
class_name WinIcon
## Ikony rysowane kodem (nie wymagają plików ani czcionek).

enum Kind { LOGO, POWER, GEAR, SEARCH, USER, CMD, SPINNER, CHECK, UPDATE, WARNING }

@export var kind: Kind = Kind.LOGO:
	set(value):
		kind = value
		set_process(kind == Kind.SPINNER)
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	match kind:
		Kind.LOGO: _draw_logo(c, s)
		Kind.POWER: _draw_power(c, s)
		Kind.GEAR: _draw_gear(c, s)
		Kind.SEARCH: _draw_search(c, s)
		Kind.USER: _draw_user(c, s)
		Kind.CMD: _draw_cmd(c, s)
		Kind.SPINNER: _draw_spinner(c, s)
		Kind.CHECK: _draw_check_badge(c, s)
		Kind.UPDATE: _draw_update(c, s)
		Kind.WARNING: _draw_warning_badge(c, s)


func _draw_logo(c: Vector2, s: float) -> void:
	var o := c - Vector2(s, s) / 2.0
	var g := s * 0.07
	var h := (s - g) / 2.0
	draw_rect(Rect2(o, Vector2(h, h)), color)
	draw_rect(Rect2(o + Vector2(h + g, 0), Vector2(h, h)), color)
	draw_rect(Rect2(o + Vector2(0, h + g), Vector2(h, h)), color)
	draw_rect(Rect2(o + Vector2(h + g, h + g), Vector2(h, h)), color)


func _draw_power(c: Vector2, s: float) -> void:
	var r := s * 0.34
	var w := maxf(s * 0.09, 1.5)
	draw_arc(c + Vector2(0, s * 0.03), r, deg_to_rad(-55), deg_to_rad(235), 40, color, w, true)
	draw_line(c + Vector2(0, -r * 1.05), c + Vector2(0, -r * 0.1), color, w, true)


func _draw_gear(c: Vector2, s: float) -> void:
	var r := s * 0.24
	var w := maxf(s * 0.09, 1.5)
	draw_arc(c, r, 0.0, TAU, 40, color, w, true)
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		draw_line(c + dir * r, c + dir * (s * 0.42), color, s * 0.12, true)


func _draw_search(c: Vector2, s: float) -> void:
	var r := s * 0.24
	var w := maxf(s * 0.09, 1.5)
	var ctr := c + Vector2(-s * 0.08, -s * 0.08)
	draw_arc(ctr, r, 0.0, TAU, 32, color, w, true)
	draw_line(ctr + Vector2.from_angle(PI / 4.0) * r, c + Vector2(s * 0.36, s * 0.36), color, w * 1.2, true)


func _draw_user(c: Vector2, s: float) -> void:
	draw_circle(c, s * 0.5, Color(0.55, 0.58, 0.62))
	draw_circle(c + Vector2(0, -s * 0.12), s * 0.17, color)
	var base := c + Vector2(0, s * 0.38)
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI + PI * i / 24.0
		pts.append(base + Vector2(cos(a), sin(a)) * s * 0.3)
	draw_colored_polygon(pts, color)


func _draw_cmd(c: Vector2, s: float) -> void:
	var o := c - Vector2(s, s) / 2.0
	draw_rect(Rect2(o, Vector2(s, s)), Color(0.05, 0.05, 0.05))
	draw_rect(Rect2(o, Vector2(s, s)), Color(0.6, 0.6, 0.6), false, maxf(s * 0.05, 1.0))
	var w := maxf(s * 0.07, 1.5)
	draw_polyline(PackedVector2Array([
		o + Vector2(s * 0.2, s * 0.3), o + Vector2(s * 0.42, s * 0.5), o + Vector2(s * 0.2, s * 0.7)
	]), Color.WHITE, w, true)
	draw_line(o + Vector2(s * 0.5, s * 0.72), o + Vector2(s * 0.8, s * 0.72), Color.WHITE, w, true)


# Kółeczka "gonią się" po okręgu jak w Windows 10
func _draw_spinner(c: Vector2, s: float) -> void:
	var r := s * 0.42
	var dot := maxf(s * 0.06, 1.5)
	for i in 6:
		var p := fposmod(_t * 0.55 - float(i) * 0.045, 1.0)
		var e := p * p * (3.0 - 2.0 * p)
		var a := -PI / 2.0 + TAU * e
		draw_circle(c + Vector2.from_angle(a) * r, dot, color)

# Kółko z "ptaszkiem" (kolor kółka = color)
func _draw_check_badge(c: Vector2, s: float) -> void:
	draw_circle(c, s * 0.5, color)
	var w := maxf(s * 0.09, 2.0)
	draw_polyline(PackedVector2Array([
		c + Vector2(-s * 0.22, 0), c + Vector2(-s * 0.07, s * 0.16), c + Vector2(s * 0.24, -s * 0.16)
	]), Color.WHITE, w, true)

# Kółko z wykrzyknikiem
func _draw_warning_badge(c: Vector2, s: float) -> void:
	draw_circle(c, s * 0.5, color)
	var w := maxf(s * 0.1, 2.0)
	draw_line(c + Vector2(0, -s * 0.24), c + Vector2(0, s * 0.06), Color.WHITE, w, true)
	draw_circle(c + Vector2(0, s * 0.22), w * 0.6, Color.WHITE)


# Dwie strzałki w kółko (ikona Windows Update)
func _draw_update(c: Vector2, s: float) -> void:
	var r := s * 0.34
	var w := maxf(s * 0.09, 2.0)
	draw_arc(c, r, deg_to_rad(-160), deg_to_rad(-30), 24, color, w, true)
	draw_arc(c, r, deg_to_rad(20), deg_to_rad(150), 24, color, w, true)
	_arrow_head(c, r, deg_to_rad(-30), s * 0.14)
	_arrow_head(c, r, deg_to_rad(150), s * 0.14)


func _arrow_head(c: Vector2, r: float, a: float, sz: float) -> void:
	var n := Vector2(cos(a), sin(a))
	var t := Vector2(-sin(a), cos(a))
	var p := c + n * r
	draw_colored_polygon(PackedVector2Array([p + t * sz * 1.3, p + n * sz * 0.9, p - n * sz * 0.9]), color)
