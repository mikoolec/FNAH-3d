extends Control
class_name PrinterSkin
## Wygląd aplikacji drukarki. Dokłada dekoracje i przestylowuje istniejące węzły
## (nazwy i ścieżki węzłów zostają - drukarkaGUI.gd i file_load_window.gd działają jak dotąd).

const PRINTER_ICON := "res://Assets/PC/Aplikacje/Ikony/printer.png"

const COL_FRAME := Color(0.667, 0.827, 0.91, 1.0)
const COL_TEXT := Color(0.10, 0.11, 0.14)
const COL_DIM := Color(0.40, 0.43, 0.50)
const COL_ACCENT := Color(0.0, 0.47, 0.84)
const COL_ZONE_BG := Color(0.965, 0.97, 0.98)
const COL_ZONE_BORDER := Color(0.62, 0.65, 0.72)
const COL_ZONE_HOVER_BG := Color(0.87, 0.94, 1.0)
const COL_ZONE_LOADED_BG := Color(0.93, 0.97, 1.0)

const MARGIN := 12.0
const HEADER_H := 78.0
const FOOTER_H := 72.0        # miejsce na przycisk "Drukuj"
const GUI_MIN_HEIGHT := 360.0

var gui: Control
var label: Label
var print_btn: Button
var pc                          # PCControl (bez typu - wołamy jego metody dynamicznie)

var _window: Control
var _file_label: Label
var _spinner: WinIcon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	gui = get_parent() as Control
	label = gui.get_node("LabelPrinterApp")
	print_btn = gui.get_node("PrintBtn")
	_window = gui.find_parent("PrinterWindow") as Control
	pc = gui.find_parent("PCControl")

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gui.custom_minimum_size = Vector2(0, GUI_MIN_HEIGHT)

	_build_header()
	_style_label_and_button()
	_style_window()
	_style_dialog()


# =========================================================================
# BUDOWA I STYLE
# =========================================================================

func _build_header() -> void:
	var icon := TextureRect.new()
	icon.texture = load(PRINTER_ICON) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(MARGIN, 14)
	icon.size = Vector2(48, 48)
	add_child(icon)

	var title := UiStyle.label("Printer", 26, COL_TEXT)
	title.position = Vector2(72, 8)
	add_child(title)

	var sub := UiStyle.label("Drukarka sieciowa", 15, COL_DIM)
	sub.position = Vector2(72, 42)
	add_child(sub)

	_file_label = UiStyle.label("", 16, COL_ACCENT)
	_file_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_file_label.visible = false
	add_child(_file_label)

	_spinner = WinIcon.new()
	_spinner.kind = WinIcon.Kind.SPINNER
	_spinner.color = COL_ACCENT
	_spinner.custom_minimum_size = Vector2(56, 56)
	_spinner.size = Vector2(56, 56)
	_spinner.visible = false
	add_child(_spinner)


func _style_label_and_button() -> void:
	# Etykieta statusu ("Upuść tu plik" / "Plik wgrany." / "Drukowanie...") - jej tekst ustawia drukarkaGUI
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.20, 0.22, 0.27))
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Przycisk "Drukuj" - szeroki, przyklejony do dołu
	print_btn.custom_minimum_size = Vector2(0, 48)
	print_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	print_btn.offset_left = MARGIN
	print_btn.offset_right = -MARGIN
	print_btn.offset_bottom = -MARGIN
	print_btn.offset_top = -MARGIN - 48.0
	print_btn.focus_mode = Control.FOCUS_NONE
	print_btn.add_theme_font_size_override("font_size", 22)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		print_btn.add_theme_color_override(c, Color.WHITE)
	var normal := UiStyle.box(COL_ACCENT, 6)
	var hover := UiStyle.box(Color(0.0, 0.40, 0.74), 6)
	var pressed := UiStyle.box(Color(0.0, 0.33, 0.62), 6)
	print_btn.add_theme_stylebox_override("normal", normal)
	print_btn.add_theme_stylebox_override("hover", hover)
	print_btn.add_theme_stylebox_override("pressed", pressed)
	print_btn.add_theme_stylebox_override("hover_pressed", pressed)
	print_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _style_window() -> void:
	if _window == null:
		return
	_window.custom_minimum_size = Vector2(540, 0)

	var ws := UiStyle.box(COL_FRAME, 0, Color(0.5, 0.53, 0.6, 0.9), 1)
	ws.shadow_size = 12
	ws.shadow_color = Color(0, 0, 0, 0.35)
	ws.shadow_offset = Vector2(0, 3)
	_window.add_theme_stylebox_override("panel", ws)

	var frame := _window.get_node_or_null("ColorRect") as ColorRect
	if frame:
		frame.color = COL_FRAME

	var bar := _window.get_node_or_null("PasekKontrolny") as HBoxContainer
	if bar == null:
		return

	# Tytuł wyrównany do lewej, ciemny
	var t := bar.get_node_or_null("Label") as Label
	if t:
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size = Vector2.ZERO
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.add_theme_font_size_override("font_size", 16)
		t.add_theme_color_override("font_color", COL_TEXT)

	# Mała ikona przed tytułem (odstęp + ikona na początek paska)
	var small := TextureRect.new()
	small.texture = load(PRINTER_ICON) as Texture2D
	small.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	small.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	small.custom_minimum_size = Vector2(20, 20)
	small.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	small.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(small)
	bar.move_child(small, 0)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	bar.add_child(spacer)
	bar.move_child(spacer, 0)

	# Przycisk X: czerwony po najechaniu
	var close_btn := bar.get_node_or_null("ClosePrinterButton") as TextureButton
	if close_btn:
		close_btn.mouse_entered.connect(func(): close_btn.modulate = Color(1.0, 0.45, 0.45))
		close_btn.mouse_exited.connect(func(): close_btn.modulate = Color.WHITE)


