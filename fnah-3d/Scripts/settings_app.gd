extends PanelContainer
class_name SettingsApp
## Zawartość okna Ustawienia: lewa nawigacja + strony. Okno tworzy pc_control.

enum Mode { IDLE, SET, CHANGE, REMOVE }

const COL_BG := Color(0.97, 0.97, 0.98)
const COL_NAV := Color(0.90, 0.90, 0.93)
const COL_CARD := Color(1, 1, 1)
const COL_BORDER := Color(0.82, 0.82, 0.86)
const COL_TEXT := Color(0.08, 0.08, 0.10)
const COL_DIM := Color(0.38, 0.38, 0.44)
const COL_ACCENT := Color(0.0, 0.47, 0.84)
const COL_OK := Color(0.10, 0.55, 0.25)
const COL_ERR := Color(0.78, 0.12, 0.12)
const SEG_OFF := Color(0.82, 0.82, 0.86)
const STRENGTH_COLORS := [
	Color(0.85, 0.20, 0.20), Color(0.95, 0.50, 0.15), Color(0.90, 0.75, 0.10),
	Color(0.55, 0.78, 0.20), Color(0.10, 0.62, 0.30),
]

const NAV_ITEMS := [
	["system", "System"],
	["personalization", "Personalizacja"],
	["accounts", "Konta"],
	["privacy", "Prywatność i bezpieczeństwo"],
]

# [klucz, tytuł, opis, wartość domyślna]
const SECTIONS := [
	["Uprawnienia systemu Windows", [
		["ad_id", "Zezwalaj aplikacjom na używanie identyfikatora reklamowego",
			"Aplikacje będą wyświetlać reklamy dopasowane do Twoich zainteresowań.", true],
		["lang_list", "Pozwól witrynom internetowym na dostęp do listy języków",
			"Witryny mogą wyświetlać zawartość w Twoim języku.", true],
		["track_launch", "Pozwól systemowi Windows śledzić uruchamiane aplikacje",
			"Ulepsza menu Start i wyniki wyszukiwania.", true],
		["suggested", "Pokazuj sugerowaną zawartość w aplikacji Ustawienia", "", false],
	]],
	["Diagnostyka i opinie", [
		["diag_optional", "Wysyłaj opcjonalne dane diagnostyczne",
			"Obejmuje dane o odwiedzanych witrynach i sposobie korzystania z aplikacji.", false],
		["activity", "Przechowuj historię aktywności na tym urządzeniu",
			"Pozwala szybko wrócić do ostatnio używanych plików i aplikacji.", true],
	]],
	["Uprawnienia aplikacji", [
		["location", "Dostęp do lokalizacji", "Pozwól aplikacjom na dostęp do Twojej lokalizacji.", false],
		["camera", "Dostęp do kamery", "Pozwól aplikacjom na korzystanie z kamery.", true],
		["mic", "Dostęp do mikrofonu", "Pozwól aplikacjom na korzystanie z mikrofonu.", true],
	]],
	["Zabezpieczenia systemu Windows", [
		["realtime", "Ochrona w czasie rzeczywistym",
			"Wykrywaj złośliwe oprogramowanie i zapobiegaj jego instalacji.", true],
		["firewall", "Zapora sieciowa",
			"Chroń urządzenie przed nieautoryzowanym dostępem z sieci.", true],
		["smartscreen", "Ochrona oparta na reputacji",
			"Sprawdzaj pobierane pliki i odwiedzane witryny.", true],
	]],
]

var pc                               # PCControl (bez typu - wołamy jego metody dynamicznie)
var username: String = "User"
var values: Dictionary = {}          # stan przełączników: klucz -> bool

var _nav_buttons := {}
var _pages := {}
var _scroll: ScrollContainer
var _mode: Mode = Mode.IDLE

var _pw_status: Label
var _pw_strength_now: Label
var _pw_notice: Label
var _btn_set: Button
var _btn_change: Button
var _btn_remove: Button
var _pw_form: VBoxContainer
var _pw_cur_row: Control
var _pw_new_row: Control
var _pw_rep_row: Control
var _pw_cur: LineEdit
var _pw_new: LineEdit
var _pw_rep: LineEdit
var _strength_box: VBoxContainer
var _segs: Array = []
var _strength_label: Label
var _tips_label: Label
var _pw_error: Label
var _pw_save: Button
var _pw_cancel: Button


