extends Node
class_name BrowserSkin
## Wygląd okna przeglądarki. Dokłada dekoracje i przestylowuje istniejące węzły
## (nazwy i ścieżki zostają - browser.gd działa bez zmian).

const COL_FRAME := Color(0.667, 0.827, 0.91, 1.0)
const COL_TEXT := Color(0.10, 0.11, 0.14)
const COL_DIM := Color(0.40, 0.43, 0.50)
const COL_ACCENT := Color(0.0, 0.47, 0.84)
const COL_BAR_BG := Color(0.93, 0.94, 0.96)
const COL_LINE := Color(0.88, 0.89, 0.92)

# Nazwa głównego węzła wczytanej strony -> tytuł karty.
# Nowa strona w grze? Dopisz tu nazwę jej węzła głównego.
const TAB_TITLES := {
	"AllegroPage": "Allegro",
	"GooglePl": "Gugul",
	"Error404": "Błąd 404",
	"HufiecStrona": "Hufiec ZHP Wągrowiec",
	"NoInternet": "Brak połączenia",
	"Sharepoint": "SharePoint",
	"SkibidiPl": "Skibidi",
	"Email": "Poczta",
}

var _window: PanelContainer
var _browser                       # MarginContainer z browser.gd (bez typu - czytamy jego zmienne)
var _tab: Label
var _empty: Control


func _ready() -> void:
	_window = get_parent() as PanelContainer
	_browser = _window.get_node("MarginContainer")
	_style_window()
	_style_titlebar()
	_style_toolbar()
	_style_progress()
	_build_empty_state()
	_style_dialog()


# =========================================================================
# STYLE
# =========================================================================

func _style_window() -> void:
	_window.custom_minimum_size = Vector2(720, 0)
	var ws := UiStyle.box(COL_FRAME, 0, Color(0.5, 0.53, 0.6, 0.9), 1)
	ws.shadow_size = 12
	ws.shadow_color = Color(0, 0, 0, 0.35)
	ws.shadow_offset = Vector2(0, 3)
	_window.add_theme_stylebox_override("panel", ws)

	var frame := _window.get_node_or_null("ColorRect") as ColorRect
	if frame:
		frame.color = COL_FRAME


# Pasek tytułu: karta w stylu Chrome zamiast zwykłego napisu
func _style_titlebar() -> void:
	var bar := _window.get_node_or_null("PasekKontrolny") as HBoxContainer
	if bar == null:
		return
	bar.add_theme_constant_override("separation", 0)

	_tab = bar.get_node_or_null("Label") as Label
	if _tab:
		_tab.text = "Nowa karta"
		_tab.custom_minimum_size = Vector2(210, 28)
		_tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_tab.size_flags_vertical = Control.SIZE_SHRINK_END     # 4 px odstępu od góry okna
		_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_tab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_tab.clip_text = true
		_tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_tab.add_theme_font_size_override("font_size", 15)
		_tab.add_theme_color_override("font_color", COL_TEXT)
		var tab_style := UiStyle.box(Color.WHITE)
		tab_style.corner_radius_top_left = 8
		tab_style.corner_radius_top_right = 8
		tab_style.content_margin_left = 14
		tab_style.content_margin_right = 10
		_tab.add_theme_stylebox_override("normal", tab_style)

		# odstęp przed kartą i rozpychacz za nią (przycisk X zostaje po prawej)
		var left := Control.new()
		left.custom_minimum_size = Vector2(8, 0)
		bar.add_child(left)
		bar.move_child(left, 0)
		var right := Control.new()
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(right)
		bar.move_child(right, _tab.get_index() + 1)

	var close_btn := bar.get_node_or_null("CloseBrowserButton") as TextureButton
	if close_btn:
		close_btn.mouse_entered.connect(func(): close_btn.modulate = Color(1.0, 0.45, 0.45))
		close_btn.mouse_exited.connect(func(): close_btn.modulate = Color.WHITE)