# Okienko postępu wgrywania/drukowania + przyciemnienie okna w trakcie
func _style_dialog() -> void:
	if _window == null:
		return
	var dlg := _window.get_node_or_null("FileLoadWindow") as PanelContainer
	if dlg:
		dlg.custom_minimum_size = Vector2(380, 0)
		var ds := UiStyle.box(Color.WHITE, 8, Color(0.8, 0.82, 0.87), 1)
		ds.set_content_margin_all(18)
		ds.shadow_size = 20
		ds.shadow_color = Color(0, 0, 0, 0.35)
		ds.shadow_offset = Vector2(0, 4)
		dlg.add_theme_stylebox_override("panel", ds)

		var vb := dlg.get_node_or_null("VBoxContainer") as VBoxContainer
		if vb:
			vb.add_theme_constant_override("separation", 12)

		var fl := dlg.get_node_or_null("VBoxContainer/FileNameLabel") as Label
		if fl:
			fl.add_theme_font_size_override("font_size", 18)
			fl.add_theme_color_override("font_color", COL_TEXT)
			fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fl.custom_minimum_size = Vector2(340, 0)

		var pb := dlg.get_node_or_null("VBoxContainer/ProgressBar") as ProgressBar
		if pb:
			pb.show_percentage = false
			pb.custom_minimum_size = Vector2(0, 14)
			pb.add_theme_stylebox_override("background", UiStyle.box(Color(0.88, 0.90, 0.93), 7))
			pb.add_theme_stylebox_override("fill", UiStyle.box(COL_ACCENT, 7))

	var blocker := _window.get_node_or_null("InputBlocker") as Control
	if blocker and dlg:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.22)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blocker.add_child(dim)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# blokada pod okienkiem postępu, żeby przyciemnienie go nie zasłaniało
		_window.move_child(blocker, dlg.get_index())


# =========================================================================
# STAN NA ŻYWO
# =========================================================================

func _zone_rect() -> Rect2:
	var bottom := FOOTER_H if (print_btn and print_btn.visible) else MARGIN
	return Rect2(
		Vector2(MARGIN, HEADER_H),
		Vector2(size.x - MARGIN * 2.0, size.y - HEADER_H - bottom)
	)


func _is_printing() -> bool:
	return label.text.begins_with("Drukowanie")


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var zone := _zone_rect()
	var center_x := zone.get_center().x

	label.position = Vector2(zone.position.x, zone.position.y + zone.size.y * 0.58)
	label.size = Vector2(zone.size.x, 34)

	_file_label.visible = gui.plikWgrany
	_file_label.text = str(gui.fileName)
	_file_label.position = label.position + Vector2(0, 38)
	_file_label.size = Vector2(zone.size.x, 24)

	_spinner.visible = _is_printing()
	_spinner.position = Vector2(center_x, zone.position.y + zone.size.y * 0.30) - _spinner.size / 2.0

	queue_redraw()