func _ready() -> void:
	_build()
	_select("privacy")
	reset()


# Wywoływane przy zamykaniu/restarcie komputera
func reset() -> void:
	_pw_notice.visible = false
	_set_mode(Mode.IDLE)


# =========================================================================
# BUDOWA: nawigacja i strony
# =========================================================================

func _build() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(COL_BG))

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var nav := PanelContainer.new()
	nav.custom_minimum_size = Vector2(230, 0)
	nav.add_theme_stylebox_override("panel", UiStyle.box(COL_NAV))
	root.add_child(nav)

	var nav_box := VBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 2)
	nav.add_child(nav_box)
	nav_box.add_child(_pad(UiStyle.label("Ustawienia", 24, COL_TEXT), 16, 16, 16, 12))
	for item in NAV_ITEMS:
		var b := _nav_button(item[0], item[1])
		_nav_buttons[item[0]] = b
		nav_box.add_child(b)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_scroll.add_child(margin)

	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(holder)

	for item in NAV_ITEMS:
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 6)
		page.visible = false
		page.add_child(UiStyle.label(item[1], 28, COL_TEXT))
		page.add_child(_gap(8))
		holder.add_child(page)
		_pages[item[0]] = page
		if item[0] == "privacy":
			_fill_privacy(page)
		else:
			page.add_child(_wrap(UiStyle.label("W tej sekcji nie ma jeszcze żadnych ustawień.", 18, COL_DIM)))


func _nav_button(id: String, text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 10)
	b.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := _wrap(UiStyle.label(text, 18, COL_TEXT))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m.add_child(l)
	b.pressed.connect(_select.bind(id))
	_style_nav(b, false)
	return b


func _style_nav(b: Button, selected: bool) -> void:
	var normal := Color(COL_ACCENT, 0.16) if selected else Color(0, 0, 0, 0)
	var hover := Color(COL_ACCENT, 0.24) if selected else Color(0, 0, 0, 0.07)
	UiStyle.flat_button(b, normal, hover, Color(0, 0, 0, 0.12))


func _select(id: String) -> void:
	for pid in _pages:
		_pages[pid].visible = (pid == id)
	for bid in _nav_buttons:
		_style_nav(_nav_buttons[bid], bid == id)
	_scroll.scroll_vertical = 0
	if id == "privacy":
		_refresh_status()


# =========================================================================
# STRONA "Prywatność i bezpieczeństwo"
# =========================================================================

func _fill_privacy(page: VBoxContainer) -> void:
	page.add_child(_section("Logowanie"))
	page.add_child(_build_password_card())
	for sec in SECTIONS:
		page.add_child(_section(sec[0]))
		for row in sec[1]:
			page.add_child(_toggle_row(row[0], row[1], row[2], row[3]))


func _toggle_row(key: String, title: String, desc: String, default_on: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(12))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(_wrap(UiStyle.label(title, 18, COL_TEXT)))
	if desc != "":
		v.add_child(_wrap(UiStyle.label(desc, 14, COL_DIM)))

	var state := UiStyle.label("Wł." if default_on else "Wył.", 16, COL_TEXT)
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(state)

	var t := WinToggle.new()
	t.on = default_on
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.toggled.connect(func(on: bool):
		values[key] = on
		state.text = "Wł." if on else "Wył.")
	h.add_child(t)

	values[key] = default_on
	return card


# =========================================================================
# HASŁO
# =========================================================================

