extends TextureButton

@export var wifi_connected_icon: Texture2D
@export var wifi_disconnected_icon: Texture2D

# --- Układ ---
const POPUP_WIDTH := 400.0
const SCREEN_MARGIN := 10.0     # odstęp od prawej krawędzi ekranu i od paska zadań
const ROW_HEIGHT := 72.0
const ROW_GAP := 6.0
const MAX_LIST_HEIGHT := 390.0  # powyżej tej wysokości lista się przewija

# --- Kolory ---
const COL_BG := Color(0.09, 0.12, 0.20, 0.97)
const COL_BORDER := Color(1, 1, 1, 0.14)
const COL_ROW := Color(1, 1, 1, 0.06)
const COL_ROW_HOVER := Color(1, 1, 1, 0.14)
const COL_ROW_PRESSED := Color(1, 1, 1, 0.22)
const COL_ACCENT := Color(0.35, 0.62, 1.0)
const COL_TEXT := Color(1, 1, 1)
const COL_TEXT_DIM := Color(0.72, 0.78, 0.88)
const COL_OK := Color(0.45, 0.9, 0.6)
const COL_WARN := Color(1.0, 0.8, 0.4)

var popup: PanelContainer
var list: VBoxContainer
var scroll: ScrollContainer
var status_label: Label

var _last_signature: String = ""
var _last_online: bool = false
var _fade_tween: Tween


func _ready() -> void:
	# Stary popup ze sceny zastępuje ten budowany w kodzie
	var old := get_node_or_null("WifiPopup")
	if old:
		old.queue_free()

	pressed.connect(_on_icon_pressed)
	_update_icon()
	NetworkManager.connection_changed.connect(func(_c: bool): _update_icon())

	_build_popup()
	_attach_popup.call_deferred()   # rodzic jest jeszcze zajęty tworzeniem dzieci


func _process(_delta: float) -> void:
	if NetworkManager.is_connected_to_internet != _last_online:
		_update_icon()
	# Na żywo: odświeżamy tylko, gdy lista jest otwarta i coś się zmieniło
	if popup and popup.visible:
		_refresh()


# Kliknięcie poza listą (i poza przyciskiem wifi) chowa listę
func _input(event: InputEvent) -> void:
	if popup == null or not popup.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var pos: Vector2 = event.position
		if popup.get_global_rect().has_point(pos) or get_global_rect().has_point(pos):
			return
		_hide_popup()


# =========================================================================
# IKONA NA PASKU
# =========================================================================

func _update_icon() -> void:
	_last_online = NetworkManager.is_connected_to_internet
	if _last_online:
		texture_normal = wifi_connected_icon
		tooltip_text = "Połączono z: " + NetworkManager.current_wifi_name
	else:
		texture_normal = wifi_disconnected_icon
		tooltip_text = "Brak dostępu do internetu"


func _on_icon_pressed() -> void:
	if popup.visible:
		_hide_popup()
	else:
		_show_popup()


# =========================================================================
# POPUP
# =========================================================================

func _show_popup() -> void:
	_refresh(true)
	popup.show()
	popup.modulate.a = 0.0
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(popup, "modulate:a", 1.0, 0.12)


func _hide_popup() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	popup.hide()


func _build_popup() -> void:
	popup = PanelContainer.new()
	popup.name = "WifiFlyout"
	popup.visible = false
	popup.custom_minimum_size = Vector2(POPUP_WIDTH, 0)

	var style := _box(COL_BG, 16, COL_BORDER, 2)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 4)
	popup.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	popup.add_child(box)

	box.add_child(_label("Wi-Fi", 28, COL_TEXT))
	status_label = _label("", 16, COL_TEXT_DIM)
	box.add_child(status_label)

	var sep_style := StyleBoxLine.new()
	sep_style.color = COL_BORDER
	sep_style.thickness = 2
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_style)
	box.add_child(sep)

	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", int(ROW_GAP))
	scroll.add_child(list)


# Przepinamy popup do korzenia PCControl, żeby rysował się nad oknami aplikacji
func _attach_popup() -> void:
	var root = owner   # PCControl (bez typu, bo wołamy jego metodę)
	root.add_child(popup)
	root.register_overlay(popup)