# Czy użytkownik przeciąga plik nad oknem drukarki (tam upuszczenie zadziała)
func _drag_over() -> bool:
	var vp := get_viewport()
	if not vp.gui_is_dragging():
		return false
	var data = vp.gui_get_drag_data()
	if not (data is Dictionary) or data.get("kind", -1) != DesktopIcon.Kind.FILE:
		return false
	return pc != null and pc.is_printer_drop_target(pc.pc_mouse_pos)


# =========================================================================
# RYSOWANIE
# =========================================================================

func _draw() -> void:
	draw_line(Vector2(0, HEADER_H - 6.0), Vector2(size.x, HEADER_H - 6.0), Color(0.88, 0.89, 0.92), 1.0)

	var zone := _zone_rect()
	var loaded: bool = gui.plikWgrany
	var printing := _is_printing()
	var hover := _drag_over()

	if loaded:
		draw_style_box(UiStyle.box(COL_ZONE_LOADED_BG, 10, COL_ACCENT, 2), zone)
	elif hover:
		draw_style_box(UiStyle.box(COL_ZONE_HOVER_BG, 10), zone)
		_draw_dashed_path(_rounded_rect_points(zone.grow(-1.5), 10.0), COL_ACCENT, 3.0)
	else:
		draw_style_box(UiStyle.box(COL_ZONE_BG, 10), zone)
		_draw_dashed_path(_rounded_rect_points(zone.grow(-1.0), 10.0), COL_ZONE_BORDER, 2.0)

	if not printing:
		var c := Vector2(zone.get_center().x, zone.position.y + zone.size.y * 0.30)
		var col := COL_ACCENT if (hover or loaded) else Color(0.5, 0.54, 0.62)
		_draw_document(c, 78.0 if hover else 72.0, col, loaded)


# Dokument z zagiętym rogiem; w środku strzałka w górę albo "ptaszek" (gdy plik wgrany)
func _draw_document(c: Vector2, s: float, col: Color, check: bool) -> void:
	var w := s * 0.72
	var h := s
	var f := s * 0.24
	var tl := c + Vector2(-w / 2.0, -h / 2.0)
	var pts := PackedVector2Array([
		tl, tl + Vector2(w - f, 0), tl + Vector2(w, f), tl + Vector2(w, h), tl + Vector2(0, h)
	])
	draw_colored_polygon(pts, Color.WHITE)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, col, 3.0, true)
	draw_polyline(PackedVector2Array([
		tl + Vector2(w - f, 0), tl + Vector2(w - f, f), tl + Vector2(w, f)
	]), col, 3.0, true)

	var mid := c + Vector2(0, h * 0.12)
	if check:
		draw_polyline(PackedVector2Array([
			mid + Vector2(-s * 0.17, 0), mid + Vector2(-s * 0.04, s * 0.13), mid + Vector2(s * 0.19, -s * 0.14)
		]), col, 4.0, true)
	else:
		draw_line(mid + Vector2(0, s * 0.16), mid + Vector2(0, -s * 0.16), col, 4.0, true)
		draw_polyline(PackedVector2Array([
			mid + Vector2(-s * 0.13, -s * 0.03), mid + Vector2(0, -s * 0.17), mid + Vector2(s * 0.13, -s * 0.03)
		]), col, 4.0, true)


# Zamknięta ścieżka po obrysie zaokrąglonego prostokąta (zgodnie z ruchem wskazówek zegara)
func _rounded_rect_points(r: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[r.position + Vector2(radius, radius), PI],
		[Vector2(r.end.x - radius, r.position.y + radius), 1.5 * PI],
		[Vector2(r.end.x - radius, r.end.y - radius), 0.0],
		[Vector2(r.position.x + radius, r.end.y - radius), 0.5 * PI],
	]
	for c in corners:
		for i in 7:
			var a: float = c[1] + (PI / 2.0) * i / 6.0
			pts.append(c[0] + Vector2(cos(a), sin(a)) * radius)
	pts.append(pts[0])
	return pts


# Linia przerywana po dowolnej łamanej
func _draw_dashed_path(pts: PackedVector2Array, color: Color, width: float, dash: float = 10.0, gap: float = 7.0) -> void:
	var on := true
	var remaining := dash
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len < 0.001:
			continue
		var dir := (b - a) / seg_len
		var pos := 0.0
		while pos < seg_len:
			var step := minf(remaining, seg_len - pos)
			if on:
				draw_line(a + dir * pos, a + dir * (pos + step), color, width, true)
			pos += step
			remaining -= step
			if remaining <= 0.001:
				on = not on
				remaining = dash if on else gap