func _build_password_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(16))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)

	v.add_child(UiStyle.label("Hasło logowania", 18, COL_TEXT))
	_pw_status = _wrap(UiStyle.label("", 15, COL_DIM))
	v.add_child(_pw_status)
	_pw_strength_now = UiStyle.label("", 15, COL_TEXT)
	v.add_child(_pw_strength_now)
	_pw_notice = _wrap(UiStyle.label("", 15, COL_OK))
	_pw_notice.visible = false
	v.add_child(_pw_notice)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	v.add_child(btns)
	_btn_set = _button("Ustaw hasło", true)
	_btn_set.pressed.connect(_start.bind(Mode.SET))
	_btn_change = _button("Zmień hasło", true)
	_btn_change.pressed.connect(_start.bind(Mode.CHANGE))
	_btn_remove = _button("Usuń hasło", false)
	_btn_remove.pressed.connect(_start.bind(Mode.REMOVE))
	for b in [_btn_set, _btn_change, _btn_remove]:
		btns.add_child(b)

	# --- formularz ---
	_pw_form = VBoxContainer.new()
	_pw_form.add_theme_constant_override("separation", 8)
	_pw_form.visible = false
	v.add_child(_pw_form)

	_pw_cur = _make_edit()
	_pw_cur_row = _labeled("Aktualne hasło", _pw_cur)
	_pw_form.add_child(_pw_cur_row)

	_pw_new = _make_edit()
	_pw_new_row = _labeled("Nowe hasło", _pw_new)
	_pw_form.add_child(_pw_new_row)

	_pw_rep = _make_edit()
	_pw_rep_row = _labeled("Powtórz nowe hasło", _pw_rep)
	_pw_form.add_child(_pw_rep_row)

	_strength_box = VBoxContainer.new()
	_strength_box.add_theme_constant_override("separation", 4)
	_pw_form.add_child(_strength_box)
	var seg_row := HBoxContainer.new()
	seg_row.add_theme_constant_override("separation", 4)
	_strength_box.add_child(seg_row)
	for i in 5:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(68, 6)
		seg.color = SEG_OFF
		seg_row.add_child(seg)
		_segs.append(seg)
	_strength_label = UiStyle.label("", 16, COL_TEXT)
	_strength_box.add_child(_strength_label)
	_tips_label = _wrap(UiStyle.label("", 14, COL_DIM))
	_strength_box.add_child(_tips_label)

	_pw_error = _wrap(UiStyle.label("", 15, COL_ERR))
	_pw_error.visible = false
	_pw_form.add_child(_pw_error)

	var form_btns := HBoxContainer.new()
	form_btns.add_theme_constant_override("separation", 8)
	_pw_form.add_child(form_btns)
	_pw_save = _button("Zapisz", true)
	_pw_save.pressed.connect(_on_save)
	_pw_cancel = _button("Anuluj", false)
	_pw_cancel.pressed.connect(_on_cancel)
	form_btns.add_child(_pw_save)
	form_btns.add_child(_pw_cancel)

	_pw_cur.text_submitted.connect(_on_cur_submitted)
	_pw_new.text_submitted.connect(func(_t: String): _pw_rep.grab_focus())
	_pw_rep.text_submitted.connect(func(_t: String): _on_save())
	_pw_new.text_changed.connect(_update_strength)

	return card


func _start(mode: Mode) -> void:
	_pw_notice.visible = false
	_set_mode(mode)


func _set_mode(m: Mode) -> void:
	_mode = m
	var editing := m != Mode.IDLE
	var needs_current := m == Mode.CHANGE or m == Mode.REMOVE
	var needs_new := m == Mode.SET or m == Mode.CHANGE

	_pw_form.visible = editing
	_pw_cur_row.visible = needs_current
	_pw_new_row.visible = needs_new
	_pw_rep_row.visible = needs_new
	_strength_box.visible = needs_new
	_pw_save.text = "Usuń hasło" if m == Mode.REMOVE else "Zapisz"
	_pw_error.visible = false
	for e in [_pw_cur, _pw_new, _pw_rep]:
		e.clear()
	_update_strength("")
	_refresh_status()

	if editing:
		var first: LineEdit = _pw_new if m == Mode.SET else _pw_cur
		first.grab_focus.call_deferred()


func _refresh_status() -> void:
	if pc == null:
		return
	var has: bool = pc.user_password != ""
	var idle := _mode == Mode.IDLE
	_btn_set.visible = idle and not has
	_btn_change.visible = idle and has
	_btn_remove.visible = idle and has

	if has:
		_pw_status.text = "Konto „%s” jest chronione hasłem. Hasło jest wymagane przy logowaniu do komputera." % username
		var s: Dictionary = pc.password_strength
		var lvl: int = s["level"]
		_pw_strength_now.text = "Siła hasła: " + str(s["label"])
		_pw_strength_now.add_theme_color_override("font_color", STRENGTH_COLORS[clampi(lvl, 0, 4)])
		_pw_strength_now.visible = true
	else:
		_pw_status.text = "Konto „%s” nie jest chronione hasłem – każdy może zalogować się do komputera." % username
		_pw_strength_now.visible = false


