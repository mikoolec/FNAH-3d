extends Control
class_name PowerLayer
## Nakładka na cały ekran: czarny ekran, boot, zamykanie/witaj, logowanie, wybudzanie.
## Gdy jest widoczna, blokuje myszkę - pod spodem nic się nie da kliknąć.

signal login_pressed(password: String)

const LOGO_COLOR := Color(0.06, 0.61, 0.93)
const BLUE_BG := Color(0.0, 0.33, 0.56)

var _black: Control
var _boot: Control
var _wake: Control
var _status: Control
var _status_label: Label
var _login: Control
var _wallpaper: TextureRect
var _name_label: Label
var _pw_edit: LineEdit
var _error_label: Label
var _clock_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black = _make_screen(Color.BLACK)
	_boot = _build_boot()
	_wake = _build_wake()
	_status = _build_status()
	_login = _build_login()
	_show_only(_black)


# =========================================================================
# API
# =========================================================================

func show_black() -> void:
	_show_only(_black)

func show_boot() -> void:
	_show_only(_boot)

func show_wake() -> void:
	_show_only(_wake)

func show_status(text: String) -> void:
	_status_label.text = text
	_show_only(_status)

func hide_all() -> void:
	_show_only(null)

func set_clock(text: String) -> void:
	if _clock_label:
		_clock_label.text = text

func set_wallpaper(tex: Texture2D) -> void:
	_wallpaper.texture = tex

func set_user_name(n: String) -> void:
	_name_label.text = n

func show_login(has_password: bool) -> void:
	_pw_edit.clear()
	_pw_edit.visible = has_password
	_error_label.visible = false
	_show_only(_login)
	if has_password:
		_pw_edit.grab_focus.call_deferred()

func show_login_error(msg: String) -> void:
	_error_label.text = msg
	_error_label.visible = true
	_pw_edit.clear()
	_pw_edit.grab_focus.call_deferred()


func _show_only(screen: Control) -> void:
	for s in [_black, _boot, _wake, _status, _login]:
		s.visible = (s == screen)
	visible = (screen != null)


# =========================================================================
# BUDOWA EKRANÓW
# =========================================================================

func _make_screen(bg: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = bg
	add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r


func _center(parent: Control) -> VBoxContainer:
	var cc := CenterContainer.new()
	parent.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	cc.add_child(v)
	return v


func _spinner(px: float) -> WinIcon:
	var sp := WinIcon.new()
	sp.kind = WinIcon.Kind.SPINNER
	sp.custom_minimum_size = Vector2(px, px)
	return sp


func _gap(h: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g


func _build_boot() -> Control:
	var s := _make_screen(Color.BLACK)
	var v := _center(s)
	var logo := WinIcon.new()
	logo.kind = WinIcon.Kind.LOGO
	logo.color = LOGO_COLOR
	logo.custom_minimum_size = Vector2(120, 120)
	v.add_child(logo)
	v.add_child(_gap(70))
	v.add_child(_spinner(56))
	return s


func _build_wake() -> Control:
	var s := _make_screen(Color.BLACK)
	var v := _center(s)
	v.add_child(_spinner(44))
	return s


func _build_status() -> Control:
	var s := _make_screen(BLUE_BG)
	var v := _center(s)
	_status_label = UiStyle.label("", 38, Color.WHITE)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status_label)
	v.add_child(_gap(30))
	v.add_child(_spinner(56))
	return s


func _build_login() -> Control:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_wallpaper = TextureRect.new()
	_wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wallpaper.stretch_mode = TextureRect.STRETCH_SCALE
	_wallpaper.modulate = Color(0.5, 0.58, 0.78)
	root.add_child(_wallpaper)
	_wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0.04, 0.14, 0.35)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := _center(root)
	v.add_theme_constant_override("separation", 12)

	var avatar := WinIcon.new()
	avatar.kind = WinIcon.Kind.USER
	avatar.custom_minimum_size = Vector2(150, 150)
	v.add_child(avatar)

	_name_label = UiStyle.label("User", 40, Color.WHITE)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_name_label)
	v.add_child(_gap(8))

	_pw_edit = LineEdit.new()
	_pw_edit.secret = true
	_pw_edit.placeholder_text = "Hasło"
	_pw_edit.custom_minimum_size = Vector2(320, 46)
	_pw_edit.add_theme_font_size_override("font_size", 22)
	_pw_edit.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	_pw_edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.45))
	_pw_edit.add_theme_color_override("caret_color", Color(0.1, 0.1, 0.1))
	var st := UiStyle.box(Color(1, 1, 1, 0.92))
	st.content_margin_left = 12
	st.content_margin_right = 12
	_pw_edit.add_theme_stylebox_override("normal", st)
	_pw_edit.add_theme_stylebox_override("focus", st)
	_pw_edit.text_submitted.connect(func(t: String): login_pressed.emit(t))
	v.add_child(_pw_edit)

	_error_label = UiStyle.label("", 18, Color(1, 0.8, 0.8))
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.visible = false
	v.add_child(_error_label)

	var btn := Button.new()
	btn.text = "Zaloguj"
	btn.custom_minimum_size = Vector2(320, 46)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 22)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(c, Color.WHITE)
	UiStyle.flat_button(btn, Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.4))
	btn.pressed.connect(func(): login_pressed.emit(_pw_edit.text))
	v.add_child(btn)

	_clock_label = UiStyle.label("00:00", 72, Color.WHITE)
	root.add_child(_clock_label)
	_clock_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 40)

	return root