# Pasek adresu: pigułka + przycisk z lupą + linia pod spodem
func _style_toolbar() -> void:
	var app := _browser.get_node_or_null("App") as VBoxContainer
	if app == null:
		return
	app.add_theme_constant_override("separation", 0)

	var bar := app.get_node_or_null("PasekAdresu") as HBoxContainer
	if bar == null:
		return
	bar.add_theme_constant_override("separation", 8)
	bar.custom_minimum_size = Vector2(0, 48)
	bar.alignment = BoxContainer.ALIGNMENT_BEGIN

	var left := Control.new()
	left.custom_minimum_size = Vector2(6, 0)
	bar.add_child(left)
	bar.move_child(left, 0)

	var url := bar.get_node_or_null("UrlInput") as LineEdit
	if url:
		url.custom_minimum_size = Vector2(300, 36)
		url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		url.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		url.placeholder_text = "Wyszukaj lub wpisz adres URL"
		url.add_theme_font_size_override("font_size", 17)
		url.add_theme_color_override("font_color", COL_TEXT)
		url.add_theme_color_override("font_placeholder_color", Color(0.5, 0.52, 0.58))
		url.add_theme_color_override("caret_color", COL_TEXT)
		url.add_theme_color_override("selection_color", Color(COL_ACCENT, 0.3))
		var n := UiStyle.box(COL_BAR_BG, 18)
		n.content_margin_left = 16
		n.content_margin_right = 16
		var f := UiStyle.box(Color.WHITE, 18, COL_ACCENT, 2)
		f.content_margin_left = 16
		f.content_margin_right = 16
		url.add_theme_stylebox_override("normal", n)
		url.add_theme_stylebox_override("focus", f)

	var search := bar.get_node_or_null("Search") as Button
	if search:
		search.text = ""
		search.tooltip_text = "Szukaj"
		search.custom_minimum_size = Vector2(40, 36)
		search.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		search.focus_mode = Control.FOCUS_NONE
		search.add_theme_stylebox_override("normal", UiStyle.box(Color(0, 0, 0, 0), 18))
		search.add_theme_stylebox_override("hover", UiStyle.box(Color(0, 0, 0, 0.07), 18))
		search.add_theme_stylebox_override("pressed", UiStyle.box(Color(0, 0, 0, 0.14), 18))
		search.add_theme_stylebox_override("hover_pressed", UiStyle.box(Color(0, 0, 0, 0.14), 18))
		search.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var mag := WinIcon.new()
		mag.kind = WinIcon.Kind.SEARCH
		mag.color = COL_ACCENT
		search.add_child(mag)
		mag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)

	var right := Control.new()
	right.custom_minimum_size = Vector2(6, 0)
	bar.add_child(right)

	var line := ColorRect.new()
	line.color = COL_LINE
	line.custom_minimum_size = Vector2(0, 1)
	app.add_child(line)
	app.move_child(line, bar.get_index() + 1)


# Postęp ładowania: delikatne niebieskie wypełnienie pola adresu (zamiast czarnego)
func _style_progress() -> void:
	var pb := _browser.get_node_or_null("App/PasekAdresu/UrlInput/PageProgressBar") as ProgressBar
	if pb == null:
		return
	pb.modulate = Color.WHITE
	pb.show_behind_parent = false
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pb.show_percentage = false
	pb.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	pb.add_theme_stylebox_override("fill", UiStyle.box(Color(COL_ACCENT, 0.22), 18))


# Ekran "Nowa karta" - widoczny, dopóki nie ma żadnej strony
func _build_empty_state() -> void:
	var zone := _browser.get_node_or_null("App/ContentZone") as Control
	if zone == null:
		return
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(cc)
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty = cc

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	cc.add_child(v)

	var word := HBoxContainer.new()
	word.alignment = BoxContainer.ALIGNMENT_CENTER
	word.add_theme_constant_override("separation", 0)
	v.add_child(word)
	var letters := [["C", "#4285f4"], ["h", "#ea4335"], ["r", "#fbbc05"],
		["o", "#34a853"], ["m", "#4285f4"], ["e", "#ea4335"]]
	for l in letters:
		word.add_child(UiStyle.label(l[0], 60, Color.html(l[1])))

	var sub := UiStyle.label("Wyszukaj lub wpisz adres URL", 18, COL_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)


# Okienko pobierania + przyciemnienie okna w trakcie
func _style_dialog() -> void:
	var dlg := _window.get_node_or_null("DownloadWindow") as PanelContainer
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
		# blokada pod okienkiem pobierania, żeby przyciemnienie go nie zasłaniało
		_window.move_child(blocker, dlg.get_index())


# =========================================================================
# STAN NA ŻYWO
# =========================================================================

func _process(_delta: float) -> void:
	if not _window.visible:
		return

	var title := "Nowa karta"
	var node = _browser.current_page_node
	var has_page: bool = is_instance_valid(node) and not node.is_queued_for_deletion()
	if _browser.is_loading_page:
		title = "Ładowanie..."
	elif has_page:
		title = TAB_TITLES.get(str(node.name), "Nowa karta")

	if _tab and _tab.text != title:
		_tab.text = title
	if _empty:
		_empty.visible = not has_page and not _browser.is_loading_page