# Pasek siły na żywo podczas pisania nowego hasła
func _update_strength(text: String) -> void:
	if text.is_empty():
		for s in _segs:
			s.color = SEG_OFF
		_strength_label.text = ""
		_tips_label.text = ""
		return
	var r: Dictionary = PasswordStrength.evaluate(text, username)
	var lvl: int = r["level"]
	for i in _segs.size():
		_segs[i].color = STRENGTH_COLORS[lvl] if i <= lvl else SEG_OFF
	_strength_label.text = "Siła hasła: " + str(r["label"])
	_strength_label.add_theme_color_override("font_color", STRENGTH_COLORS[lvl])
	var tips: Array = r["tips"]
	_tips_label.text = "\n".join(PackedStringArray(tips.slice(0, 3)))


func _on_cur_submitted(_t: String) -> void:
	if _mode == Mode.CHANGE:
		_pw_new.grab_focus()
	else:
		_on_save()


func _on_cancel() -> void:
	_pw_notice.visible = false
	_set_mode(Mode.IDLE)


func _on_save() -> void:
	if _mode == Mode.IDLE:
		return
	var cur := _pw_cur.text
	var new_pw := _pw_new.text
	var rep := _pw_rep.text

	if _mode == Mode.CHANGE or _mode == Mode.REMOVE:
		if cur != pc.user_password:
			_show_error("Aktualne hasło jest nieprawidłowe.")
			return

	if _mode == Mode.REMOVE:
		pc.set_user_password("")
		_finish("Hasło zostało usunięte. Logowanie nie będzie już wymagało hasła.")
		return

	if new_pw.is_empty():
		_show_error("Wpisz nowe hasło.")
		return
	if new_pw != rep:
		_show_error("Hasła nie są takie same. Wpisz je ponownie.")
		return
	if _mode == Mode.CHANGE and new_pw == pc.user_password:
		_show_error("Nowe hasło musi różnić się od obecnego.")
		return

	pc.set_user_password(new_pw)   # zapisuje hasło i jego ocenę (pc.password_strength)
	_finish("Hasło zostało ustawione. Od teraz będzie wymagane przy logowaniu do komputera.")


func _show_error(msg: String) -> void:
	_pw_error.text = msg
	_pw_error.visible = true


func _finish(msg: String) -> void:
	_set_mode(Mode.IDLE)
	_pw_notice.text = msg
	_pw_notice.visible = true


# =========================================================================
# POMOCNICZE (UI)
# =========================================================================

func _section(text: String) -> Control:
	return _pad(UiStyle.label(text, 20, COL_TEXT), 0, 14, 0, 2)


func _pad(child: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


func _gap(h: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g


func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(120, 0)
	return l


func _card_style(vertical_margin: int) -> StyleBoxFlat:
	var s := UiStyle.box(COL_CARD, 4, COL_BORDER, 1)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = vertical_margin
	s.content_margin_bottom = vertical_margin
	return s


func _labeled(title: String, edit: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(UiStyle.label(title, 15, COL_DIM))
	v.add_child(edit)
	return v


func _make_edit() -> LineEdit:
	var e := LineEdit.new()
	e.secret = true
	e.custom_minimum_size = Vector2(360, 40)
	e.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	e.add_theme_font_size_override("font_size", 18)
	e.add_theme_color_override("font_color", COL_TEXT)
	e.add_theme_color_override("caret_color", COL_TEXT)
	var n := UiStyle.box(Color.WHITE, 2, COL_BORDER, 1)
	n.content_margin_left = 10
	n.content_margin_right = 10
	var f := UiStyle.box(Color.WHITE, 2, COL_ACCENT, 2)
	f.content_margin_left = 10
	f.content_margin_right = 10
	e.add_theme_stylebox_override("normal", n)
	e.add_theme_stylebox_override("focus", f)
	return e


func _button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 17)
	var fc := Color.WHITE if primary else COL_TEXT
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, fc)
	var bg_normal := COL_ACCENT if primary else Color(0.88, 0.88, 0.90)
	var bg_hover := Color(0.0, 0.40, 0.74) if primary else Color(0.82, 0.82, 0.86)
	var bg_press := Color(0.0, 0.33, 0.62) if primary else Color(0.76, 0.76, 0.80)
	var border := Color(0, 0, 0, 0) if primary else COL_BORDER
	b.add_theme_stylebox_override("normal", _btn_box(bg_normal, border))
	b.add_theme_stylebox_override("hover", _btn_box(bg_hover, border))
	b.add_theme_stylebox_override("pressed", _btn_box(bg_press, border))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(bg_press, border))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _btn_box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := UiStyle.box(bg, 2, border, 1)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s
