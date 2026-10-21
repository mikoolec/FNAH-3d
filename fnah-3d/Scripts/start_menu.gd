extends Control
class_name StartMenu

signal app_chosen(app_id: StringName)
signal settings_pressed
signal power_action(action: StringName)   # &"sleep" / &"shutdown" / &"restart"
signal closed

const MENU_SIZE := Vector2(400, 560)
const RAIL_W := 56.0
const ROW_H := 52.0

const COL_BG := Color(0.11, 0.11, 0.13, 0.98)
const COL_RAIL := Color(0.07, 0.07, 0.09, 0.98)
const COL_HOVER := Color(1, 1, 1, 0.10)
const COL_PRESS := Color(1, 1, 1, 0.18)
const COL_ACCENT := Color(0.0, 0.47, 0.84)
const COL_TEXT := Color(1, 1, 1)
const COL_DIM := Color(0.7, 0.72, 0.78)

var taskbar_ref: Control                 # menu wyrasta nad paskiem zadań
var keep_open: Array[Control] = []       # kliknięcie tych kontrolek nie zamyka menu

var _header: Label
var _list: VBoxContainer
var _power_btn: Button
var _power_menu: PanelContainer
var _query: String = ""
var _fade: Tween


func _init() -> void:
	visible = false
	custom_minimum_size = MENU_SIZE
	size = MENU_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


# =========================================================================
# BUDOWA
# =========================================================================

func _build() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.box(COL_BG))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	panel.add_child(h)

	# --- lewy pasek: ustawienia i zasilanie na dole ---
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(RAIL_W, 0)
	rail.add_theme_stylebox_override("panel", UiStyle.box(COL_RAIL))
	h.add_child(rail)

	var rail_box := VBoxContainer.new()
	rail_box.alignment = BoxContainer.ALIGNMENT_END
	rail_box.add_theme_constant_override("separation", 0)
	rail.add_child(rail_box)

	var settings_btn := _rail_button(WinIcon.Kind.GEAR)
	settings_btn.pressed.connect(func():
		_power_menu.visible = false
		settings_pressed.emit())
	rail_box.add_child(settings_btn)

	_power_btn = _rail_button(WinIcon.Kind.POWER)
	_power_btn.pressed.connect(func(): _power_menu.visible = not _power_menu.visible)
	rail_box.add_child(_power_btn)

	# --- zawartość: nagłówek + lista ---
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	h.add_child(margin)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	margin.add_child(cv)

	_header = UiStyle.label("Aplikacje", 18, COL_DIM)
	cv.add_child(_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)

	# --- podmenu zasilania (nad przyciskiem zasilania) ---
	_power_menu = PanelContainer.new()
	_power_menu.visible = false
	_power_menu.custom_minimum_size = Vector2(230, 134)
	_power_menu.size = Vector2(230, 134)
	_power_menu.position = Vector2(RAIL_W, MENU_SIZE.y - 134.0 - 4.0)
	_power_menu.add_theme_stylebox_override("panel", UiStyle.box(Color(0.2, 0.2, 0.23), 0, Color(1, 1, 1, 0.18), 1))
	add_child(_power_menu)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	_power_menu.add_child(pv)
	for item in [["Uśpij", &"sleep"], ["Zamknij", &"shutdown"], ["Uruchom ponownie", &"restart"]]:
		pv.add_child(_power_item(item[0], item[1]))


func _rail_button(kind: WinIcon.Kind) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(RAIL_W, RAIL_W)
	b.focus_mode = Control.FOCUS_NONE
	UiStyle.flat_button(b, Color(0, 0, 0, 0), COL_HOVER, COL_PRESS)
	var icon := WinIcon.new()
	icon.kind = kind
	b.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	return b


func _power_item(text: String, action: StringName) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, COL_TEXT)
	UiStyle.flat_button(b, Color(0, 0, 0, 0), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.2), 14.0)
	b.pressed.connect(func():
		close()
		power_action.emit(action))
	return b


# =========================================================================
# LISTA / WYSZUKIWANIE
# =========================================================================

func set_query(q: String) -> void:
	_query = q.strip_edges()
	_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	if _query.is_empty():
		_header.text = "Aplikacje"
		for id in AppRegistry.listed_ids():
			_list.add_child(_make_row(id, false, false))
		return

	var results := AppRegistry.search(_query)
	if results.is_empty():
		_header.text = "Brak wyników"
		_list.add_child(UiStyle.label("Nie znaleziono: " + _query, 18, COL_DIM))
	else:
		_header.text = "Najlepsze dopasowanie"
		for i in results.size():
			_list.add_child(_make_row(results[i], i == 0, true))


func _make_row(id: StringName, highlighted: bool, subtitle: bool) -> Button:
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	row.focus_mode = Control.FOCUS_NONE
	var normal := Color(COL_ACCENT, 0.55) if highlighted else Color(0, 0, 0, 0)
	var hover := Color(COL_ACCENT, 0.75) if highlighted else COL_HOVER
	UiStyle.flat_button(row, normal, hover, COL_PRESS)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	row.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	margin.add_child(h)
	h.add_child(_make_app_icon(id, 32.0))

	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(UiStyle.label(AppRegistry.display_name(id), 22, COL_TEXT))
	if subtitle:
		texts.add_child(UiStyle.label("Aplikacja", 14, COL_DIM))
	h.add_child(texts)

	row.pressed.connect(func(): app_chosen.emit(id))
	return row


func _make_app_icon(id: StringName, px: float) -> Control:
	var tex := AppRegistry.icon_texture(id)
	if tex:
		var icon_rect := TextureRect.new()
		icon_rect.texture = tex
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(px, px)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return icon_rect
	var wi := WinIcon.new()
	wi.kind = AppRegistry.icon_kind(id)
	wi.custom_minimum_size = Vector2(px, px)
	wi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return wi


# =========================================================================
# OTWIERANIE / ZAMYKANIE
# =========================================================================

func open() -> void:
	if visible:
		return
	if taskbar_ref:
		global_position = Vector2(0, taskbar_ref.global_position.y - size.y)
	_power_menu.visible = false
	visible = true
	modulate.a = 0.0
	if _fade and _fade.is_running():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, 0.1)


func close() -> void:
	if not visible:
		return
	if _fade and _fade.is_running():
		_fade.kill()
	visible = false
	_power_menu.visible = false
	_query = ""
	closed.emit()


# Kliknięcie poza menu (i poza przyciskiem Start / wyszukiwarką) zamyka je
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		if _power_menu.visible and not _power_menu.get_global_rect().has_point(pos) \
				and not _power_btn.get_global_rect().has_point(pos):
			_power_menu.visible = false
		if get_global_rect().has_point(pos):
			return
		for c in keep_open:
			if c.get_global_rect().has_point(pos):
				return
		close()