# Odbudowuje listę tylko gdy zmienił się stan (albo wymusimy)
func _refresh(force: bool = false) -> void:
	var signature := _make_signature()
	if not force and signature == _last_signature:
		return
	_last_signature = signature

	_rebuild_list()
	status_label.text = ("Połączono z: " + NetworkManager.current_wifi_name) \
		if NetworkManager.current_wifi_name != "" else "Niepołączono"

	popup.reset_size()
	_reposition()


func _make_signature() -> String:
	var parts := PackedStringArray()
	parts.append(NetworkManager.current_wifi_name)
	parts.append(str(NetworkManager.is_connected_to_internet))
	for n in WifiDatabase.networks.keys():
		parts.append("%s:%s" % [n, WifiDatabase.networks[n]["is_available"]])
	return "|".join(parts)


# Prawy dolny róg ekranu, tuż nad paskiem zadań
func _reposition() -> void:
	var root := popup.get_parent() as Control
	if root == null:
		return
	var taskbar := root.get_node_or_null("TaskBar") as Control
	var bottom := taskbar.global_position.y if taskbar else root.size.y
	popup.global_position = Vector2(
		root.size.x - popup.size.x - SCREEN_MARGIN,
		bottom - popup.size.y - SCREEN_MARGIN
	)


func _rebuild_list() -> void:
	# remove_child + queue_free: stare wiersze nie liczą się już do rozmiaru
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	# Połączona sieć na górze, reszta w kolejności z bazy
	var names: Array = []
	for n in WifiDatabase.networks.keys():
		if WifiDatabase.networks[n]["is_available"]:
			if n == NetworkManager.current_wifi_name:
				names.push_front(n)
			else:
				names.append(n)

	if names.is_empty():
		list.add_child(_label("Nie znaleziono sieci", 20, COL_TEXT_DIM))
	for n in names:
		list.add_child(_make_row(n, WifiDatabase.networks[n]))

	var rows_h := names.size() * (ROW_HEIGHT + ROW_GAP)
	scroll.custom_minimum_size.y = clampf(rows_h, 40.0, MAX_LIST_HEIGHT)


func _make_row(wifi_name: String, data: Dictionary) -> Button:
	var connected := NetworkManager.current_wifi_name == wifi_name
	var has_internet := float(data["speed_multiplier"]) > 0.0

	var border := COL_ACCENT if connected else Color(0, 0, 0, 0)
	var bw := 2 if connected else 0
	var normal_bg := Color(COL_ACCENT, 0.22) if connected else COL_ROW

	var row := Button.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.focus_mode = Control.FOCUS_NONE
	row.add_theme_stylebox_override("normal", _box(normal_bg, 10, border, bw))
	row.add_theme_stylebox_override("hover", _box(COL_ROW_HOVER, 10, border, bw))
	row.add_theme_stylebox_override("pressed", _box(COL_ROW_PRESSED, 10, border, bw))
	row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Zawartość wiersza (wszystko ignoruje mysz - klika się cały przycisk)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	row.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	margin.add_child(h)

	var icon := TextureRect.new()
	icon.texture = wifi_connected_icon if has_internet else wifi_disconnected_icon
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(icon)

	var status_text := "Zabezpieczona" if data["password"] != "" else "Otwarta"
	var status_color := COL_TEXT_DIM
	if connected:
		status_text = "Połączono" if has_internet else "Połączono, brak internetu"
		status_color = COL_OK if has_internet else COL_WARN

	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(_label(wifi_name, 22, COL_TEXT))
	texts.add_child(_label(status_text, 15, status_color))
	h.add_child(texts)

	var action := _label("Rozłącz" if connected else "Połącz", 16, COL_ACCENT)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(action)

	if connected:
		row.pressed.connect(_attempt_disconnect)
	else:
		row.pressed.connect(_attempt_connect.bind(wifi_name))
	return row


# =========================================================================
# AKCJE
# =========================================================================

func _attempt_connect(wifi_name: String) -> void:
	NetworkManager.connect_to_net(wifi_name)
	# Lista zostaje otwarta i sama pokaże nowy status.
	# Wolisz, żeby się zamykała? Dopisz tu: _hide_popup()


func _attempt_disconnect() -> void:
	NetworkManager.disconnect_from_net()


# =========================================================================
# POMOCNICZE
# =========================================================================

func _box(bg: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	return s


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
